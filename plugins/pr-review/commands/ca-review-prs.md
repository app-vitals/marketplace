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
   gh pr list --state open --json number,title,author,createdAt,updatedAt,reviews,reviewRequests,isDraft --limit <limit>
   ```

5. **Filter PRs** into categories:

   **A. Review Requested** (highest priority):
   - PRs where you're in `reviewRequests`

   **B. Not Yet Reviewed**:
   - PRs where you haven't submitted any review
   - Exclude your own PRs (author != you)
   - Exclude drafts

   **C. Updated Since Your Review**:
   - PRs where you reviewed, but `updatedAt` > your review timestamp
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

For each PR number:
```bash
ca pr review <pr_number>
```

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

## Apply Reviews

For each successful review, ask user:

"PR #<number> review complete. Options:"
1. Apply review locally: `ca task apply <task_id> --no-resume`
2. View review details first
3. Skip to next PR
4. Examine PR branch: `gh pr checkout <number>`

When applying:
```bash
ca task apply <task_id> --no-resume
```

This brings the review into your local session for iteration before posting.

## Post-Apply Workflow

After applying each review:
- Review file is created: `PR_REVIEW_<number>.md`
- User can edit, discuss, or post
- Use standard review-pr workflow for posting

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
