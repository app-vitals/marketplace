---
description: Auto-detecting code review — recovers task from branch name, verifies PR against planning doc acceptance criteria, runs parallel review agents, captures learnings
---

# Review

Auto-detecting code review for a fresh session. Follow all steps in order. Only pause where explicitly marked — keep the flow fast.

---

## Step 0: Setup

### 0a. Check Recommended Plugins

Check if the following plugins are installed by looking for their skills in the available skills list:

| Plugin | Check For | Used In |
|--------|-----------|---------|
| `learning-loop` | `/learn` skill | Step 11 (Learning Capture) |

If any are missing, present:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDED PLUGINS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The following plugins enhance this workflow:

MISSING:
  ✗ learning-loop — captures review learnings
    Install: /plugin install learning-loop@app-vitals/marketplace

INSTALLED:
  ✓ {installed plugins}

Continue without them? (Yes / Install first)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If all plugins are installed, skip the prompt and continue. If plugins are missing and the user chooses to continue, note which are unavailable so later steps can skip those features.

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

3. Store the detected commands for use in Steps 5b and 8.

Refer to `references/toolchain-patterns.md` for the full detection lookup table.

## Step 1: Auto-Detect Context

Gather context automatically — no arguments needed:

1. Get current branch: `git branch --show-current`
2. If on `main`, tell the user: "You're on the main branch. Switch to a feature branch first, or pass a branch name." and stop.
3. Find the PR for this branch: `gh pr list --head {branch} --json number,title,url --jq '.[0]'`
4. If no PR found, tell the user: "No PR found for branch {branch}. Push and create a PR first (or run /dev-task to complete development)." and stop.

## Step 2: Recover Task ID

Parse the branch name to recover the task ID:

1. Strip the `feat/` prefix
2. Extract the task ID pattern from the beginning: the prefix letters + numbers separated by dashes map back to the dotted task ID. M can be numeric (`1`, `2`) or a test suffix (`t1`, `t2`). Uppercase all alphabetic characters in the resulting ID.
   - Pattern: `{letters}-{N}-{M}` → `{LETTERS}-{N}.{M}`
   - Example: `feat/mr-2-1-extract-types-libs` → prefix `mr-2-1` → task ID `MR-2.1`
   - Example: `feat/pb-1-t1-unit-tests-badge-icon` → prefix `pb-1-t1` → task ID `PB-1.T1`
   - The prefix ends when you hit a segment that is longer than 2 characters or doesn't match the `[a-z]+\d*` pattern (i.e., the start of the kebab-case description slug)
3. Search `planning/**/*_Task_Breakdown.md` for this task ID
4. If the task ID can't be recovered from the branch name or isn't found in any planning doc:
   - Ask the user: "Couldn't recover task ID from branch `{branch}`. What's the task ID? (e.g., MR-2.1)"
   - Use the user-provided ID to find the task

## Step 3: Gather Context

Fetch all sources in parallel:

1. **Task details from planning doc**: Extract acceptance criteria, context, description, test type (if present)
2. **PR details**: `gh pr view {pr-number} --json title,body,baseRefName,headRefName,additions,deletions,changedFiles`
3. **PR diff**: `gh pr diff {pr-number}`

Present a summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEW CONTEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: {task-id} — {task title}
PR:   #{pr-number} — {pr title}
Base: {base branch} ← {head branch}
Size: +{additions} -{deletions} across {changedFiles} files

Acceptance Criteria:
{numbered list from planning doc}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Proceed directly to the review — the user invoked this command, no confirmation needed.

## Step 4: Launch Review Agents

First, analyze the diff to determine which conditional agents to run:
- **Test files changed?** — glob the diff for `*.test.*`, `*.spec.*`, `tests/`, `*_test.go`, `*_test.rs`, `test_*.py` paths
- **Comments added/modified?** — scan the diff for doc comments (`/**`, `///`, `#[doc`, `"""`) or substantial comment blocks (3+ consecutive comment lines)
- **New types introduced?** — scan the diff for added `interface `, `type ` (TS), `struct ` (Rust/Go), `class ` (Python/Ruby), `dataclass` definitions

Then launch review agents in parallel using the Agent tool:

### Always run (core review):

**Agent 1: Code Review** (confidence-scored)
- **Type**: `feature-dev:code-reviewer`
- **Prompt**: "Review this PR diff for bugs, logic errors, code quality, and CLAUDE.md compliance. Apply confidence scoring — only report findings ≥80 confidence. Here is the diff: {diff}. Here are the CLAUDE.md contents: {CLAUDE.md content}."

**Agent 2: Silent Failure Hunter**
- **Type**: `general-purpose`
- **Prompt**: "Analyze this PR diff for silent failures, inadequate error handling, swallowed errors, and inappropriate fallback behavior. For each finding, include the file path, line number, a description of the issue, and a confidence score (0-100). Only report findings with confidence ≥80. Here is the diff: {diff}."

### Conditionally run (based on diff analysis):

**Agent 3: Test Analyzer** — only if test files changed
- **Type**: `general-purpose`
- **Prompt**: "Review this PR diff for test coverage quality and completeness. Identify critical gaps in test coverage, missing edge case tests, and inadequate assertions. For each finding, include file path, description, and confidence score (0-100). Only report findings ≥80. Here is the diff: {diff}."

**Agent 4: Comment Analyzer** — only if comments/docs were added or modified
- **Type**: `general-purpose`
- **Prompt**: "Analyze the comments and documentation in this PR diff for accuracy, completeness, and long-term maintainability. Check that comments accurately reflect the code they describe. For each finding, include file path, description, and confidence score (0-100). Only report findings ≥80. Here is the diff: {diff}."

**Agent 5: Type Design Analyzer** — only if new type/interface/struct definitions were added
- **Type**: `general-purpose`
- **Prompt**: "Analyze the type design in this PR diff. Review new types for encapsulation, invariant expression, usefulness, and enforcement. For each finding, include file path, description, and confidence score (0-100). Only report findings ≥80. Here is the diff: {diff}."

Present which agents were selected and why (1 line each):
```
Agents launched: code-reviewer, silent-failure-hunter{, test-analyzer}{, comment-analyzer}{, type-design-analyzer}
{1-line reason for each conditional agent that was included or excluded}
```

## Step 5: Validate Findings

Collect all findings from the agents that ran.

- **code-reviewer** findings already use confidence ≥80 scoring — pass through directly without re-scoring
- **All other agents**: read the actual source file to verify each finding is accurate (not a false positive from reading only the diff), assign a confidence score (0-100), discard findings with confidence < 80

Categorize remaining findings: **Bug**, **Style**, **Pattern**, **Security**, **Performance**, **Test Gap**, **Comment**, **Type Design**

## Step 5b: Coverage Verification

Run coverage checks for each package with changed files in the PR, using the detected toolchain from Step 0:

1. **Detect changed packages**: From the diff, identify which packages/modules were modified
2. **Run tests with coverage**: Use the detected test command with coverage enabled (e.g., `--coverage` flag for vitest/jest, `--cov` for pytest, `tarpaulin` for Rust)
3. **Compare to threshold**: Use the threshold from the planning doc's Project Metadata (default: 90%)

Add coverage results to the review report in Step 7. If coverage is below the threshold for any package, add it as a finding with category **Coverage** and confidence 100.

## Step 6: Requirements Verification

For each acceptance criterion from the planning doc, evaluate against the PR diff:

| Status | Meaning |
|--------|---------|
| MET | Clear evidence in the diff that this criterion is satisfied |
| PARTIAL | Some progress but incomplete implementation |
| NOT MET | No evidence of implementation |
| UNVERIFIABLE | Cannot determine from code alone |

## Step 7: Present Report

Display the combined review report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CODE REVIEW REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Code Issues ({count} findings, {N} agents ran)

| # | Category | File:Line | Issue | Confidence |
|---|----------|-----------|-------|------------|
{one row per validated finding, sorted by confidence desc}

## Coverage

| Package | Type | Lines | Branches | Target | Status |
|---------|------|-------|----------|--------|--------|
{one row per affected package — PASS if above threshold, FAIL if at/below}

## Requirements Verification

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
{one row per acceptance criterion}

## Verdict

{One of:}
- SHIP IT — All criteria met, no blocking issues
- NEEDS FIXES — {N} issues to resolve before merging
- NEEDS WORK — Acceptance criteria gaps require implementation work

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Pause point:** Ask the user which findings to fix (if any). The user may dismiss some findings.

## Step 8: Fix Issues

For each finding the user approved for fixing:

1. Read the full file containing the issue
2. Apply the fix using Edit tool
3. Explain what was changed and why (1-2 sentences)

After all fixes are applied:

1. Review the changed files for consistency and clarity (inline simplification pass)
2. Run the detected validation commands from Step 0 (e.g., `{manager} validate`, `cargo clippy`, `go vet`, `pytest`)
3. For multi-ecosystem projects, run validation for each ecosystem

If checks fail, fix the failures before proceeding.

## Step 9: Commit & Push

If fixes were applied in Step 8:

1. Run `git status` and `git diff --stat`
2. Stage and commit with: `fix: address review feedback for {task-id}`
3. Push to the remote branch
4. Inform the user: "Committed and pushed review fixes: {short-sha}"

No pause — the commit message is always the same. If no fixes were applied, skip to Step 10.

## Step 10: Update Planning Doc

If the verdict is **SHIP IT**:

1. Get the PR number from Step 1
2. In the planning doc **Appendix: Complete Task List** table, change the task's status from `[🔨]` to `[x] PR #{number}`
3. In the **{Feature Name} Summary** table, change the same task's status from `[🔨]` to `[x] PR #{number}`
4. Commit: `chore: mark {task-id} done (PR #{number})`
5. Push to the current branch

If the verdict is not SHIP IT, skip this step.

## Step 11: Learning Capture (Optional)

Check if the `learning-loop` plugin is available (look for `/learn` in available skills).

If available:
1. Review the findings from Step 5 and fixes from Step 8. Look for:
   - Patterns that appeared multiple times across different files
   - Issues that suggest a missing convention or guideline
   - Bugs that could be prevented by a documented rule
2. If 1-2 genuine learnings are identified, auto-stage them using `/learn`, then run `/learn-promote` to route them to their final destination immediately.
3. If no genuine patterns were found, skip — do not force learnings.

If not available: skip this step entirely.

## Step 12: Final Commit, Push & Merge

If learning capture wrote any changes (i.e., CLAUDE.md or CLAUDE.local.md were modified):

1. Stage the changed files
2. Commit with: `chore: promote learnings from /review`
3. Push to the remote branch

**Pause point:** Ask the user: "Merge PR #{pr-number}? (Yes / No)"

If yes, merge the PR using `gh pr merge {pr-number} --squash --delete-branch`.

After merge (or if user declines merge), scan the planning doc Appendix for the **suggested next task**: find `[ ]` tasks whose dependencies are all `[x]` (or have no dependencies).

Print the completion block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEW COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: {task-id} — {task title}
PR:   #{pr-number} — {merged | ready to merge}

AVAILABLE TASKS
───────────────
{List [ ] tasks with all deps satisfied:}
- {PREFIX-N.M}: {task title} ({hours}h)

NEXT: /dev-task {suggested-task-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
