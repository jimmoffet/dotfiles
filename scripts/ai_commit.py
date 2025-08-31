#!/usr/bin/env python3

import os
import sys
import subprocess
import json
from pathlib import Path

def get_git_diff():
    """Get the staged git diff"""
    try:
        # Get staged changes
        result = subprocess.run(
            ['git', 'diff', '--cached'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def estimate_tokens(text):
    """Rough token estimation (1 token ≈ 4 characters)"""
    return len(text) // 4

def generate_commit_message(user_message, git_diff):
    """Generate commit message using OpenAI API"""
    try:
        from openai import OpenAI
    except ImportError:
        print("OpenAI SDK not available", file=sys.stderr)
        return None
    
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        print("OPENAI_API_KEY not found", file=sys.stderr)
        return None
    
    # Limit diff size to prevent expensive API calls
    max_diff_chars = 8000  # ~2000 tokens
    if len(git_diff) > max_diff_chars:
        git_diff = git_diff[:max_diff_chars] + "\n\n[diff truncated...]"
    
    client = OpenAI(api_key=api_key)
    
    # Construct prompt
    if user_message:
        prompt = f"""Based on the git diff below, enhance this commit message: "{user_message}"

Create a commit message with:
1. A short summary line (under 50 chars) that incorporates the user's message
2. A blank line
3. A detailed description of the changes

Git diff:
{git_diff}"""
    else:
        prompt = f"""Based on the git diff below, generate a commit message with:
1. A short summary line (under 50 chars)
2. A blank line  
3. A detailed description of the changes

Git diff:
{git_diff}"""
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a helpful assistant that writes clear, conventional commit messages. Follow conventional commit format when appropriate."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=300,
            temperature=0.3
        )
        
        return response.choices[0].message.content.strip()
    
    except Exception as e:
        print(f"OpenAI API error: {e}", file=sys.stderr)
        return None

def main():
    user_message = sys.argv[1] if len(sys.argv) > 1 else ""
    
    # Check if we're in a git repository
    if not Path('.git').exists():
        print("Not in a git repository", file=sys.stderr)
        sys.exit(1)
    
    # Get staged changes
    git_diff = get_git_diff()
    if not git_diff:
        print("No staged changes found", file=sys.stderr)
        sys.exit(1)
    
    # Generate commit message
    ai_message = generate_commit_message(user_message, git_diff)
    
    if ai_message:
        print(ai_message)
        sys.exit(0)
    else:
        # Fallback to user message or default
        fallback = user_message if user_message else "Update files"
        print(fallback)
        sys.exit(1)

if __name__ == "__main__":
    main()
