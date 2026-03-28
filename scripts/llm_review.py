import os
import sys
import json
import requests
import time
import re
import google.generativeai as genai
from github import Github, Auth

# Setup Gemini
genai.configure(api_key=os.environ["GEMINI_API_KEY"])

# Setup GitHub
token = os.environ["GITHUB_TOKEN"]
auth = Auth.Token(token)
g = Github(auth=auth)
repo_name = os.environ["GITHUB_REPOSITORY"]
pr_number = int(os.environ["PR_NUMBER"])
repo = g.get_repo(repo_name)
pr = repo.get_pull(pr_number)

def get_valid_lines(patch):
    """
    Parses a git patch string and returns a set of line numbers 
    that are valid for commenting in a GitHub review (the 'new' lines).
    """
    if not patch:
        return set()
    
    valid_lines = set()
    current_line = 0
    
    # Matches hunk header: @@ -old_start,old_count +new_start,new_count @@
    hunk_header_re = re.compile(r'^@@ \-\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@')
    
    for line in patch.split('\n'):
        hunk_match = hunk_header_re.match(line)
        if hunk_match:
            # When we see a hunk header, current_line becomes the first line of the NEW file in this hunk
            current_line = int(hunk_match.group(1))
        elif line.startswith('-'):
            # This line exists in the old file but NOT the new file.
            # We don't increment current_line because it's not in the new version.
            continue
        elif line.startswith('+') or line.startswith(' ') or line == "":
            # This line exists in the new file (either added or unchanged context).
            # We increment current_line.
            valid_lines.add(current_line)
            current_line += 1
        # Metadata lines like '\ No newline at end of file' are ignored
            
    return valid_lines

def get_pr_files():
    files = pr.get_files()
    file_data = []
    for file in files:
        if file.status == "removed":
            continue
        if not file.filename.endswith(".swift"):
            continue
            
        try:
            content = repo.get_contents(file.filename, ref=pr.head.sha).decoded_content.decode("utf-8")
            valid_lines = get_valid_lines(file.patch)
            file_data.append({
                "path": file.filename,
                "content": content,
                "patch": file.patch,
                "valid_lines": list(valid_lines)
            })
        except Exception as e:
            print(f"Warning: Could not fetch content for {file.filename}: {e}")
            
    return file_data

def read_checklist():
    with open("codereview_ios.md", "r") as f:
        return f.read()

def review_code(file_data, checklist):
    files_context = ""
    for f in file_data:
        sorted_lines = sorted(f['valid_lines'])
        files_context += f"\n--- FILE: {f['path']} ---\nVALID LINE NUMBERS (IN DIFF): {sorted_lines}\nFULL CONTENT:\n{f['content']}\n"

    prompt = f"""
You are an expert iOS and SwiftUI developer performing a code review.
You MUST use the provided checklist.

Checklist:
{checklist}

Files Context:
{files_context}

INSTRUCTIONS:
1. ONLY comment on line numbers that are explicitly listed in the 'VALID LINE NUMBERS' for each file.
2. If a violation spans multiple lines, use the FIRST line of the violation that is in the valid list.
3. Format response STRICTLY as JSON:
{{
  "summary": "Overall summary",
  "verdict": "APPROVE" or "REQUEST CHANGES",
  "comments": [
    {{
      "path": "file/path.swift",
      "line": 123,
      "body": "Explanation"
    }}
  ]
}}
    """
    
    # We use list_models to find names that actually exist in the environment
    available_models = [m.name for m in genai.list_models() if 'generateContent' in m.supported_generation_methods]
    print(f"Available models: {available_models}")
    
    # Preferred order
    pref = ['models/gemini-1.5-flash', 'models/gemini-1.5-pro', 'models/gemini-2.0-flash-exp']
    models_to_try = [m for m in pref if m in available_models]
    if not models_to_try:
        # Fallback to whatever matches the pattern
        models_to_try = [m for m in available_models if 'gemini' in m]
    
    for model_name in models_to_try:
        for attempt in range(2):
            try:
                print(f"Attempting review with {model_name}...")
                model = genai.GenerativeModel(
                    model_name=model_name,
                    generation_config={"response_mime_type": "application/json"}
                )
                response = model.generate_content(prompt)
                return json.loads(response.text)
            except Exception as e:
                print(f"Error with {model_name}: {e}")
                time.sleep(5)
    
    raise Exception("Review failed on all models.")

def create_github_review(summary, event, comments):
    """Uses the direct REST API to create a review with better error reporting."""
    url = f"https://api.github.com/repos/{repo_name}/pulls/{pr_number}/reviews"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    payload = {
        "body": f"## 🤖 Gemini Code Review\n\n{summary}",
        "event": event,
        "commit_id": pr.head.sha
    }
    
    if comments:
        payload["comments"] = [
            {
                "path": c["path"],
                "line": int(c["line"]),
                "side": "RIGHT",
                "body": c["body"]
            } for c in comments
        ]
    
    print(f"Sending review payload to {url} with {len(comments) if comments else 0} comments...")
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code not in [200, 201]:
        print(f"API Error: {response.status_code} - {response.text}")
        error_msg = response.text
        try:
            error_json = response.json()
            error_msg = json.dumps(error_json, indent=2)
        except:
            pass
            
        pr.create_issue_comment(f"## 🤖 Gemini Code Review (Fallback)\n\n{summary}\n\n*Note: Inline review failed ({response.status_code}):*\n```json\n{error_msg}\n```")
        return False
        
    print("Review posted successfully.")
    return True

def main():
    try:
        print(f"Starting Gemini Robust Review for PR #{pr_number}...")
        file_data = get_pr_files()
        if not file_data:
            print("No relevant Swift files to review.")
            sys.exit(0)
            
        checklist = read_checklist()
        review_result = review_code(file_data, checklist)
        
        summary = review_result.get("summary", "Gemini Code Review Summary")
        verdict = review_result.get("verdict", "APPROVE")
        comments = review_result.get("comments", [])
        
        github_comments = []
        for c in comments:
            path = c["path"]
            line = int(c["line"])
            f_data = next((f for f in file_data if f["path"] == path), None)
            
            if f_data and line in f_data["valid_lines"]:
                github_comments.append(c)
            else:
                print(f"Skipping comment on {path}:{line} - not in diff range.")
                summary += f"\n\n**AI Note on {path}:{line}**: {c['body']}"
            
        event = "REQUEST_CHANGES" if verdict == "REQUEST CHANGES" else ("APPROVE" if verdict == "APPROVE" else "COMMENT")
        
        create_github_review(summary, event, github_comments)
        # Success status 0 even if issues found, to keep CI flow green
        sys.exit(0)
            
    except Exception as e:
        print(f"FATAL ERROR: {e}")
        pr.create_issue_comment(f"## 🤖 Gemini Code Review\n\nAutomated review failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
