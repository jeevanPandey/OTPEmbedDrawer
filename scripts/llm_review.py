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

def get_pr_files():
    """Returns a list of files changed in the PR with their status and content."""
    files = pr.get_files()
    file_data = []
    for file in files:
        if file.status == "removed":
            continue
        
        # Only review Swift files for now
        if not file.filename.endswith(".swift"):
            continue
            
        try:
            # Fetch the full content of the file from the PR branch
            content = repo.get_contents(file.filename, ref=pr.head.sha).decoded_content.decode("utf-8")
            file_data.append({
                "path": file.filename,
                "content": content,
                "patch": file.patch # This contains the diff for this specific file
            })
        except Exception as e:
            print(f"Warning: Could not fetch content for {file.filename}: {e}")
            
    return file_data

def read_checklist():
    with open("codereview_ios.md", "r") as f:
        return f.read()

def review_code(file_data, checklist):
    # Prepare the prompt with all file contents and their diffs
    files_context = ""
    for f in file_data:
        files_context += f"\n--- FILE: {f['path']} ---\nFULL CONTENT:\n{f['content']}\n\nDIFF (PATCH):\n{f['patch']}\n"

    prompt = f"""
You are an expert iOS and SwiftUI developer. Your task is to perform a code review on the following files from a Pull Request.
You MUST use the provided checklist to evaluate the changes.

Checklist:
{checklist}

Files Context (Full content and their specific diffs):
{files_context}

INSTRUCTIONS:
1. Review the changes against each item in the checklist.
2. For each violation, identify the EXACT line number in the FULL CONTENT of the file.
3. Format your response STRICTLY as a JSON object with the following structure:
{{
  "summary": "Overall summary of the review",
  "verdict": "APPROVE" or "REQUEST CHANGES",
  "comments": [
    {{
      "path": "file/path.swift",
      "line": 123,
      "body": "Clear explanation of the violation and suggested fix."
    }}
  ]
}}
4. If there are no violations, return an empty comments list and "APPROVE".
5. Ensure the JSON is valid and contains no extra text outside the JSON block.
    """
    
    models_to_try = ['gemini-flash-latest', 'gemini-pro-latest', 'gemini-2.0-flash']
    
    for model_name in models_to_try:
        for attempt in range(2):
            try:
                print(f"Attempting review with {model_name} (Attempt {attempt + 1})...")
                # Use JSON output mode if supported, otherwise just parse the string
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config={
                        'response_mime_type': 'application/json'
                    }
                )
                
                # Parse the response to ensure it's valid JSON
                return json.loads(response.text)
            except Exception as e:
                error_msg = str(e).upper()
                if "429" in error_msg or "QUOTA" in error_msg:
                    print(f"Quota issue with {model_name}. Waiting 15s...")
                    time.sleep(15)
                    continue
                else:
                    print(f"Model {model_name} failed: {e}")
                    break
    
    raise Exception("All models failed to perform the review.")

def main():
    try:
        print(f"Starting Gemini Inline Review for PR #{pr_number}...")
        
        file_data = get_pr_files()
        if not file_data:
            print("No Swift files to review.")
            sys.exit(0)
            
        checklist = read_checklist()
        review_result = review_code(file_data, checklist)
        
        summary = review_result.get("summary", "Gemini Code Review")
        verdict = review_result.get("verdict", "APPROVE")
        comments = review_result.get("comments", [])
        
        print(f"Review complete. Verdict: {verdict}. Found {len(comments)} issues.")
        
        # Convert comments to the format expected by the GitHub Review API
        # We need to filter out comments that might have invalid line numbers
        github_comments = []
        for c in comments:
            github_comments.append({
                "path": c["path"],
                "line": int(c["line"]),
                "body": c["body"]
            })
            
        # Post the review with inline comments
        if github_comments:
            event = "REQUEST_CHANGES" if verdict == "REQUEST CHANGES" else "COMMENT"
            pr.create_review(
                body=f"## 🤖 Gemini Code Review\n\n{summary}",
                event=event,
                comments=github_comments
            )
        else:
            # Just post a summary if no specific inline comments
            event = "APPROVE" if verdict == "APPROVE" else "COMMENT"
            pr.create_review(
                body=f"## 🤖 Gemini Code Review\n\n{summary}",
                event=event
            )
            
        if verdict == "REQUEST CHANGES":
            sys.exit(1)
        else:
            sys.exit(0)
            
    except Exception as e:
        print(f"FATAL ERROR: {e}")
        # Post a fallback comment if the whole process fails
        pr.create_issue_comment(f"## 🤖 Gemini Code Review\n\nError performing automated review: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
