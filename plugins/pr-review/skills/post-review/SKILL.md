---
name: post-review
description: Post a PR review to GitHub with inline comments via the gh API. Use when ready to submit a review from PR_REVIEW_<number>.md.
user-invocable: false
---

# Post PR Review to GitHub

Post a review from `PR_REVIEW_<number>.md` to GitHub using the reviews API.

## Prerequisites

- PR branch checked out
- `PR_REVIEW_<number>.md` exists with review content
- **User has explicitly approved posting** — reviews are visible to the PR author and team. Always show the final review body and inline comments, then confirm before submitting. Never auto-post.

## Diff Against the Correct Base Branch

Always diff against the PR's actual base branch, not main:

```bash
base=$(gh pr view <number> --json baseRefName -q '.baseRefName')
git diff "$base"...HEAD
```

PRs targeting feature branches will show wrong diffs if compared to main.

## Tone Shift

The `PR_REVIEW_<number>.md` is a draft for the reviewer. The posted review is from the reviewer to the PR author. Reframe the tone accordingly. Be direct — no filler language ("FYI", "Note:", "Just a heads up").

## Step 1: Get PR Metadata

```bash
gh pr view <number> --json headRefOid -q '.headRefOid'
gh pr view <number> --json baseRefName -q '.baseRefName'
```

## Step 2: Map Inline Comments to Diff Lines

For each issue with a specific file:line reference:

- Only lines in the diff are valid for inline comments
- For new files: any line works
- For modified files: only lines in diff hunks
- If a line isn't in the diff, move the comment to the review body instead

Check the diff to verify line numbers:
```bash
git diff <base>...HEAD -- <file>
```

## Step 3: Build Review JSON

Create `pr_review_<number>.json`:

```json
{
  "commit_id": "<head_sha>",
  "body": "<review body>",
  "event": "APPROVE|COMMENT",
  "comments": [
    {
      "path": "path/to/file.ts",
      "line": 123,
      "side": "RIGHT",
      "body": "Comment text"
    }
  ]
}
```

### Keep the Body Minimal

The review body should be brief — the inline comments carry the detail. A good body is just the verdict and a sentence of context. Don't enumerate what was addressed, list strengths, or repeat inline comment content.

If all issues have inline comments, the body needs only: verdict + one-liner + signature. Don't duplicate inline feedback in the body — the PR author sees both.

## Step 4: Submit

```bash
gh api -X POST /repos/{owner}/{repo}/pulls/{number}/reviews --input pr_review_<number>.json
```

## Step 5: Confirm

Show the link to the posted review from the API response `html_url`.

## Approval Shorthand

For approvals, prefer concise messages:
- "Looks good, approved"
- "Looks good, I have a few suggestions"

Don't repeat the entire review summary for approvals — the inline comments speak for themselves.
