#!/usr/bin/env python3

import os
import sys
import subprocess
import json
from pathlib import Path
from pydantic import BaseModel


class CommitMessage(BaseModel):
    summary: str
    description: str


def get_git_diff():
    """Get the staged git diff"""
    try:
        # Get staged changes
        result = subprocess.run(["git", "diff", "--cached"], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None


def estimate_tokens(text):
    """Rough token estimation (1 token ≈ 4 characters)"""
    return len(text) // 4


def get_openai_api_key():
    """Get OpenAI API key from Keychain or environment variable"""
    # First try Keychain
    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-a", os.getenv("USER"), "-s", "openai-api-key", "-w"],
            capture_output=True,
            text=True,
            check=True,
        )
        api_key = result.stdout.strip()
        if api_key:
            return api_key
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    # Fallback to environment variable
    return os.getenv("OPENAI_API_KEY")


def generate_commit_message(user_message, git_diff):
    """Generate commit message using OpenAI Chat Completions API with structured outputs"""
    try:
        from openai import OpenAI
    except ImportError:
        print("OpenAI SDK not available", file=sys.stderr)
        return None

    api_key = get_openai_api_key()
    if not api_key:
        print("OPENAI_API_KEY not found", file=sys.stderr)
        return None

    # Limit diff size to prevent expensive API calls
    max_diff_chars = 8000  # ~2000 tokens
    if len(git_diff) > max_diff_chars:
        git_diff = git_diff[:max_diff_chars] + "\n\n[diff truncated...]"

    client = OpenAI(api_key=api_key)

    # Construct prompt for structured outputs
    if user_message:
        prompt = f"""Based on the git diff below, enhance this user's commit message: "{user_message}"

Analyze the changes and create a commit message with:
- summary: Reproduce the user's commit message exactly, make no changes
- description: A more detailed description of what was changed

Git diff:
{git_diff}"""
    else:
        prompt = f"""Based on the git diff below, generate a commit message.

Analyze the changes and create a commit message with:
- summary: A concise summary line (aim for under 50 characters)
- description: A more detailed description of what was changed

Git diff:
{git_diff}"""

    try:
        # Use Chat Completions API with structured outputs
        response = client.chat.completions.parse(
            model="gpt-5-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful assistant that analyzes code changes and writes clear, conventional commit messages. Follow conventional commit format (e.g., 'feat:', 'fix:', 'docs:', etc.). Limit description to ≤ 12 lines, ≤ 600 characters total.",
                },
                {"role": "user", "content": prompt},
            ],
            response_format=CommitMessage,
            max_completion_tokens=600,
            # temperature=0.3,
        )

        # Parse the structured response
        commit_data = response.choices[0].message.parsed
        summary = commit_data.summary
        description = commit_data.description

        # Check if summary is over 50 characters and warn
        if len(summary) > 50:
            print(f"Warning: Summary is {len(summary)} characters (recommended: ≤50)", file=sys.stderr)

        if user_message:
            summary = user_message
        # Reconstruct the commit message with proper formatting
        if description.strip():
            return f"{summary}\n\n{description}"
        else:
            return summary

    except Exception as e:
        # Handle specific OpenAI API errors
        try:
            from openai import APIError, APIConnectionError, RateLimitError, AuthenticationError

            if isinstance(e, AuthenticationError):
                print(f"OpenAI API authentication error: {e}", file=sys.stderr)
            elif isinstance(e, RateLimitError):
                print(f"OpenAI API rate limit exceeded: {e}", file=sys.stderr)
            elif isinstance(e, APIConnectionError):
                print(f"OpenAI API connection error: {e}", file=sys.stderr)
            elif isinstance(e, APIError):
                print(f"OpenAI API error: {e}", file=sys.stderr)
            else:
                print(f"Unexpected error: {e}", file=sys.stderr)
        except ImportError:
            # If we can't import OpenAI error types, just show the general error
            print(f"OpenAI API error: {e}", file=sys.stderr)

        return None


def main():
    user_message = sys.argv[1] if len(sys.argv) > 1 else ""

    # Check if we're in a git repository
    if not Path(".git").exists():
        print("Error: Not in a git repository", file=sys.stderr)
        sys.exit(1)

    # Get staged changes
    git_diff = get_git_diff()
    if not git_diff:
        print("Error: No staged changes found", file=sys.stderr)
        sys.exit(1)

    # Generate commit message
    ai_message = generate_commit_message(user_message, git_diff)

    if ai_message:
        print(ai_message)
        sys.exit(0)
    else:
        # AI failed, exit with error code to trigger fallback in gitgo
        print("AI commit generation failed", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
