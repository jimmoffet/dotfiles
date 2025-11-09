#!/usr/bin/env python3

import os
import sys
import subprocess
from pathlib import Path
from pydantic import BaseModel


class PRContent(BaseModel):
    title: str
    body: str


def get_current_branch():
    """Get the current git branch name"""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None


def get_default_branch():
    """Get the default branch (main or master) from remote"""
    try:
        # Try to get default branch from remote
        result = subprocess.run(
            ["git", "symbolic-ref", "refs/remotes/origin/HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        # Output is like: refs/remotes/origin/main
        default_branch = result.stdout.strip().split("/")[-1]
        return default_branch
    except subprocess.CalledProcessError:
        # Fallback: try common default branches
        for branch in ["main", "master"]:
            result = subprocess.run(
                ["git", "rev-parse", "--verify", f"origin/{branch}"],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                return branch
        return None


def get_commits_ahead_of_default(current_branch, default_branch):
    """Get list of commit messages ahead of default branch"""
    try:
        result = subprocess.run(
            [
                "git",
                "log",
                f"origin/{default_branch}..{current_branch}",
                "--pretty=format:%s%n%n%b",
                "--reverse",  # Oldest first
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        commits = result.stdout.strip()
        return commits if commits else None
    except subprocess.CalledProcessError:
        return None


def get_combined_diff(default_branch):
    """Get combined diff of all changes ahead of default branch"""
    try:
        result = subprocess.run(
            [
                "git",
                "diff",
                f"origin/{default_branch}...HEAD",
                "-U15",  # Show 15 lines of context (same as ai_commit.py)
                "--function-context",  # Show entire function context
                "--ignore-space-change",  # Ignore whitespace-only changes
                "--no-color",  # Ensure no ANSI color codes
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None


def detect_template_type_from_branch(branch_name):
    """Auto-detect template type from branch name"""
    branch_lower = branch_name.lower()
    
    # Common branch naming patterns
    patterns = {
        "feat/": "feature",
        "feature/": "feature",
        "fix/": "bugfix",
        "bugfix/": "bugfix",
        "hotfix/": "hotfix",
        "docs/": "docs",
        "chore/": "chore",
        "infra/": "infra",
    }
    
    for pattern, template_type in patterns.items():
        if branch_lower.startswith(pattern):
            return template_type
    
    return None


def detect_template_type_from_commits(commits):
    """Auto-detect template type from commit prefixes"""
    if not commits:
        return None
    
    # Count conventional commit prefixes
    prefix_counts = {
        "feat": 0,
        "fix": 0,
        "docs": 0,
        "chore": 0,
        "refac": 0,
        "hotfix": 0,
    }
    
    for line in commits.split("\n"):
        line = line.strip().lower()
        for prefix in prefix_counts:
            if line.startswith(f"{prefix}:"):
                prefix_counts[prefix] += 1
    
    # Return most common prefix type
    max_prefix = max(prefix_counts, key=prefix_counts.get)
    if prefix_counts[max_prefix] > 0:
        if max_prefix == "feat":
            return "feature"
        elif max_prefix == "fix":
            return "bugfix"
        elif max_prefix == "refac":
            return "feature"  # Refactors often use feature template
        return max_prefix
    
    return None


def find_pr_template(template_type=None, current_branch=None, commits=None):
    """Find PR template following search order"""
    # Auto-detect template type if not specified
    if not template_type:
        template_type = detect_template_type_from_branch(current_branch) if current_branch else None
    
    if not template_type:
        template_type = detect_template_type_from_commits(commits)
    
    # Default to feature if still no type
    if not template_type:
        template_type = "feature"
    
    # Search order
    search_paths = []
    
    # 1. Project-specific templates with type
    if template_type:
        search_paths.append(Path(f".github/PULL_REQUEST_TEMPLATE/{template_type}.md"))
    
    # 2. Project-specific single template
    search_paths.append(Path(".github/pull_request_template.md"))
    
    # 3. Dotfiles templates with type
    dotfiles_template_dir = Path.home() / "dotfiles" / "scripts" / "PULL_REQUEST_TEMPLATE"
    if template_type:
        search_paths.append(dotfiles_template_dir / f"{template_type}.md")
    
    # 4. Dotfiles default template
    search_paths.append(dotfiles_template_dir / "feature.md")
    
    # Find first existing template
    for template_path in search_paths:
        if template_path.exists():
            try:
                return template_path.read_text(), str(template_path)
            except Exception:
                continue
    
    # Fallback: basic template
    return """## Description
[Describe the changes]

## Changes
[List of changes]

## Testing
[How to test]
""", "built-in"


def get_openai_api_key():
    """Get OpenAI API key from Keychain or environment variable"""
    # First try Keychain
    try:
        result = subprocess.run(
            [
                "security",
                "find-generic-password",
                "-a",
                os.getenv("USER"),
                "-s",
                "openai-api-key",
                "-w",
            ],
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


def generate_pr_content(commits, git_diff, template_content, user_guidance=None):
    """Generate PR title and body using OpenAI"""
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
    max_diff_chars = int(os.getenv("AI_PR_MAX_CHARS", "100000"))
    if len(git_diff) > max_diff_chars:
        git_diff = git_diff[:max_diff_chars] + "\n\n[diff truncated...]"

    client = OpenAI(api_key=api_key)

    # Construct prompt
    prompt_parts = [
        "Based on the commit messages and git diff below, generate a pull request.",
        "",
        "**Commit Messages:**",
        commits,
        "",
        "**Git Diff:**",
        git_diff,
        "",
        "**PR Template to follow:**",
        template_content,
        "",
        "Generate:",
        "- title: A concise PR title using conventional commit format (feat:, fix:, docs:, etc.)",
        "- body: Fill in the template sections based on the commits and code changes",
    ]

    if user_guidance:
        prompt_parts.insert(1, f"**User Guidance:** {user_guidance}")
        prompt_parts.insert(2, "")

    prompt = "\n".join(prompt_parts)

    try:
        response = client.chat.completions.parse(
            model="gpt-4.1-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You are a helpful assistant that analyzes code changes and writes clear, comprehensive pull request descriptions. Follow the provided template structure. Use conventional commit prefixes (feat:, fix:, docs:, refactor:, chore:, etc.) in titles.",
                },
                {"role": "user", "content": prompt},
            ],
            response_format=PRContent,
            max_completion_tokens=1500,
            temperature=0.3,
        )

        # Optional usage diagnostics
        if os.getenv("AI_PR_USAGE"):
            usage = getattr(response, "usage", None)
            if usage:
                prompt_tokens = getattr(usage, "prompt_tokens", "?")
                completion_tokens = getattr(usage, "completion_tokens", "?")
                total_tokens = getattr(usage, "total_tokens", "?")
                comp_details = getattr(usage, "completion_tokens_details", None)
                reasoning_tokens = (
                    getattr(comp_details, "reasoning_tokens", None)
                    if comp_details
                    else None
                )
                print(
                    f"[ai-usage] prompt={prompt_tokens} completion={completion_tokens} total={total_tokens}"
                    + (
                        f" reasoning={reasoning_tokens}"
                        if reasoning_tokens is not None
                        else ""
                    ),
                    file=sys.stderr,
                )

        # Parse the structured response
        pr_content = response.choices[0].message.parsed
        return pr_content.title, pr_content.body

    except Exception as e:
        print(f"OpenAI API error: {e}", file=sys.stderr)
        return None


def create_pull_request(title, body, base_branch, current_branch, draft=False):
    """Create PR using GitHub CLI"""
    # Check if gh is installed
    try:
        subprocess.run(
            ["gh", "--version"],
            capture_output=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Error: GitHub CLI (gh) is not installed or not in PATH", file=sys.stderr)
        print("Install with: brew install gh", file=sys.stderr)
        return None

    # Check if authenticated
    try:
        subprocess.run(
            ["gh", "auth", "status"],
            capture_output=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        print("Error: Not authenticated with GitHub CLI", file=sys.stderr)
        print("Run: gh auth login", file=sys.stderr)
        return None

    # Create PR
    cmd = [
        "gh", "pr", "create",
        "--base", base_branch,
        "--head", current_branch,
        "--title", title,
        "--body", body,
    ]
    
    if draft:
        cmd.append("--draft")

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
        )
        # gh pr create outputs the PR URL
        pr_url = result.stdout.strip()
        return pr_url
    except subprocess.CalledProcessError as e:
        error_msg = e.stderr.strip() if e.stderr else str(e)
        print(f"Error creating PR: {error_msg}", file=sys.stderr)
        return None


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate and create AI-powered pull requests")
    parser.add_argument("guidance", nargs="?", help="Optional guidance for AI to customize PR title/body")
    parser.add_argument("--template", help="Specify template type (feature, bugfix, hotfix, etc.)")
    parser.add_argument("--draft", action="store_true", help="Create as draft PR")
    parser.add_argument("--no-ai", action="store_true", help="Skip AI generation, use commits as-is")
    parser.add_argument("--base", help="Target branch (defaults to repo default branch)")

    args = parser.parse_args()

    # Check if we're in a git repository
    try:
        subprocess.run(
            ["git", "rev-parse", "--git-dir"],
            capture_output=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        print("Error: Not in a git repository", file=sys.stderr)
        sys.exit(1)

    # Get current branch
    current_branch = get_current_branch()
    if not current_branch:
        print("Error: Could not determine current branch", file=sys.stderr)
        sys.exit(1)

    # Get default branch
    default_branch = args.base if args.base else get_default_branch()
    if not default_branch:
        print("Error: Could not determine default branch", file=sys.stderr)
        sys.exit(1)

    # Check if current branch is default branch
    if current_branch == default_branch:
        print(f"Error: Cannot create PR from default branch ({default_branch})", file=sys.stderr)
        sys.exit(1)

    # Get commits ahead of default
    commits = get_commits_ahead_of_default(current_branch, default_branch)
    if not commits:
        print(f"Error: No commits ahead of {default_branch}", file=sys.stderr)
        sys.exit(1)

    # Get combined diff
    git_diff = get_combined_diff(default_branch)
    if not git_diff:
        print(f"Error: Could not get diff against {default_branch}", file=sys.stderr)
        sys.exit(1)

    # Find PR template
    template_content, template_source = find_pr_template(
        args.template, current_branch, commits
    )
    print(f"Using template: {template_source}", file=sys.stderr)

    # Generate or create PR content
    if args.no_ai:
        # Simple mode: use commits as title/body
        title = commits.split("\n")[0][:50]  # First line, max 50 chars
        body = f"{commits}\n\n---\n\n{template_content}"
    else:
        # AI mode
        print("Generating PR content with AI...", file=sys.stderr)
        result = generate_pr_content(commits, git_diff, template_content, args.guidance)
        if not result:
            print("Error: Failed to generate PR content", file=sys.stderr)
            sys.exit(1)
        title, body = result

    # Create PR
    print(f"Creating PR: {title}", file=sys.stderr)
    pr_url = create_pull_request(title, body, default_branch, current_branch, args.draft)
    
    if pr_url:
        print(pr_url)  # Output PR URL to stdout for shell capture
        sys.exit(0)
    else:
        print("Error: Failed to create PR", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
