import os
import sys
import json
import requests
import time
import re
from google import genai
from github import Github, Auth

# Setup Gemini
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

# Setup GitHub
auth = Auth.Token(os.environ["GITHUB_TOKEN"])
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
    
    # regex to find hunk headers like @@ -1,4 +1,6 @@
    hunk_header_re = re.compile(r'^@@ \-\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@')
    
    for line in patch.split('\n'):
        hunk_match = hunk_header_re.match(line)
        if hunk_match:
            current_line = int(hunk_match.group(1))
        elif line.startswith('+'):
            valid_lines.add(current_line)
            current_line += 1
        elif line.startswith(' '):
            valid_lines.add(current_line)
            current_line += 1
        elif line.startswith('-'):
            # Line was removed, doesn't increment current_line in the 'new' file
            pass
            
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
        # Sort valid lines for cleaner prompt
        sorted_lines = sorted(f['valid_lines'])
        files_context += f"\n--- FILE: {f['path']} ---\nVALID LINE NUMBERS FOR COMMENTS: {sorted_lines}\nFULL CONTENT:\n{f['content']}\n"

    prompt = f"""
You are an expert iOS and SwiftUI developer performing a code review.
You MUST use the provided checklist.

Checklist:
{checklist}

Files Context:
{files_context}

INSTRUCTIONS:
1. ONLY comment on line numbers that are explicitly listed in the 'VALID LINE NUMBERS FOR COMMENTS' for each file.
2. If a violation spans multiple lines, use the first line of the violation that is in the valid list.
3. If you find a violation on a line NOT in the valid list, do not include it in the 'comments' array; instead, mention it in the 'summary'.
4. Format response STRICTLY as JSON:
{{
  "summary": "Overall summary of the review",
  "verdict": "APPROVE" or "REQUEST CHANGES",
  "comments": [
    {{
      "path": "file/path.swift",
      "line": 123,
      "body": "Explanation of the violation and fix."
    }}
  ]
}}
    """
    
    models_to_try = ['gemini-flash-latest', 'gemini-pro-latest', 'gemini-2.0-flash']
    
    for model_name in models_to_try:
        for attempt in range(2):
            try:
                print(f"Attempting review with {model_name}...")
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config={'response_mime_type': 'application/json'}
                )
                return json.loads(response.text)
            except Exception as e:
                print(f"Error with {model_name}: {e}")
                time.sleep(5)
    
    raise Exception("Review failed on all models.")

def main():
    try:
        print(f"Starting Gemini Robust Review for PR #{pr_number}...")
        file_data = get_pr_files()
        if not file_data:
            print("No files to review.")
            sys.exit(0)
            
        checklist = read_checklist()
        review_result = review_code(file_data, checklist)
        
        summary = review_result.get("summary", "Gemini Code Review")
        verdict = review_result.get("verdict", "APPROVE")
        comments = review_result.get("comments", [])
        
        # Validation: Double check that line numbers are actually in the diff
        github_comments = []
        for c in comments:
            path = c["path"]
            line = int(c["line"])
            
            # Find the file data for this path
            f_data = next((f for f in file_data if f["path"] == path), None)
            if f_data and line in f_data["valid_lines"]:
                github_comments.append({
                    "path": path,
                    "line": line,
                    "body": c["body"]
                })
            else:
                print(f"Skipping comment on {path}:{line} as it is not in the valid diff range.")
                summary += f"\n\n**Note on {path}:{line}**: {c['body']}"
            
        if github_comments:
            pr.create_review(
                body=f"## 🤖 Gemini Code Review\n\n{summary}",
                event="REQUEST_CHANGES" if verdict == "REQUEST CHANGES" else "COMMENT",
                comments=github_comments
            )
        else:
            pr.create_review(
                body=f"## 🤖 Gemini Code Review\n\n{summary}",
                event="APPROVE" if verdict == "APPROVE" else "COMMENT"
            )
            
        print(f"Review submitted with verdict: {verdict}")
        sys.exit(1 if verdict == "REQUEST CHANGES" else 0)
            
    except Exception as e:
        print(f"FATAL ERROR: {e}")
        pr.create_issue_comment(f"## 🤖 Gemini Code Review\n\nAutomated review encountered an error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
