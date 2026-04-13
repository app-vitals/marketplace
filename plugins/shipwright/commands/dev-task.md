---
description: Execute the next ready task from the queue — build feature, simplify, verify, ship PR
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
---

# Dev Task

Pick the next ready task from `state/todos.json`, build the feature, simplify, verify requirements, and ship a PR. Follow all steps in order.

**This command runs autonomously. Do not pause for user input unless a build or test failure cannot be auto-resolved.**

---

## Step 0: Detect Project Toolchain

Auto-detect the project toolchain (run once, reuse throughout). Skip this step until the repo is known (Step 1 sets the repo).

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

Record `task_started_at` (current ISO timestamp) for metrics.

Resolve the PostHog send script (silent — used throughout):

```bash
POSTHOG_SCRIPT=$(find ~/.claude/plugins/cache -name "posthog_send.py" -path "*/shipwright/*" 2>/dev/null | head -1)
```

If `POSTHOG_SCRIPT` is empty, all PostHog calls in this task are silently skipped.

Now detect the project toolchain for `{repo}` (used throughout):

### 0b. Detect Project Toolchain

Auto-detect the project toolchain (run once, reuse throughout):

1. Scan the project root for config files:
   - `package.json` + lockfile → Node.js (detect manager: pnpm/yarn/npm/bun)
   - `Cargo.toml` → Rust
   - `go.mod` → Go
   - `pyproject.toml` / `setup.py` → Python
   - `Gemfile` → Ruby
   - `Makefile` → Generic Make

2. For Node.js: read `package.json` scripts for `validate`, `build`, `test`, `lint`, `typecheck`/`check`

3. Check for monorepo indicators

4. Store the detected commands:
   - **validate**: Full validation command (e.g., `pnpm validate`, `cargo clippy && cargo test`, `make check`)
   - **test**: Test command (e.g., `pnpm test`, `cargo test`, `go test ./...`, `pytest`)
   - **lint**: Lint command (e.g., `pnpm lint`, `cargo clippy`, `golangci-lint run`, `ruff check`)
   - **typecheck**: Type check command if applicable (e.g., `pnpm -r check`, `tsc --noEmit`)
   - **build**: Build command (e.g., `pnpm build`, `cargo build`, `go build ./...`)

Refer to `references/toolchain-patterns.md` for the full detection lookup table.


## Step 2: Mark In-Progress

### Orphan Check (prior session recovery)

If the task's current status is already `in_progress`:

1. Check for an orphaned branch: `git ls-remote --heads origin {branch}`
2. Check for an orphaned PR: `gh pr list --head {branch} --state open --json number,title`
3. If an orphaned PR exists, close it: `gh pr close {number} --comment "Shipwright cleanup — resuming task from prior session"`
4. If a remote branch exists, delete it: `git push origin --delete {branch}`
5. Print:
   ```
   ↩ Recovered orphaned session for {id}
   {If PR closed: "Closed PR #{number}"}
   {If branch deleted: "Deleted branch {branch}"}
   Starting fresh.
   ```

### Mark In-Progress

Update `state/todos.json`:
- Set `status: "in_progress"`
- Set `startedAt: "{ISO timestamp}"`

Write the updated todos.json.

If `POSTHOG_SCRIPT` is set, fire `shipwright_task_started`:

```bash
python3 "$POSTHOG_SCRIPT" shipwright_task_started \
  --project {repo} --task {id} --ts "{task_started_at}" \
  title="{title}" layer="{layer}" estimated_h={hours} session="{session}"
```

## Step 3: Build Feature-Dev Prompt

Construct the implementation prompt from the task fields in `state/todos.json`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPLEMENTATION BRIEF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{title}

Description:
{description}

Acceptance Criteria:
{acceptanceCriteria items}

Layer: {layer}

AUTONOMOUS MODE: Proceed directly from discovery to
architecture to implementation. Auto-fix all quality issues.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 4: Set Up Worktree

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

Print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
READY TO START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch: {branch}
Task:   {id} — {title}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```


## Step 5: Dispatch Implementation Subagent

**TDD REQUIRED**: The subagent below must follow red-green-refactor. No production code is written before a failing test exists. Expected Tests in the brief are the starting point for the RED phase.

To preserve context quality for the post-implementation steps (Simplify, Spec Check, Requirements Verification), all implementation work is dispatched to a fresh subagent. Construct the subagent prompt from context already in session, then hand it off.

### 5a. Prepare Subagent Context

Before dispatching:
1. Read `CLAUDE.md` at project root (pass full contents to subagent)
2. Glob the worktree to identify the files most likely relevant to the task

### 5b. Dispatch Implementation Subagent

Dispatch a `general-purpose` subagent with this prompt (fill in all `{placeholders}` from context already collected):

```
You are implementing a feature task. Follow TDD (red-green-refactor) strictly — write failing tests BEFORE writing implementation code.

Working directory: ~/worktrees/{repo}-{branch-slug}
Do NOT create a new branch. Commit your work with conventional commit messages.

━━━━ IMPLEMENTATION BRIEF ━━━━
{Full implementation brief from Step 3}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT CONVENTIONS (from CLAUDE.md):
{CLAUDE.md contents}

TOOLCHAIN:
  Test command:     {test command from Step 0}
  Validate command: {validate command from Step 0}
  Typecheck:        {typecheck command from Step 0, or "none"}

INSTRUCTIONS — follow in order:

[A] Discovery
  - Glob the project structure and read the files most relevant to this task
  - Spawn the shipwright:researcher agent via the Agent tool, passing: task ID "{id}", title "{title}", description "{description}", layer "{layer}", and the project docs directory path
  - Use research output to inform architecture and patterns
  - Extract the ### Metrics block from research output — include it verbatim in your STATUS report at the end

[B] Architecture — use the simplest approach that fits existing patterns:
  Plan which files to create/modify and what patterns to follow.

[C] Testing — RED (Write failing tests first)
  {If Expected Tests are specified in the brief:
  "Start with these Expected Tests — write them exactly as specified, then run them to confirm they fail."}
  1. Detect the test framework from existing test files
  2. Follow test patterns found in nearby test files
  3. Write tests covering each acceptance criterion
  4. Run: {test command}
     → Tests MUST FAIL at this point. A test passing immediately means it is testing existing behavior or is incorrectly written — fix it.

[D] Implementation — GREEN (Make tests pass)
  1. Write minimal code to make the failing tests pass
  2. Follow CLAUDE.md conventions and existing codebase patterns
  3. Handle: {edge cases from planning doc}
  4. Apply: {error handling strategy from planning doc}
  5. Respect scope: {scope boundaries from planning doc}
  6. Run: {test command} — ALL tests must pass before continuing

[E] Refactor — Keep tests green
  1. Clean up: remove duplication, improve naming, simplify complexity
  2. No new behavior during refactor
  3. Rerun tests after each change — must stay green

[F] Validation
  1. Run: {validate command}
  2. Fix any errors
  3. {If Test Type specified: "Ensure a {test-type} test exists and passes"}

Commit all changes: use conventional commit format (e.g., "feat: {task title}")

━━━━ REPORT BACK ━━━━
At the end, output a block in this exact format:

STATUS: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED

RESEARCH_METRICS:
{paste the ### Metrics block verbatim from the research agent output}

CONCERNS: {if DONE_WITH_CONCERNS: describe them here}
BLOCKER:  {if BLOCKED: describe what is blocking you}
━━━━━━━━━━━━━━━━━━━━
```

### 7c. Handle Subagent Status

Parse the subagent's STATUS report:

- **DONE**: Store the RESEARCH_METRICS block for Step 10b. Proceed to Step 6.
- **DONE_WITH_CONCERNS**: Read the concerns. If they indicate correctness or scope gaps, address them before Step 6. If they are observations only (e.g., "this file is growing large"), note them and proceed.
- **NEEDS_CONTEXT**: Provide the missing context and re-dispatch with the same prompt augmented with the answer.
- **BLOCKED**: Assess the blocker. If it is a context problem, re-dispatch with more context. If the task is too large, break it into smaller sub-tasks. If the plan is wrong, escalate to the user.

Extract from RESEARCH_METRICS for Step 10b: `docs_scanned`, `docs_selected`, `docs_loaded` (as JSON array), `web_search` (boolean), `web_queries` (integer).

> **CRITICAL — DO NOT SKIP STEPS 8–12**
> After the implementation subagent completes (Step 7), you MUST continue through ALL remaining steps: Simplify (8), Spec Compliance Check (8.5), Requirements Verification (9), Pre-Ship Checks (10), Push & PR (11), CI Gate (11b), Handoff (12). Do NOT stop or ask to run a separate workflow.

## Step 6: Simplify

After implementation completes, run a simplification pass:

1. Review `git diff main...HEAD` to see all changes on this branch
2. Look for and fix:
   - **DRY violations**: Duplicated code that should be extracted
   - **Dead code**: Unused imports, variables, or functions introduced
   - **Naming**: Unclear or inconsistent names
   - **Complexity**: Over-engineered solutions that can be simplified
   - **Consistency**: Patterns that don't match the rest of the codebase
3. Apply fixes using the Edit tool
4. **Tally simplify fixes**: After applying fixes, count how many were applied in each category:
   - `simplify_dry`: count of DRY violation fixes
   - `simplify_dead_code`: count of dead code removals
   - `simplify_naming`: count of naming improvements
   - `simplify_complexity`: count of complexity reductions
   - `simplify_consistency`: count of consistency fixes
   - `simplify_total`: sum of above
   Store these counts for use in Step 10b metrics. If no fixes were needed, all counts are 0.
5. Run the detected typecheck command (if applicable) to verify types still pass after cleanup

If `POSTHOG_SCRIPT` is set, fire `shipwright_simplify_complete`:

```bash
python3 "$POSTHOG_SCRIPT" shipwright_simplify_complete \
  --project {project} --task {task_id} \
  total={simplify_total} dry={simplify_dry} dead_code={simplify_dead_code} \
  naming={simplify_naming} complexity_fixes={simplify_complexity} consistency={simplify_consistency}
```

---

## Step 6.5: Spec Compliance Check

Before creating a PR, launch an independent spec compliance subagent to verify the implementation actually satisfies the acceptance criteria. This is an independent review — the subagent has no knowledge of implementation decisions made in Step 7, only the spec and the diff.

**Dispatch a `general-purpose` subagent** with this prompt:

```
You are performing a spec compliance review. Review the implementation diff against the acceptance criteria and report whether each criterion is MET, PARTIAL, or NOT MET.

Task: {task-id} — {task title}

Feature Overview:
{parent feature Overview section from Step 2}

Acceptance Criteria:
{each acceptance criterion from Step 2, as a list}

Implementation Diff:
{output of: git diff main...HEAD}

Implementation Decisions (context):
- Edge Cases: {edge cases from planning doc}
- Error Handling: {error handling from planning doc}
- Scope Boundaries: {scope boundaries from planning doc}

For each criterion, evaluate the diff and assign:
  MET     — clear evidence in the diff that this criterion is satisfied
  PARTIAL — partially implemented but incomplete
  NOT MET — no evidence of implementation in the diff

Respond with:
| Criterion | Status | Evidence |
|-----------|--------|----------|
{one row per criterion}

At the end, list any NOT MET criteria explicitly under "## Gaps Found".
If all criteria are MET, write "## All Criteria Met".
```

**Handle the result:**

- **All MET**: Proceed to Step 8.
- **Any NOT MET**:
  1. Fix the gaps (re-enter the implementation subagent from Step 5b with specific fix instructions)
  2. Run `{validate command}` to confirm the fix doesn't break existing tests
  3. Re-dispatch the spec compliance subagent to confirm all criteria are now MET
  4. Repeat until all are MET
- **PARTIAL**: Treat the same as NOT MET — auto-fix before proceeding.
---

## Step 7: Requirements Verification

Using the acceptance criteria extracted in Step 2, run `git diff main...HEAD` to see all changes on this branch.

For each acceptance criterion, evaluate against the diff:

| Status | Meaning |
|--------|---------|
| MET | Clear evidence in the diff that this criterion is satisfied |
| PARTIAL | Some progress but incomplete implementation |
| NOT MET | No evidence of implementation |
| UNVERIFIABLE | Cannot determine from code alone (e.g., "feels snappy") |

Present results in a table:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REQUIREMENTS VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
{one row per criterion}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Tally requirement statuses**: Count the verdicts from the table above:
- `req_met`: count of MET criteria
- `req_partial`: count of PARTIAL criteria
- `req_not_met`: count of NOT_MET criteria
- `req_unverifiable`: count of UNVERIFIABLE criteria
- `req_total`: total criteria evaluated
Store these counts for use in Step 10b metrics.

If any criterion is PARTIAL or NOT MET after the fix loop, mark the task `blocked` in todos.json with a note. If `POSTHOG_SCRIPT` is set, fire `shipwright_task_blocked` with `reason="requirements_not_met"`. Stop.

## Step 8: Pre-Ship Checks

Run the detected validation commands from Step 0. For multi-ecosystem projects, run all applicable commands.

Examples based on detected toolchain:
- Node.js: `{manager} validate` (or `{manager} lint && {manager} test && {manager} build`)
- Rust: `cargo clippy --workspace -- -D warnings && cargo test --workspace`
- Go: `go vet ./... && go test ./...`
- Python: `pytest` (or `poetry run pytest`, `uv run pytest`)
- Ruby: `bundle exec rspec` (or `bundle exec rake test`)

### Coverage Gate

Run coverage checks for each package that has changed files on this branch:

1. **Detect changed packages**: From the diff, identify which packages/modules were modified
2. **Run tests with coverage**: Use the detected test command with coverage enabled (e.g., `--coverage` flag for most frameworks)
3. **Report**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COVERAGE REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Package | Type | Lines | Branches | Target | Status |
|---------|------|-------|----------|--------|--------|
{one row per package+type}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Coverage threshold**: Use the threshold from the planning doc's Project Metadata (default: 90%).

**Capture coverage delta**: Record coverage measurements for metrics:
- `coverage_before`: If the test framework reports a baseline (e.g., from a prior run on main, or a coverage badge), use it. Otherwise, set to `null`.
- `coverage_after`: The line coverage percentage reported for changed packages (use the lowest package coverage if multiple).
- `coverage_delta`: `coverage_after - coverage_before` if both are available, otherwise `null`.
Store these values for use in Step 10b metrics. Coverage measurement is best-effort — if the toolchain doesn't support baseline comparison, only `coverage_after` is populated.

If any coverage is below the threshold, log the warning and auto-proceed — do not stop.

Do NOT silently skip this check. Coverage must be measured and reported even if the user chooses to continue below threshold.

### Build & Lint

**Pause point (conditional):** Only if a check fails and cannot be auto-fixed, stop and let the user resolve.

## Step 9: Push & PR

1. Run `git status` and `git diff --stat`
2. Push to remote (use `-u origin {branch}` if no upstream exists)

Create a PR:
1. Draft a PR title from the task title (under 70 characters, conventional commit format)
2. Draft a PR body:

```
## Summary
- {1-3 bullet points summarizing the changes}

## Acceptance Criteria
{Copy the acceptance criteria table from Step 7, or list criteria from the task}

## Test Plan
- {Key test scenarios verified}
- [x] Pre-commit checks passing

Generated with [Claude Code](https://claude.com/claude-code)
```

3. **Write the PR body to a temp file** to avoid heredoc syntax in the command string (heredocs break permission glob matching and cause repeated approval prompts during `/dev-loop`):
   ```
   Write the PR body content to /tmp/shipwright-pr-body-{task-id}.txt
   gh pr create --title "{title}" --body-file /tmp/shipwright-pr-body-{task-id}.txt
   rm /tmp/shipwright-pr-body-{task-id}.txt
   ```
   The temp file path MUST include the task ID to avoid collisions — `/tmp` is shared across all worktrees.
   Do NOT use `--body "$(cat <<'EOF'..."` — this produces a different command string each time and cannot be matched by `Bash(gh pr create:*)`.
4. Display the PR URL. Store it as `{pr-url}` for use in Step 9b.5.

5. If `POSTHOG_SCRIPT` is set, fire `shipwright_pr_created`:

```bash
python3 "$POSTHOG_SCRIPT" shipwright_pr_created \
  --project {project} --task {task_id} \
  pr={pr_number} files_changed={files_changed}
```

### PR Failure Cleanup

If PR creation fails, OR if CI checks fail after max retries (Step 9b.5), after 2 retries:

1. Check for orphaned PRs on this branch:
   `gh pr list --head {branch} --state open --json number,title`

2. If orphaned PRs found, close each:
   `gh pr close {pr-number} --comment "Shipwright cleanup — PR creation/merge failed"`

3. Delete the remote branch (if it exists):
   `git push origin --delete {branch}`

4. Return to main and clean up local branch:
   `git checkout main && git branch -D {branch}`

5. Reset the task status in the planning doc from `[🔨]` back to `[ ]`

6. Commit: `chore: reset {task-id} after PR failure`

7. Print cleanup summary:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   CLEANUP: {task-id}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Closed PR(s): {list or "none"}
   Deleted branch: {branch}
   Task status: reset to [ ]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

This cleanup ensures no orphaned PRs or branches are left behind. Mark the task `blocked` in todos.json with failure details. If `POSTHOG_SCRIPT` is set, fire `shipwright_task_blocked` with `reason="pr_creation_failed"`. The execution cron will not pick it up until a human intervenes.

## Step 9b: CI Gate

After PR creation, update the branch from main and monitor GitHub Actions CI checks before proceeding.

### 11b.1. Update from Main

Merge the latest main into the PR branch to satisfy branch protection rules:

```
git fetch origin main
git merge origin/main
```

If the merge **succeeds** (no conflicts):

Check whether the merge actually brought in new commits:
```
git diff HEAD @{1} --quiet
```
If no changes (exit code 0 = already up to date), skip the push — CI is already running against the current code. Proceed directly to 11b.2.

If there are changes:
```
git push
```
The push triggers new CI runs against the updated code. Proceed to 11b.2.

If the merge produces **conflicts**: do NOT commit the merge. Instead, abort it (`git merge --abort`) and jump directly to 11b.4 (Fix Loop) with the conflict details as the failure context. The fix subagent will run `git merge origin/main`, resolve the conflicts, commit, and push.

### 11b.2. Wait for Checks

```
gh pr checks {pr-number} --watch
```

Use a **10-minute timeout** for this command (Bash tool `timeout: 600000`). If the command times out, treat it as a failure.

**No CI configured:** If `gh pr checks {pr-number}` returns no checks (empty output), skip the rest of Step 9b and proceed to Step 10. Print:
```
⏭ No CI checks configured — skipping CI gate
```

**All checks pass:** Print the following and proceed to Step 10:
```
✓ CI checks passed
```

If `POSTHOG_SCRIPT` is set, fire `shipwright_ci_result` (pass case):
```bash
python3 "$POSTHOG_SCRIPT" shipwright_ci_result \
  --project {project} --task {task_id} \
  passed_first_try=true fix_attempts=0 'failures=[]'
```

**Any check fails:** Continue to 11b.3.

### 11b.3. Collect Failure Logs

1. Get the failed check names:
   `gh pr checks {pr-number} --json name,status,conclusion --jq '.[] | select(.conclusion == "failure")'`

2. List the failed workflow runs for this branch:
   `gh run list --branch {branch} --status failure --json databaseId,name,conclusion --limit 5`

3. For each failed run, get the logs (truncated to last 200 lines per run to avoid context blowup):
   `gh run view {run-id} --log --failed 2>&1 | tail -200`

Collect all failure output into a single context block for the fix subagent. If `--failed` is not supported by the installed `gh` version, fall back to `gh run view {run-id} --log 2>&1 | tail -200`.

4. **Record failure summary**: Append a one-line description of the CI failure to the `ci_failures[]` array (e.g., `"jest: 2 test suites failed"`, `"eslint: 4 lint errors in src/api/routes.ts"`, `"merge conflict with origin/main"`). Keep each entry under 100 characters. This array is written to metrics in Step 10b.

### 11b.4. Fix Loop

Initialize: `ci_attempt = 0`, `ci_max_retries = 6`, `ci_fix_history = []` (accumulates a one-line summary of what each attempt tried).

While `ci_attempt < ci_max_retries`:

1. Increment `ci_attempt`.

2. Print:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   CI FIX: attempt {ci_attempt}/{ci_max_retries}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

3. **Launch fix subagent** using the Agent tool:

   - **Type**: `general-purpose`
   - **Prompt**:
     ```
     You are fixing CI failures (or merge conflicts) on an open pull request.
     Do NOT create a new PR or branch. Fix the code on the current branch and push.

     Task: {task-id} — {task title}
     Branch: {branch}
     PR: #{pr-number}

     Current failure context:
     {If merge conflict: "Merging origin/main produced conflicts. Run `git merge origin/main`, resolve all conflicts, then commit and push."}
     {If CI failure: collected failure logs from 11b.3}

     {If ci_attempt > 1:}
     Previous fix attempts (do NOT repeat these — try a different approach):
     {ci_fix_history formatted as numbered list}

     PR diff (for context):
     {output of gh pr diff {pr-number}}

     Instructions:
     1. Analyze the failure logs (or conflict markers) to identify the root cause
     2. Read the relevant source files
     3. Fix the failing code, tests, or merge conflicts — if a previous attempt already tried an approach that didn't work, take a different angle
     4. Run the project's local validation commands to confirm the fix
     5. Commit with message: "fix: {brief description}"
     6. Push to the branch: git push
     ```

4. After the subagent completes, **append a one-line summary** of what this attempt tried to `ci_fix_history` (e.g., `"Attempt 1: updated failing snapshot in UserCard.test.tsx"`, `"Attempt 2: fixed type error in api/auth.ts — wrong return type"`).

5. **Loop back to 11b.1** — update from main again (main may have moved while the fix was in progress), then re-wait for CI in 11b.2.

5. **All checks pass:** Break the loop. Print:
   ```
   ✓ CI checks passed (after {ci_attempt} fix attempt(s))
   ```
   If `POSTHOG_SCRIPT` is set, fire `shipwright_ci_result` (pass after fixes):
   ```bash
   python3 "$POSTHOG_SCRIPT" shipwright_ci_result \
     --project {project} --task {task_id} \
     passed_first_try=false fix_attempts={ci_attempt} "failures={ci_failures_json_array}"
   ```
   Proceed to Step 10.

6. **Checks still failing:** Collect new failure logs (repeat 11b.3) and continue the loop.

### 11b.5. Max Retries Exhausted

If `ci_attempt >= ci_max_retries` and checks are still failing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CI GATE FAILED: {task-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{ci_max_retries} fix attempts exhausted.
Failing checks:
  {list of still-failing check names}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**When merge-mode is OFF (standalone):**
Run PR Failure Cleanup (Step 9) and stop. Mark the task `blocked` in todos.json with the failure details. If `POSTHOG_SCRIPT` is set, fire `shipwright_task_blocked` with `reason="ci_max_retries_exhausted"`.

## Step 10: Update Queue & Metrics

### 10a. Update todos.json

Update the task in `state/todos.json`:
- Set `status: "pr_open"`
- Set `pr: {pr_number}`
- Set `prCreatedAt: "{ISO timestamp}"`

Write the updated todos.json.

### 10b. Append Metrics

Append one JSONL line to `planning/{session}/metrics.jsonl` (create the file if it doesn't exist). The `/review` command will enrich this line with review data later (see review.md Step 10b).

```json
{"task":"{id}","title":"{title}","session":"{session}","repo":"{repo}","estimated_h":{hours},"ci_fix_attempts":{ci_attempt},"pr":{pr_number},"files_changed":{files_changed_count},"started_at":"{task_started_at}","ts":"{ISO timestamp}","simplify":{"total":{simplify_total},"dry":{simplify_dry},"dead_code":{simplify_dead_code},"naming":{simplify_naming},"complexity":{simplify_complexity},"consistency":{simplify_consistency}},"requirements":{"met":{req_met},"partial":{req_partial},"not_met":{req_not_met},"total":{req_total}},"ci":{"fix_attempts":{ci_attempt},"failures":{ci_failures_json_array}}}
```

This step is silent. JSONL format — one JSON object per line; append-only.

### 10c. Print Handoff

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DONE: {id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR: #{pr_number} — {pr_url}
Simplify: {simplify_total} fixes
CI:       {Pass | {ci_fix_attempts} fix attempt(s)}
Coverage: {coverage_before}% → {coverage_after}%
Reqs:     {req_met}/{req_total} met
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
