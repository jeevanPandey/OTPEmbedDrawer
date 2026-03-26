import os
import sys
import json
import requests
import time
from google import genai
from github import Github

# Setup Gemini
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

# Setup GitHub
g = Github(os.environ["GITHUB_TOKEN"])
repo_name = os.environ["GITHUB_REPOSITORY"]
pr_number = int(os.environ["PR_NUMBER"])
repo = g.get_repo(repo_name)
pr = repo.get_pull(pr_number)

def get_pr_diff():
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
    
    # List of models to try in order of preference
    models_to_try = ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-pro']
    
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
                if "429" in error_msg or "QUOTA" in error_msg or "EXHAUSTED" in error_msg:
                    print(f"Quota hit for {model_name}. Waiting 15s...")
                    time.sleep(15)
                    continue
                elif "404" in error_msg or "NOT_FOUND" in error_msg:
                    print(f"Model {model_name} not found. Trying next model...")
                    break # Break inner loop to try next model
                else:
                    print(f"Unexpected error with {model_name}: {e}")
                    break
    
    raise Exception("All models failed to perform the review. Please check your API key and quota.")

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
