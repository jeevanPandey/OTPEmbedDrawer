import os
import sys
import json
import requests
import time
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

def get_pr_diff():
    # Use the official API endpoint for the PR to get the diff
    url = f"https://api.github.com/repos/{repo_name}/pulls/{pr_number}"
    headers = {
        "Authorization": f"token {os.environ['GITHUB_TOKEN']}",
        "Accept": "application/vnd.github.v3.diff"
    }
    print(f"Fetching diff from: {url}")
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"Error fetching diff: {response.status_code} - {response.text}")
        return f"Error: Could not fetch PR diff (Status {response.status_code})."
    
    diff_text = response.text
    if not diff_text or len(diff_text.strip()) == 0:
        print("Warning: API returned an empty diff.")
        return "No code changes found in this PR."
        
    print(f"Successfully fetched diff ({len(diff_text)} bytes)")
    return diff_text

def read_checklist():
    with open("codereview_ios.md", "r") as f:
        return f.read()

def review_code(diff, checklist):
    prompt = f"""
You are an expert iOS and SwiftUI developer. Your task is to perform a code review on the following Pull Request diff.
You MUST use the provided checklist to evaluate the changes.

Checklist:
{checklist}

PR Diff:
{diff}

Instructions:
1. Review the diff against each item in the checklist.
2. For each violation, provide a clear explanation and suggest a fix.
3. If the code introduces CRITICAL violations (e.g., memory leaks, security issues, breaking architecture), explicitly state "CRITICAL VIOLATION FOUND".
4. Provide a summary of your review.
5. End your review with a final verdict: "APPROVE" or "REQUEST CHANGES".
    """
    
    # List of models CONFIRMED available in your logs
    models_to_try = ['gemini-flash-latest', 'gemini-pro-latest', 'gemini-2.0-flash']
    
    for model_name in models_to_try:
        for attempt in range(2):
            try:
                print(f"Attempting review with {model_name} (Attempt {attempt + 1})...")
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt
                )
                return response.text
            except Exception as e:
                error_msg = str(e).upper()
                if "429" in error_msg or "QUOTA" in error_msg:
                    print(f"Quota issue with {model_name}. Waiting 15s...")
                    time.sleep(15)
                    continue
                else:
                    print(f"Model {model_name} failed: {e}")
                    break # Try next model
    
    raise Exception("All confirmed models failed. Please verify billing/quota in AI Studio.")

def main():
    try:
        print(f"Starting Gemini Review for PR #{pr_number}...")
        diff = get_pr_diff()
        checklist = read_checklist()
        
        review_result = review_code(diff, checklist)
        
        # Post comment to PR
        pr.create_issue_comment(f"## 🤖 Gemini Code Review\n\n{review_result}")
        
        if "REQUEST CHANGES" in review_result:
            print("Review complete: Changes requested.")
            sys.exit(1)
        else:
            print("Review complete: Approved.")
            sys.exit(0)
            
    except Exception as e:
        print(f"FATAL ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
