---
name: ca-review-prs
description: Fetch PRs needing review and process them in parallel using cloud-agent CLI
argument-hint: "[pr-numbers...] or [repo] [--limit N]"
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

# Cloud Agent Parallel PR Review

Review multiple GitHub pull requests in parallel using the cloud-agent CLI (ca).

**Arguments**: $ARGUMENTS

## Prerequisites

This command requires the cloud-agent CLI (`ca`). Install from:
https://github.com/app-vitals/cloud-agent

```bash
command -v ca >/dev/null 2>&1 || echo "ca not installed"
```

If `ca` is not available, stop and show installation instructions.

---

## Mode 1: PR Numbers Provided

If arguments are PR numbers (e.g., `626 636 637`), skip to **Queue Reviews** below.

---

## Mode 2: Fetch Review Queue

If no PR numbers provided (or repo specified), fetch PRs needing your review.

### Setup

1. **Get your GitHub username**:
   ```bash
   gh auth status
   ```

2. **Determine target repository**:
   - If repo specified (e.g., `owner/repo`), use that
   - Otherwise, use current repo: `gh repo view --json nameWithOwner`

3. **Parse options**:
   - `--limit N`: Max PRs to fetch (default: 20)

### Fetch PRs

4. **Get open PRs**:
   ```bash
   gh pr list --state open --json number,title,author,createdAt,updatedAt,reviews,reviewRequests,isDraft,commits --limit <limit>
   ```
   The `commits` field is needed to compare the latest commit date against your review timestamp (do not rely on `updatedAt` for this — see category C below).

5. **Filter PRs** into categories:

   **A. Review Requested** (highest priority):
   - PRs where you're in `reviewRequests`

   **B. Not Yet Reviewed**:
   - PRs where you haven't submitted any review in ANY state (APPROVED, CHANGES_REQUESTED, COMMENTED, DISMISSED all count as "reviewed")
   - Exclude your own PRs (author != you)
   - Exclude drafts

   **C. Updated Since Your Review**:
   - PRs where you reviewed, but there are new commits since your last review
   - To check: fetch the PR's commits and compare the latest commit date against your review `submittedAt`
   - Do NOT use the PR `updatedAt` field — it gets bumped by any activity including your own review comments
   - Candidates for `/review-pr-update`

### Display Queue

6. **Show the queue**:

   ```
   ## PR Review Queue for <owner/repo>

   ### Review Requested (X)
   | PR | Title | Author | Age |
   |----|-------|--------|-----|
   | #123 | Add feature X | @alice | 2d |

   ### Updated Since Your Review (X)
   | PR | Title | Author | Updated | Your Review |
   |----|-------|--------|---------|-------------|
   | #456 | Fix bug Y | @bob | 3h ago | 2d ago |

   ### Not Yet Reviewed (X)
   | PR | Title | Author | Age |
   |----|-------|--------|-----|
   | #789 | Refactor Z | @carol | 5d |

   Total: X PRs need attention
   ```

7. **Ask user how to proceed**:
   - "Queue all for parallel review" → Continue to Queue Reviews
   - "Select specific PRs" → User picks numbers
   - "Review one at a time" → Use `/review-pr` instead
   - "Exit" → Done

---

## Queue Reviews

For each PR number, use the `--repo` flag with `org/name` format:
```bash
ca pr review <pr_number> --repo <org/name>
```

**Important**: `ca pr review` takes PR numbers (not full GitHub URLs) with an optional `--repo` flag. If `--repo` is omitted, it uses the current git repo.

Track each queued task:
| PR | Task ID | Status |
|----|---------|--------|
| 123 | task-abc | queued |
| 456 | task-def | queued |

## Monitor Progress

For each task, launch a background monitor:
```bash
ca task wait <task_id> && ca task get <task_id>
```

Use `run_in_background=true` for all monitoring tasks.

Periodically report progress:
- Tasks completed: X/Y
- Tasks in progress: Z
- Tasks failed: N

## Handle Completed Reviews

**If succeeded**:
```bash
ca task get <task_id>
```
Show summary of findings.

**If failed**:
```bash
ca task logs <task_id>
```
Ask user: Retry, Skip, or Debug?

## Apply Reviews (One at a Time)

Process reviews **sequentially** — finish one PR before moving to the next:

For the next completed review:

1. **Checkout the PR branch first**:
   ```bash
   gh pr checkout <number>
   ```

2. **Apply the review** (from project root — `ca task apply` writes files to CWD):
   ```bash
   ca task apply <task_id> --no-resume
   ```
   This creates `PR_REVIEW_<number>.md` in the current directory.

3. **Verify and trim** the review content:
   - **Always verify claims against the actual PR diff** using `gh pr diff <number>` (NOT `git diff main...HEAD` which may include unrelated commits from the checked-out branch)
   - Cloud agent reviews often have false positives on "critical" findings — check the code before trusting severity ratings
   - Cloud agent reviews tend to be verbose (~400+ lines) — trim to essentials before presenting
   - Apply the same "keep it tight" standard from `/review-pr`: 2-5 actionable items, drop low-confidence nitpicks
   - Don't call out obvious CI failures (lint, formatting) in reviews — the author will see and fix them
   - Show the review summary
   - Let the user edit or adjust the review
   - Discuss any findings

4. **Get explicit approval before posting** — reviews are visible to the PR author and team. Always show the final review body and inline comments, then ask the user to confirm before submitting. Never auto-post.

5. **Post to GitHub** using the `post-review` skill — it handles building the review JSON with inline comments and submitting via `gh api`

6. **Move to the next PR** — repeat from step 1

---

## Example Usage

**Fetch queue and review**:
```bash
/ca-review-prs
/ca-review-prs anthropics/claude-code
/ca-review-prs --limit 10
```

**Review specific PRs**:
```bash
/ca-review-prs 626 636 637 642
```

## Tips

- Run without arguments to see what needs review first
- "Updated since review" PRs are candidates for `/review-pr-update`
- Start with 3-5 PRs to gauge timing
- Apply and iterate on one review before moving to next

## Notes

- All reviews run in parallel on cloud infrastructure
- Failed reviews don't block others
- Excludes draft PRs and your own PRs from queue
- Queue state is session-only (not persisted)
