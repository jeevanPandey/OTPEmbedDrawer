import os
import sys
import json
import requests
import google.generativeai as genai
from github import Github

# Setup Gemini
genai.configure(api_key=os.environ["GEMINI_API_KEY"])
model = genai.GenerativeModel('gemini-1.5-flash')

# Setup GitHub
g = Github(os.environ["GITHUB_TOKEN"])
repo_name = os.environ["GITHUB_REPOSITORY"]
pr_number = int(os.environ["PR_NUMBER"])
repo = g.get_repo(repo_name)
pr = repo.get_pull(pr_number)

def get_pr_diff():
    # Use the GitHub API to get the diff directly
    headers = {
        "Authorization": f"token {os.environ['GITHUB_TOKEN']}",
        "Accept": "application/vnd.github.v3.diff"
    }
    response = requests.get(pr.diff_url, headers=headers)
    return response.text

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
    
    response = model.generate_content(prompt)
    return response.text

def main():
    try:
        print(f"Reviewing PR #{pr_number}...")
        diff = get_pr_diff()
        checklist = read_checklist()
        
        review_result = review_code(diff, checklist)
        
        # Post comment to PR
        pr.create_issue_comment(f"## 🤖 Gemini Code Review\n\n{review_result}")
        
        # Fail the PR if "REQUEST CHANGES" is present
        if "REQUEST CHANGES" in review_result:
            print("Review suggests changes. Failing the check.")
            sys.exit(1)
        else:
            print("Review approved.")
            sys.exit(0)
            
    except Exception as e:
        print(f"Error during review: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
