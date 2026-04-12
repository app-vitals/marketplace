---
description: Review open PRs grouped by session — patch CI failures, address blocking comments, merge when green
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
---

# Review

Process open PRs from the shipwright-lite queue. Group by session for shared context. Patch, approve, and merge.

**This command runs autonomously. Do not pause for user input unless a fundamental acceptance criteria gap requires a design decision.**

---

## Step 1: Find Open PRs

Read `state/todos.json`. Find all `shipwright-lite` tasks with `status: "pr_open"`.

If none, print:
```
No open PRs to review.
```
and stop.

Group tasks by `session`. Process one session at a time — reviewing related PRs together gives the reviewer full context on the feature being built.

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

Before reviewing individual PRs, load shared context:

1. Read all tasks in this session from `state/todos.json` — understand the full feature scope and what's already merged
2. Read the planning folder if it exists: `planning/{session}/`
3. For each open PR, note its dependencies — review PRs whose dependencies are all `merged` first

---

## Step 3: Review Each PR

For each open PR in dependency order:

### 3a. Fetch PR Context

```bash
gh pr view {pr_number} --repo app-vitals-com/{repo} \
  --json number,title,headRefName,baseRefName,state,statusCheckRollup,reviewDecision,body,additions,deletions,changedFiles
gh pr diff {pr_number} --repo app-vitals-com/{repo}
```

Print:
```
PR #{pr_number} — {title}
Size: +{additions} -{deletions} across {changedFiles} files
CI: {overall status}
Review: {reviewDecision}
```

### 3b. Handle CI

**All checks PASS or SKIPPED** → proceed to 3c

**Any check FAILING**:
1. Get failure logs:
   ```bash
   gh api repos/app-vitals-com/{repo}/actions/runs?branch={branch} \
     --jq '.workflow_runs[0] | {id, status, conclusion}'
   gh api repos/app-vitals-com/{repo}/actions/runs/{run_id}/jobs \
     --jq '.jobs[] | select(.conclusion=="failure") | {name, id}'
   gh api repos/app-vitals-com/{repo}/actions/jobs/{job_id}/logs
   ```
2. Diagnose: lint error, type error, test failure, build error
3. Set up worktree if not present:
   ```bash
   git -C ~/src/{repo} fetch origin
   git -C ~/src/{repo} worktree add ~/worktrees/{repo}-{branch-slug} origin/{branch} 2>/dev/null || \
     git -C ~/worktrees/{repo}-{branch-slug} pull
   ```
4. Apply a targeted fix. Read the full file before editing — understand why the failure is happening.
5. Verify locally:
   ```bash
   # Run the specific failing check in the worktree, e.g.:
   cd ~/worktrees/{repo}-{branch-slug} && bun lint 2>&1 | tail -20
   cd ~/worktrees/{repo}-{branch-slug} && bun test --passWithNoTests 2>&1 | tail -20
   ```
6. Commit and push:
   ```bash
   git -C ~/worktrees/{repo}-{branch-slug} add -A
   git -C ~/worktrees/{repo}-{branch-slug} commit -m "fix: address CI failure for {id}"
   git -C ~/worktrees/{repo}-{branch-slug} push
   ```
7. Wait for CI: poll every 60s up to 5 minutes:
   ```bash
   gh api repos/app-vitals-com/{repo}/actions/runs?branch={branch} \
     --jq '.workflow_runs[0] | {status, conclusion}'
   ```
8. If CI still failing after 3 fix attempts: mark task `blocked` in todos.json with the failure details. Skip to next PR.

**Checks PENDING**: wait up to 5 minutes, polling every 60s.

### 3c. Code Review

Read the full diff carefully. This is not a quick scan — read every changed file.

**Check against acceptance criteria:**

For each criterion in `task.acceptanceCriteria`, evaluate:
- **MET** — clear evidence in the diff
- **PARTIAL** — core behavior present but incomplete
- **NOT MET** — no evidence

**Check for code quality issues:**

1. **Silent failures** — error cases that are swallowed, logged but not surfaced, or silently return bad data
2. **Logic errors** — off-by-ones, wrong conditionals, missing null checks in paths that will actually be hit
3. **Test gaps** — changed code paths with no test coverage, edge cases that are obviously missing
4. **Pattern violations** — code that doesn't follow the patterns in `CLAUDE.md` or visible in the rest of the codebase (naming, error handling, file structure)
5. **Scope creep** — changes outside the acceptance criteria that introduce risk

For each finding, record: file, line, category (silent-failure | logic | test-gap | pattern | scope), description, confidence (0-100). Only surface findings with confidence ≥ 80.

**Verdict:**
- **SHIP IT** — all criteria MET or PARTIAL, no high-confidence blocking issues
- **NEEDS FIXES** — blocking issues found (logic errors, silent failures); fix before merging
- **NEEDS WORK** — acceptance criteria NOT MET; gap requires implementation work, not just fixes

### 3d. Fix Blocking Issues (NEEDS FIXES only)

For each blocking finding:
1. Read the full file containing the issue
2. Apply the fix with Edit
3. Verify with a targeted test run if applicable
4. Note the fix in the review comment

If NEEDS WORK: comment on the PR with the specific gap, update task to `blocked` in todos.json, skip to next PR.

### 3e. Commit Fixes and Submit Review

If fixes were applied:
```bash
git -C ~/worktrees/{repo}-{branch-slug} add -A
git -C ~/worktrees/{repo}-{branch-slug} commit -m "fix: address review findings for {id}"
git -C ~/worktrees/{repo}-{branch-slug} push
```

Submit a formal GitHub review — a comment alone doesn't set `reviewDecision` and won't satisfy branch protection:

```bash
# SHIP IT (or after fixing NEEDS FIXES):
gh pr review {pr_number} --repo app-vitals-com/{repo} \
  --approve \
  --body "shipwright-lite:review — SHIP IT.
Criteria: {met_count} met, {partial_count} partial.
{If fixes applied: 'Fixed: {brief list of what was fixed.}'}"

# NEEDS WORK:
gh pr review {pr_number} --repo app-vitals-com/{repo} \
  --request-changes \
  --body "shipwright-lite:review — NEEDS WORK.
{List each NOT MET criterion and what's missing.}"
```

### 3f. Update from Main and Merge

Update the branch before merging:
```bash
gh api -X PUT repos/app-vitals-com/{repo}/pulls/{pr_number}/update-branch
```

If the update triggers CI, wait for it to pass (same polling pattern as 3b, 5 min timeout).

Merge:
```bash
gh pr merge {pr_number} --repo app-vitals-com/{repo} --squash --delete-branch
```

---

## Step 4: Update Queue

For each merged PR, update the task in `state/todos.json`:
- `status: "merged"`
- `mergedAt: "{ISO timestamp}"`

Write todos.json. Check if any `pending` tasks now have all dependencies `merged` — note them in the output so the next execution cron tick picks them up.

---

## Step 5: Update Metrics

For each merged task, update its record in `planning/{session}/metrics.jsonl`. Find the line by `task_id` and add:

```json
{
  "merged_at": "{ISO timestamp}",
  "review": {
    "verdict": "SHIP IT | NEEDS FIXES | NEEDS WORK",
    "findings": {count of ≥80 confidence findings},
    "fixes_applied": {count of fixes made in 3d},
    "ci_fix_attempts": {count from 3b}
  },
  "review_iterations": {total fix rounds},
  "first_time_merge": {true if ci_fix_attempts == 0 and fixes_applied == 0},
  "tokens": {
    "execution": "{existing}",
    "review": { "input": null, "output": null, "cost_usd": null },
    "total_cost_usd": null
  }
}
```

---

## Step 6: Learning Loop

After processing the session, look for patterns worth capturing:

- CI failures that point to a missing check in the dev-task workflow
- Code patterns that should be in `CLAUDE.md`
- Acceptance criteria that were systematically incomplete (planning signal)

If 1-2 genuine actionable learnings found, append to `CLAUDE.md` in the repo:
`- {assumption} → {what happened} → {what to do instead}`

Only add learnings that are specific and actionable. No generic advice.

---

## Done

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEW COMPLETE — {session}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Merged:  {list "#{pr} {id}: {title}"}
Blocked: {list with reason, or "none"}
Learnings: {count}

{If newly unblocked tasks exist:}
Ready for execution:
  {list task IDs}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
