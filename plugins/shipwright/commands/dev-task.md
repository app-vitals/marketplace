---
description: End-to-end feature development — read task from planning doc, build feature, simplify, verify, ship PR
arguments:
  - name: task-id
    description: Task ID from the planning doc (e.g., MR-2.1). Append --merge to auto-create PR, review, and merge without pausing.
    required: true
allowed-tools: Bash(git:*), Bash(gh:*), Bash(bun:*), Bash(npm:*), Bash(pnpm:*), Bash(yarn:*), Bash(cargo:*), Bash(go:*), Bash(python:*), Bash(python3:*), Bash(npx:*), Bash(node:*), Bash(make:*), Bash(wc:*), Bash(find:*), Bash(grep:*), Edit(planning/**), Write(planning/**)
---

# Dev Task: $ARGUMENTS

Read the task from the planning doc, build the feature, simplify, verify requirements, and ship a PR. Follow all steps in order.

---

## Argument Parsing

Parse `$ARGUMENTS` to extract:
- **task-id**: Everything before `--merge` (trimmed), e.g., `MR-2.1`
- **merge-mode**: `true` if `$ARGUMENTS` contains `--merge`, `false` otherwise

When **merge-mode is ON**:
- All pause points become auto-proceed (skip user prompts)
- After PR creation, run review and merge automatically
- Used by `/dev-loop` for fully autonomous operation

---

## Step 0: Setup

### 0a. Check Recommended Plugins

Check if the following plugins are installed by looking for their skills in the available skills list:

| Plugin | Check For | Used In |
|--------|-----------|---------|
| `learning-loop` | `/learn` skill | Step 12f (Learning Capture, merge-mode only) |
| `frontend-design` | `frontend-design` skill | Step 7a (Discovery, for Design Skill-tagged tasks) |
| `research` | `research` skill | Step 7a (Discovery — loads task-relevant project docs for implementation context) |

If any are missing, present:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDED PLUGINS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The following plugins enhance this workflow:

MISSING:
  ✗ learning-loop — captures review learnings
    Install: /plugin install learning-loop@app-vitals/marketplace
  ✗ frontend-design — high-quality UI for design-tagged tasks
    Install: /plugin install frontend-design
  ✗ research — loads task-relevant project docs automatically
    Install: /plugin install research@app-vitals/marketplace

INSTALLED:
  ✓ {installed plugins}

Continue without them? (Yes / Install first)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If all plugins are installed, skip the prompt and continue. If plugins are missing and the user chooses to continue, note which are unavailable so later steps can skip those features. **In merge-mode, skip this prompt — log missing plugins and auto-proceed.**

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

## Step 1: Find Planning Doc

Search for the parsed task ID (from Argument Parsing above).

1. Glob for `planning/**/*_Task_Breakdown.md`
2. Grep each file for the task ID
3. If not found, also try case-insensitive search and check if the ID format needs adjusting (e.g., `mr-2.1` vs `MR-2.1`)
4. If still not found, tell the user: "Task {task-id} not found in any planning doc under planning/. Check the task ID and try again." and stop.

## Step 2: Extract Task

Parse the task block from the planning doc. Extract:

- **Task title** and **Description**
- **Parent feature Overview** (the `### Overview` section of the feature this task belongs to)
- **Context** field (from the task table)
- **Branch** field (from the task table)
- **Acceptance Criteria** (the `- [ ]` items under the task)
- **Technical Details** (Location + implementation notes)
- **Dependencies** (comma-separated task IDs or None)
- **Design Skill** (if present in the task table)
- **Test Type** (if present — indicates this is a test task)
- **Architecture** (`minimal` / `clean` / `pragmatic`)
- **Implementation Decisions** (Edge Cases, Error Handling, Scope Boundaries, Backward Compatibility, Performance)
- **Layer**
- **Hours** estimate

Present a brief summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TASK: $ARGUMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{Task title}
Branch: {branch}
Layer:  {layer} | Hours: {hours}
Deps:   {dependencies}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 3: Dependency Pre-flight

For each dependency listed:

1. Search the planning doc Appendix for the dependency task ID
2. Check its Status column value

If any dependency does not have `[x]` status:

```
⚠ DEPENDENCY WARNING
- {DEP-ID}: {task title} — status: {status}
```

**Pause point:** Ask the user: "Some dependencies are not complete. Continue anyway, or stop and work on dependencies first?" **{In merge-mode, skip this pause — warn and auto-proceed.}**

If all dependencies are `[x]` or there are no dependencies, continue without pausing.

## Step 4: Mark In-Progress

### Orphan Check (prior session recovery)

If the task's current status is already `[🔨]` (in-progress from a prior interrupted session):

1. Check for an orphaned branch: `git branch --list {branch}` and `git ls-remote --heads origin {branch}`
2. Check for an orphaned PR: `gh pr list --head {branch} --state open --json number,title`
3. If an orphaned PR exists, close it: `gh pr close {number} --comment "Shipwright cleanup — resuming task from prior session"`
4. If a remote branch exists, delete it: `git push origin --delete {branch}`
5. If a local branch exists, delete it: `git branch -D {branch}`
6. Print:
   ```
   ↩ Recovered orphaned session for {task-id}
   {If PR closed: "Closed PR #{number}"}
   {If branch deleted: "Deleted branch {branch}"}
   Starting fresh.
   ```

### Mark In-Progress

Update the planning doc:

1. In the **Appendix: Complete Task List** table, change the Status column for the task from `[ ]` (or `[🔨]`) to `[🔨]`
2. In the **{Feature Name} Summary** table, change the same task's status to `[🔨]`
3. Commit: `chore: mark {task-id} in-progress`

## Step 5: Build Feature-Dev Prompt

Construct the implementation prompt from the extracted fields:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPLEMENTATION BRIEF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Task title}

Context:
{Context field from the task table}

Feature Overview:
{Parent feature Overview section}

Description:
{Description field}

Technical Details:
{Technical Details section}

Acceptance Criteria:
{Acceptance Criteria items}

Layer: {layer}
Architecture: {architecture approach}
{If Test Type present: "Test Type: {test-type}"}
{If Design Skill present: "Design Skill: {design-skill}"}

Implementation Decisions (PRE-ANSWERED — do not re-ask):
- Edge Cases: {edge cases from planning doc}
- Error Handling: {error handling strategy from planning doc}
- Scope Boundaries: {scope boundaries from planning doc}
- Backward Compatibility: {backward compat from planning doc}
- Performance: {performance constraints from planning doc}

AUTONOMOUS MODE: All clarifying questions have been pre-answered
above during planning. Proceed directly from discovery to
architecture to implementation. For architecture, use the
"{architecture}" approach. For quality review issues, auto-fix
all fixable issues.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 6: Set Up Repo & Branch

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
READY TO START
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch: {branch from task}
Task:   {task-id} — {task title}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

1. `git checkout main && git pull`
2. `git checkout -b {branch-from-task}`

If any git command fails, report the error and stop.

## Step 7: Start Feature Development

Execute the implementation using the prompt from Step 5. This is a self-contained inline workflow — no external skills required.

### 7a. Discovery
1. Read `CLAUDE.md` to understand project conventions
2. Read all files listed in the Technical Details section
3. **Load project docs** (if `research` plugin is available): Spawn the research agent via the Agent tool with the task ID, title, description, and layer. Use the agent's output to inform architecture decisions and implementation patterns in steps 7b and 7c. If the research plugin is not available, skip this step silently.
4. If Design Skill is specified, check if that skill is available and invoke it if so
5. Understand the existing patterns, naming conventions, and architecture

### 7b. Architecture
Apply the task's architecture approach:
- **minimal**: Smallest change possible, maximum reuse
- **clean**: Proper abstractions, well-separated concerns
- **pragmatic**: Balance of speed and quality

Plan the implementation: which files to create/modify, what patterns to follow, what to reuse.

### 7c. Implementation
1. Write the code following project conventions from CLAUDE.md
2. Follow existing patterns in the codebase
3. Handle all edge cases from Implementation Decisions
4. Apply the error handling strategy from Implementation Decisions
5. Respect scope boundaries — don't implement what's explicitly excluded

### 7d. Testing
1. Detect the project's test framework from Step 0 toolchain detection
2. Follow existing test patterns in the codebase (find nearby test files for examples)
3. Write tests appropriate to the task's Test Type (if specified) or based on what's needed
4. Run the detected test command to verify tests pass

### 7e. Validation
1. Run the detected validate/build/test commands from Step 0
2. Fix any errors that arise
3. If the task specifies a Test Type, ensure that specific type of test exists and passes

> **CRITICAL — DO NOT SKIP STEPS 8–12**
> After implementation completes, you MUST continue through ALL remaining steps. Do NOT stop or ask to run a separate workflow.

## Step 8: Simplify

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
   Store these counts for use in Step 12e.2 metrics. If no fixes were needed, all counts are 0.
5. Run the detected typecheck command (if applicable) to verify types still pass after cleanup

---

## Step 9: Requirements Verification

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
Store these counts for use in Step 12e.2 metrics.

**Pause point:** If any criterion is PARTIAL or NOT MET, ask the user: "Some criteria have gaps. Continue shipping, or go back and address them?" **{In merge-mode, only pause if NOT MET criteria exist. PARTIAL is acceptable — auto-proceed.}**

## Step 10: Pre-Ship Checks

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
Store these values for use in Step 12e.2 metrics. Coverage measurement is best-effort — if the toolchain doesn't support baseline comparison, only `coverage_after` is populated.

**Pause point:** If any coverage is below the threshold, warn the user:
"Coverage for {package} is at {X}% (target: >{threshold}%). Add tests to bring it up, or continue anyway?" **{In merge-mode, skip this pause — log the warning and auto-proceed.}**

Do NOT silently skip this check. Coverage must be measured and reported even if the user chooses to continue below threshold.

### Build & Lint

**Pause point (conditional):** Only if a check fails and cannot be auto-fixed, stop and let the user resolve.

## Step 11: Push & PR

1. Run `git status` and `git diff --stat`
2. Push to remote (use `-u origin {branch}` if no upstream exists)

**Pause point:** Ask the user: "All checks pass. Create PR? (Yes / Push only)" **{In merge-mode, skip this pause — auto-create PR.}**

If creating a PR:
1. Draft a PR title from the task title (under 70 characters, conventional commit format)
2. Draft a PR body:

```
## Summary
- {1-3 bullet points summarizing the changes}

## Acceptance Criteria
{Copy the acceptance criteria table from Step 9, or list criteria from the task}

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
   The temp file path MUST include the task ID to avoid race conditions when `/dev-loop` runs multiple subagents in parallel — `/tmp` is shared across all worktrees.
   Do NOT use `--body "$(cat <<'EOF'..."` — this produces a different command string each time and cannot be matched by `Bash(gh pr create:*)`.
4. Display the PR URL. Store it as `{pr-url}` for use in Step 11b.5.

### PR Failure Cleanup

If PR creation fails, OR if CI checks fail after max retries (in merge-mode, Step 11b.5), OR if `gh pr merge` fails later (in merge-mode Step 12g), after 2 retries:

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

This cleanup ensures no orphaned PRs or branches are left behind. In merge-mode, the dev-loop's Phase 3 failure recovery will handle re-queuing the task.

## Step 11b: CI Gate

After PR creation, update the branch from main and monitor GitHub Actions CI checks before proceeding. This applies in both standalone and merge-mode.

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

**No CI configured:** If `gh pr checks {pr-number}` returns no checks (empty output), skip the rest of Step 11b and proceed to Step 12. Print:
```
⏭ No CI checks configured — skipping CI gate
```

**All checks pass:** Print the following and proceed to Step 12:
```
✓ CI checks passed
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

4. **Record failure summary**: Append a one-line description of the CI failure to the `ci_failures[]` array (e.g., `"jest: 2 test suites failed"`, `"eslint: 4 lint errors in src/api/routes.ts"`, `"merge conflict with origin/main"`). Keep each entry under 100 characters. This array is written to metrics in Step 12e.2.

### 11b.4. Fix Loop

Initialize: `ci_attempt = 0`, `ci_max_retries = 3`.

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

     Failure context:
     {If merge conflict: "Merging origin/main produced conflicts. Run `git merge origin/main`, resolve all conflicts, then commit and push."}
     {If CI failure: collected failure logs from 11b.3}

     PR diff (for context):
     {output of gh pr diff {pr-number}}

     Instructions:
     1. Analyze the failure logs (or conflict markers) to identify the root cause
     2. Read the relevant source files
     3. Fix the failing code, tests, or merge conflicts
     4. Run the project's local validation commands to confirm the fix
     5. Commit with message: "fix: {brief description}"
     6. Push to the branch: git push
     ```

4. After the subagent completes, **loop back to 11b.1** — update from main again (main may have moved while the fix was in progress), then re-wait for CI in 11b.2.

5. **All checks pass:** Break the loop. Print:
   ```
   ✓ CI checks passed (after {ci_attempt} fix attempt(s))
   ```
   Proceed to Step 12.

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
**Pause point:** "CI checks are still failing after {ci_max_retries} fix attempts. The PR is open at {pr-url}. Would you like to: (1) Try fixing manually, (2) Close the PR and clean up?"

If the user chooses (2), run PR Failure Cleanup (Step 11).

**When merge-mode is ON:**
Print:
```
⚠️ CI gate exhausted — task {task-id} reset for retry
```
Trigger PR Failure Cleanup (Step 11) and stop — do NOT proceed to Step 12. The dev-loop's Phase 3a-retry failure recovery will handle re-queuing the task.

## Step 12: Handoff / Review & Merge

### When merge-mode is OFF (standalone)

#### 12a-standalone. Append Metrics

Append one JSONL line to `planning/{folder-name}/metrics.jsonl` (create the file if it doesn't exist). See Step 12e.2 for the full field specification and `references/metrics-schema.md` for the schema.

In standalone mode, **omit the `review` field** — Steps 12b-d don't run. The `/review` command will enrich this line with review data later (see review.md Step 10b).

All other fields are populated from data already collected: `simplify.*` (Step 8), `requirements.*` (Step 9), `coverage.*` (Step 10), `ci.*` (Step 11b).

#### 12b-standalone. Print Handoff

Print the handoff block with a quality summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHIP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branch: {branch-name}
Commit: {short-sha} {commit-message}
{PR: #{pr-number} {pr-url}  OR  PR: skipped}

QUALITY
-------
Simplify:     {simplify_total} fixes {if > 0: ({category}: {count}, ...)}
CI:           {Pass | {ci_fix_attempts} fix attempt(s)}
Coverage:     {coverage_before}% → {coverage_after}% ({+/-}{coverage_delta}%)
Requirements: {req_met}/{req_total} met{if req_partial > 0: , {req_partial} partial}

NEXT STEPS
----------
1. /clear
2. /review

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### When merge-mode is ON — Review & Merge

{Skip the handoff block above. Instead, run review and merge automatically.}

Run an inline review with these autonomous-mode modifications:

#### 12a. Gather Review Context
1. Get the PR diff: `gh pr diff {pr-number}`
2. Acceptance criteria are already known from Step 2

#### 12b. Launch Review Agents

Launch review agents in parallel using the Agent tool:

**Agent 1: Code Review** (always run)
- **Type**: `feature-dev:code-reviewer`
- **Prompt**: "Review this PR diff for bugs, logic errors, code quality, and CLAUDE.md compliance. Apply confidence scoring — only report findings ≥80 confidence. Here is the diff: {diff}. Here are the CLAUDE.md contents: {CLAUDE.md content}."

**Agent 2: Silent Failure Hunter** (always run)
- **Type**: `general-purpose`
- **Prompt**: "Analyze this PR diff for silent failures, inadequate error handling, swallowed errors, and inappropriate fallback behavior. For each finding, include the file path, line number, and a confidence score (0-100). Only report findings with confidence ≥80. Here is the diff: {diff}."

**Agent 3: Test Analyzer** — only if test files changed
- **Type**: `general-purpose`
- **Prompt**: "Review this PR diff for test coverage quality and completeness. Identify critical gaps in test coverage, missing edge case tests, and inadequate assertions. For each finding, include confidence score (0-100). Only report findings ≥80. Here is the diff: {diff}."

**Agent 4: Comment Analyzer** — only if comments/docs were added or modified
- **Type**: `general-purpose`
- **Prompt**: "Analyze the comments and documentation in this PR diff for accuracy, completeness, and long-term maintainability. Check that comments accurately reflect the code they describe. For each finding, include confidence score (0-100). Only report findings ≥80. Here is the diff: {diff}."

**Agent 5: Type Design Analyzer** — only if new type/interface/struct definitions were added
- **Type**: `general-purpose`
- **Prompt**: "Analyze the type design in this PR diff. Review new types for encapsulation, invariant expression, usefulness, and enforcement. For each finding, include confidence score (0-100). Only report findings ≥80. Here is the diff: {diff}."

#### 12c. Evaluate & Act

Collect findings, verify against source files, categorize.

**Verdict logic:**
- **SHIP IT** → continue automatically, no pause
- **NEEDS FIXES** (only code quality issues, no AC gaps) → auto-fix all, no pause
- **NEEDS WORK** (AC gaps) → **PAUSE** — requires human decision

**Capture review metrics**: After the verdict is determined, record:
- `review_verdict`: the verdict string (`"SHIP IT"`, `"NEEDS FIXES"`, or `"NEEDS WORK"`)
- `review_findings`: total count of validated findings across all review agents
- `review_fixes_applied`: count of findings that will be auto-fixed (`0` for SHIP IT, count for NEEDS FIXES)
- `review_agents`: list of agent type names that were launched (e.g., `["code-reviewer", "silent-failure-hunter", "test-analyzer"]`)
Store these for use in Step 12e.2 metrics.

#### 12d. Fix Issues (if NEEDS FIXES)
1. Apply fixes using Edit tool
2. Run detected validation commands
3. Commit: `fix: address review feedback for {task-id}`
4. Push to remote

#### 12e. Update Planning Doc
1. Change task status from `[🔨]` to `[x] PR #{number}` in both Appendix and Feature Summary
2. Commit: `chore: mark {task-id} done (PR #{number})`

#### 12e.2. Append Metrics

After marking done, append one JSONL line to `planning/{folder-name}/metrics.jsonl` (create the file if it doesn't exist). See `references/metrics-schema.md` for the full field specification.

> **Note:** In standalone mode, metrics are written earlier in Step 12a-standalone (without `review` data). This step only runs in merge-mode where the review has already completed inline.

```json
{"task":"{task-id}","title":"{task title}","estimated_h":{hours},"actual_h":{actual_hours},"complexity":{complexity_score},"retries":{retry_count},"ci_fix_attempts":{ci_attempt},"pr":{pr_number},"hotfixes":0,"files_changed":{files_changed_count},"ts":"{ISO timestamp}","simplify":{"total":{simplify_total},"dry":{simplify_dry},"dead_code":{simplify_dead_code},"naming":{simplify_naming},"complexity":{simplify_complexity},"consistency":{simplify_consistency}},"requirements":{"met":{req_met},"partial":{req_partial},"not_met":{req_not_met},"unverifiable":{req_unverifiable},"total":{req_total}},"review":{"verdict":"{review_verdict}","findings":{review_findings},"fixes_applied":{review_fixes_applied},"agents":{review_agents_json_array}},"ci":{"fix_attempts":{ci_attempt},"failures":{ci_failures_json_array}},"model":"{model_tier}","coverage":{"before":{coverage_before},"after":{coverage_after},"delta":{coverage_delta}}}
```

Field derivation:
- `actual_h`: elapsed time from Step 6 branch creation to now (approximate from wall clock or git timestamps)
- `complexity`: from the task's Complexity field in the planning doc (0 if not set — pre-B1.2 planning docs)
- `retries`: 0 in standalone dev-task; passed from dev-loop retryMap when called via dev-loop
- `ci_fix_attempts`: number of CI fix subagent attempts in Step 11b (0 if CI passed on first try or no CI configured)
- `files_changed`: count from `git diff --stat main...{branch}` (before merge)
- `simplify.*`: tallied in Step 8. All 0 if no simplify fixes were needed.
- `requirements.*`: tallied in Step 9. If Step 9 was not reached, omit the `requirements` field entirely.
- `review.*`: captured in Step 12c (merge-mode only). In standalone mode, the `review` field is omitted — `/review` will enrich the metrics line later (see review.md Step 10b).
- `ci.fix_attempts`: mirrors top-level `ci_fix_attempts`. `ci.failures`: from Step 11b.3 collection. Empty array `[]` if CI passed on first try.
- `model`: from the task's Model field in the planning doc, or the current session model if not specified. Use `null` if unknown.
- `coverage.*`: from Step 10 coverage gate. Use `null` for any field that couldn't be measured.

This step is silent — no output. JSONL format means one JSON object per line; append-only. Old metrics.jsonl files without the new fields remain valid — see `references/metrics-schema.md` for backward compatibility rules.

#### 12f. Learning Capture (Optional)
Check if the `learning-loop` plugin is available by checking if `/learn` skill exists.
- If available: review findings for patterns, auto-stage genuine learnings via `/learn`, then run `/learn-promote`
- If not available: skip this step

#### 12g. Merge
Auto-merge with squash: `gh pr merge {pr-number} --squash --delete-branch`

Print the completion block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TASK COMPLETE (merge-mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task:   {task-id} — {task title}
Branch: {branch} → merged to main
PR:     #{pr-number} — squash-merged
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Handling Legacy Planning Docs

If the planning doc lacks Status/Branch/Context columns (auto-detected by checking for `| Status |` in the Appendix table header), run this migration before proceeding with the normal flow:

1. **Add Status column** to the Appendix and all feature Summary tables — insert `| [ ] |` as the first column for every task row
2. **Compute and add Branch field** to each task's field table using the naming convention: `feat/{task-id-lowered-dots-to-dashes}-{first-3-4-words-kebab}`
3. **Generate Context field** for each task from its parent feature Overview section (2-3 sentences)
4. **Commit**: `chore: migrate {doc-name} to new planning format`
5. Then proceed with Step 1 (Find Planning Doc) using the migrated doc
