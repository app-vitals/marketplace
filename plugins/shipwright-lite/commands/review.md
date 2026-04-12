---
description: Review open PRs grouped by session — patch CI failures, address blocking comments, merge when green
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
---

# Review

Process open PRs from the shipwright-lite queue. Group by session for shared context. Patch, approve, and merge.

**This command runs autonomously. Do not pause for user input unless a fundamental acceptance criteria gap is found.**

---

## Step 1: Find Open PRs

Read `state/todos.json`. Find all `shipwright-lite` tasks with `status: "pr_open"`.

If none, print:
```
No open PRs to review.
```
and stop.

Group tasks by `session`. Process one session at a time — reviewing related PRs together gives the agent full context on the feature being built.

For the first session with open PRs, print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEWING SESSION: {session}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Open PRs ({count}):
{For each task: "  #{pr} — {id}: {title}"}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 2: Load Session Context

Before reviewing individual PRs, load shared context for the session:

1. Read `state/todos.json` — get all tasks in this session to understand the full feature scope
2. Check if any tasks are already `merged` — understand what's been completed
3. Read the planning folder if it exists: `planning/{session}/`

This gives the reviewer the full picture of what the feature is trying to accomplish.

---

## Step 3: Review Each PR

For each open PR in the session, in dependency order (PRs with no pending deps first):

### 3a. Fetch PR Context

```bash
gh pr view {pr_number} --repo app-vitals-com/{repo} \
  --json number,title,headRefName,baseRefName,state,statusCheckRollup,reviewDecision,body
gh pr diff {pr_number} --repo app-vitals-com/{repo}
```

### 3b. Check CI Status

From `statusCheckRollup`:

**If all checks PASS or SKIPPED** → proceed to 3c (code review)

**If any check FAILING**:
1. Get the failure logs:
   ```bash
   gh run list --repo app-vitals-com/{repo} --branch {branch} \
     --json databaseId,status,conclusion,name | head -5
   gh run view {run_id} --repo app-vitals-com/{repo} --log-failed
   ```
2. Diagnose: lint error, test failure, type error, build error
3. Set up worktree if not present:
   ```bash
   git -C ~/src/{repo} fetch origin
   git -C ~/src/{repo} worktree add ~/worktrees/{repo}-{branch-slug} origin/{branch} 2>/dev/null || true
   ```
4. Apply a targeted fix in the worktree
5. Run the relevant check locally to verify the fix
6. Commit and push:
   ```bash
   git -C ~/worktrees/{repo}-{branch-slug} add -A
   git -C ~/worktrees/{repo}-{branch-slug} commit -m "fix: address CI failure for {id}"
   git -C ~/worktrees/{repo}-{branch-slug} push
   ```
7. Increment `ci_attempts` in the task's metrics record
8. Wait for CI to re-run: `gh pr checks {pr_number} --repo app-vitals-com/{repo} --watch` (5 min timeout)
9. If CI still failing after 3 attempts: update task to `blocked` in todos.json with the failure details, skip to next PR

**If checks PENDING**: wait up to 5 minutes for them to complete before proceeding.

### 3c. Code Review

Review the diff against the task's `acceptanceCriteria`:

For each criterion, mark: **MET** | **PARTIAL** | **NOT MET**

Also check:
- Are there obvious bugs or silent failures in the changed code?
- Does the code follow existing patterns in the repo?
- Are tests adequate for what's being added?

**If any criterion is NOT MET**: This is a genuine gap, not just a style issue. Comment on the PR with the specific gap, update task to `blocked` in todos.json with a note, and skip to next PR.

**If all criteria are MET or PARTIAL** (PARTIAL is acceptable — the PR ships the core behavior):

Submit a formal GitHub approval:
```bash
gh pr review {pr_number} --repo app-vitals-com/{repo} \
  --approve \
  --body "shipwright-lite:review — SHIP IT. Criteria met."
```

### 3d. Update from Main

Before merging, update the branch:
```bash
gh api -X PUT repos/app-vitals-com/{repo}/pulls/{pr_number}/update-branch
```

If the update triggers CI, wait for it to pass (same watch pattern as 3b).

### 3e. Merge

```bash
gh pr merge {pr_number} --repo app-vitals-com/{repo} --squash --delete-branch
```

---

## Step 4: Update Queue

For each merged PR, update the task in `state/todos.json`:
- Set `status: "merged"`
- Set `mergedAt: "{ISO timestamp}"`

Write the updated todos.json.

Check if any previously-blocked tasks now have all dependencies `merged` — if so, their status can remain `pending` (the execution cron will pick them up automatically).

---

## Step 5: Update Metrics

For each merged task, update its record in `planning/{session}/metrics.jsonl`:

Find the line with matching `task_id` and update:
```json
{
  "merged_at": "{ISO timestamp}",
  "review_iterations": {count of CI fix attempts + comment rounds},
  "first_time_merge": {true if ci_attempts == 1 and no blocking comments},
  "learnings_captured": {count from Step 6},
  "tokens": {
    "execution": "{existing values}",
    "review": { "input": null, "output": null, "cost_usd": null },
    "total_cost_usd": null
  }
}
```

Token fields from the headless run's usage output if available.

---

## Step 6: Learning Loop

After processing all PRs in the session, review what happened:

- Were there CI failures that reveal a missing check in the dev-task workflow?
- Did the code review find patterns that should be in `CLAUDE.md`?
- Did any acceptance criteria come up short in a way that suggests the planning step missed something?

If 1-2 genuine actionable learnings found, append to `CLAUDE.md` in the repo under the relevant section.

Same format as dev-task: `- {what was assumed} → {what happened} → {what to do instead}`

---

## Done

Print a summary of what happened:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEW COMPLETE — {session}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Merged:  {list of PR numbers and task IDs}
Blocked: {list of blocked tasks with reason, or "none"}
Learnings: {count}

{If any tasks in session are now unblocked:}
Unblocked for execution:
{list task IDs now ready to run}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
