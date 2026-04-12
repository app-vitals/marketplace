---
description: Execute the next ready task from the queue — implement, test, lint, create PR, update queue, capture metrics
allowed-tools: Bash, Read, Glob, Grep, Edit, Write, Agent
---

# Dev Task

Pick the next ready task from `state/todos.json` and execute it end-to-end.

**This command runs autonomously. Do not pause for user input unless a build or test failure cannot be auto-resolved.**

---

## Step 1: Pick Task

Read `state/todos.json`. Find `shipwright` tasks where:
- `status` is `pending`
- All entries in `dependencies` have `status: "merged"` (or `dependencies` is empty)

If multiple tasks are ready, pick the one with the earliest `addedAt`.

If no tasks are ready, print:
```
No ready tasks. Either all tasks are complete, or remaining tasks are waiting on open PRs.
```
and stop.

Print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TASK: {id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{title}
Session: {session} | Repo: {repo}
Layer:   {layer}   | Hours: {hours}
Deps:    {dependencies or "none"}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Record `execution_started_at` (current ISO timestamp) for metrics.

---

## Step 2: Mark In-Progress

Update the task in `state/todos.json`:
- Set `status: "in_progress"`
- Set `startedAt: "{ISO timestamp}"`

Write the updated todos.json.

---

## Step 3: Set Up Worktree

All work happens in a worktree — see workspace `CLAUDE.md` for the convention. Branch slug = branch name with `/` replaced by `-`.

```bash
git -C ~/src/{repo} pull
git -C ~/src/{repo} worktree add ~/worktrees/{repo}-{branch-slug} origin/main -b {branch}
```

If the worktree already exists (interrupted prior run):
```bash
git -C ~/src/{repo} worktree remove ~/worktrees/{repo}-{branch-slug} --force
git -C ~/src/{repo} worktree add ~/worktrees/{repo}-{branch-slug} origin/main -b {branch}
```

All subsequent file operations and commands run from `~/worktrees/{repo}-{branch-slug}/`.

---

## Step 4: Load Context

1. Read `CLAUDE.md` in the worktree
2. Detect the project toolchain:
   - `package.json` + lockfile → Node.js (detect manager: pnpm/yarn/npm/bun; read scripts for `validate`, `build`, `test`, `lint`, `typecheck`)
   - `Cargo.toml` → Rust
   - `go.mod` → Go
   - `pyproject.toml` / `setup.py` → Python
3. Read the files listed in the task's `description` that are relevant to the implementation
4. Read nearby test files to understand the testing patterns in use

Do not over-read. Load what's needed to understand the existing patterns and where to make changes.

---

## Step 5: Implement

Build the feature. Follow the acceptance criteria from the task. Follow the patterns in `CLAUDE.md` and the existing codebase.

### Code
- Follow existing patterns — naming, file structure, error handling
- Implement only what's in scope. Do not add features not in the acceptance criteria.
- Do not add comments or docstrings to code you didn't change

### Tests
- Unit tests for new logic
- Integration tests if the feature crosses service boundaries
- Follow the test patterns already in the codebase
- Tests must pass before continuing

### Docs
- If the task changes a public API, CLI interface, or user-facing behavior, update the relevant docs
- If `README.md` or `CLAUDE.md` has a section that describes what you changed, update it

---

## Step 6: Simplify

Review `git diff main...HEAD` in the worktree. Look for and fix:

- Duplicated code that should be extracted (DRY)
- Unused imports or variables introduced by this change
- Names that are unclear or inconsistent with the codebase
- Logic that's more complex than it needs to be

Apply fixes with Edit. Run typecheck if applicable.

**Tally simplify fixes** for metrics (count each category separately):
- `simplify_dry` — DRY violations extracted
- `simplify_dead_code` — unused imports/vars removed
- `simplify_naming` — names clarified
- `simplify_complexity` — logic simplified
- `simplify_total` — sum of above

Store these counts for Step 11.

---

## Step 7: Verify Acceptance Criteria

For each acceptance criterion in the task, evaluate against the diff:

| Status | Meaning |
|---|---|
| MET | Clear evidence in the diff |
| PARTIAL | Some progress but incomplete |
| NOT MET | No evidence |

Print the results. If any criterion is NOT MET, implement what's missing before continuing.

**Tally requirement statuses** for metrics: `req_met`, `req_partial`, `req_not_met`, `req_total`. Store for Step 11.

---

## Step 8: Pre-Ship Checks

Run the project's validation commands based on detected toolchain:
- Node.js: `bun validate` or `bun lint && bun test && bun build`
- Rust: `cargo clippy --workspace -- -D warnings && cargo test --workspace`
- Go: `go vet ./... && go test ./...`
- Python: `ruff check . && pytest`

### CI Fix Loop

If checks fail:
1. Read the error output carefully
2. Apply a targeted fix
3. Re-run checks
4. Repeat up to 3 times

If checks still fail after 3 attempts, mark the task `blocked` in todos.json with a note explaining the failure, and stop.

---

## Step 9: Push & Create PR

```bash
git -C ~/worktrees/{repo}-{branch-slug} add -A
git -C ~/worktrees/{repo}-{branch-slug} commit -m "feat: {task title}"
git -C ~/worktrees/{repo}-{branch-slug} push -u origin {branch}
```

Write the PR body to a temp file to avoid permission prompt issues:

```bash
# Write body to /tmp/sw-pr-{task-id}.txt first, then:
gh pr create \
  --repo {org}/{repo} \
  --title "feat({id}): {task title}" \
  --body-file /tmp/sw-pr-{task-id}.txt
rm /tmp/sw-pr-{task-id}.txt
```

PR body:
```
## Summary
{2-3 bullets summarizing the changes}

## Acceptance Criteria
{task acceptance criteria as a checklist}

## Test Plan
- {key scenarios verified}
- [x] Lint and tests passing

Session: {session}
Task: {id}
```

Record `pr_created_at` and `pr_number` for metrics.

---

## Step 10: Update Queue

Update the task in `state/todos.json`:
- Set `status: "pr_open"`
- Set `pr: {pr_number}`
- Set `prCreatedAt: "{ISO timestamp}"`

Write the updated todos.json.

---

## Step 11: Write Metrics

Append one line to `planning/{session}/metrics.jsonl` (create file if it doesn't exist):

```json
{
  "task_id": "{id}",
  "session": "{session}",
  "repo": "{repo}",
  "queued_at": "{task.addedAt}",
  "execution_started_at": "{recorded in Step 1}",
  "pr_created_at": "{recorded in Step 9}",
  "merged_at": null,
  "ci_attempts": {count from Step 8 fix loop},
  "simplify": {
    "dry": {simplify_dry},
    "dead_code": {simplify_dead_code},
    "naming": {simplify_naming},
    "complexity": {simplify_complexity},
    "total": {simplify_total}
  },
  "requirements": {
    "met": {req_met},
    "partial": {req_partial},
    "not_met": {req_not_met},
    "total": {req_total}
  },
  "review_iterations": 0,
  "first_time_merge": null,
  "learnings_captured": 0,
  "tokens": {
    "execution": { "input": null, "output": null, "cost_usd": null },
    "review": null,
    "total_cost_usd": null
  }
}
```

Token fields are populated from the headless run's usage output if available. Leave null if not available.

---

## Step 12: Learning Loop

Review the changes made during this task. Look for:

- A pattern that exists in the codebase that you didn't know about upfront (would have saved exploration time)
- An error or edge case that wasn't in the acceptance criteria but should have been
- A project convention that isn't documented in `CLAUDE.md`

If you find 1-2 genuine learnings that would help future executions of similar tasks, append them to `CLAUDE.md` in the repo under a `## Learnings` section (or add to an existing relevant section).

Format: `- {what you assumed} → {what actually happened} → {what to do instead}`

Only add learnings that are specific and actionable. Do not add generic programming advice.

If no genuine learnings found, skip this step.

---

## Done

Print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DONE: {id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR: #{pr_number} — {pr_url}
Checks: {ci_attempts} attempt(s)
Learnings: {count captured}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
