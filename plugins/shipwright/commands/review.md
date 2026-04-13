---
description: Review open PRs from the queue — process session by session, patch CI failures, merge when green
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
---

# Review

Process open PRs from the shipwright queue. Group by session for shared context. Patch, approve, and merge.

**This command runs autonomously. Do not pause for user input unless a fundamental acceptance criteria gap requires a design decision.**

---

## Step 1: Find Open PRs

Read `state/todos.json`. Find all `shipwright` tasks with `status: "pr_open"`.

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

## Step 2: Gather Context Per PR

For each open PR in the session:

1. **Task details from todos.json**: `id`, `title`, `acceptanceCriteria`, `repo`, `session`
2. **PR details**: `gh pr view {pr} --repo {org}/{repo} --json number,title,headRefName,baseRefName,additions,deletions,changedFiles,statusCheckRollup,reviewDecision`
3. **PR diff**: `gh pr diff {pr} --repo {org}/{repo}`

Auto-detect the project toolchain for the repo (used in Steps 5b and 8):

1. Scan the project root for config files:
   - `package.json` + lockfile → Node.js (detect manager: pnpm/yarn/npm/bun)
   - `Cargo.toml` → Rust
   - `go.mod` → Go
   - `pyproject.toml` / `setup.py` → Python
   - `Gemfile` → Ruby
   - `Makefile` → Generic Make

2. For Node.js: read `package.json` scripts for `validate`, `build`, `test`, `lint`, `typecheck`/`check`

Refer to `references/toolchain-patterns.md` for the full detection lookup table.

Present a summary per PR:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEW CONTEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: {id} — {title}
PR:   #{pr} — {pr title}
Base: {base branch} ← {head branch}
Size: +{additions} -{deletions} across {changedFiles} files

Acceptance Criteria:
{numbered list from task.acceptanceCriteria}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

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

## Step 7b: Submit GitHub Review

After determining the verdict, submit a **formal GitHub review** to structurally enforce it — a plain comment is not enough, as it doesn't change `reviewDecision` and won't block merges.

- **SHIP IT** → `gh pr review {pr-number} --repo {owner/repo} --approve --body "shipwright:review — SHIP IT. All criteria met, no blocking issues."`
- **NEEDS FIXES** or **NEEDS WORK** → `gh pr review {pr-number} --repo {owner/repo} --request-changes --body "{condensed findings: one line per issue, category + file:line + description}"`

This sets the PR's `reviewDecision` to `APPROVED` or `CHANGES_REQUESTED`. The pr-health cron and GitHub's branch protection both read this field — a formal review is what actually enforces the gate.

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

## Step 10: Update Queue

If the verdict is **SHIP IT**:

Update the task in `state/todos.json`:
- `status: "merged"`
- `mergedAt: "{ISO timestamp}"`

Write todos.json. Check if any `pending` tasks now have all dependencies `merged` — note them in the output so the next execution tick picks them up.

If the verdict is not SHIP IT, skip this step.

## Step 10b: Enrich Metrics with Review Data

After the review verdict is determined, update the task's metrics record with review data. This enriches the record that `/dev-task` wrote (which omitted `review` in standalone mode).

1. Find the planning doc folder for this task (already known from Step 2)
2. Read `planning/{folder-name}/metrics.jsonl`
3. Find the JSON line where the `task` field matches the current task ID
4. Parse the JSON object and add the `review` fields:
   ```json
   "review": {
     "verdict": "{verdict from Step 7}",
     "findings": {count of validated findings from Step 5},
     "fixes_applied": {count of fixes applied in Step 8},
     "agents": ["code-reviewer", "silent-failure-hunter", ...]
   }
   ```
5. Write the updated JSON line back to `metrics.jsonl`, replacing the original line for this task
6. **Edge case:** If no metrics line exists for this task (dev-task ran before v1.4.0 or metrics were not written), append a new line with `task`, `title`, `ts` (current timestamp), and `review` fields only. This partial record will be excluded from non-review aggregates by `/metrics` but included in review aggregates.

This step runs regardless of the verdict (SHIP IT, NEEDS FIXES, or NEEDS WORK) — all verdicts are valuable data.

This step is silent — no output to the user.

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

1. If the initial verdict in Step 7 was **NEEDS FIXES** or **NEEDS WORK** (i.e., a `--request-changes` review was submitted in Step 7b), re-submit as an approval now that fixes are verified:
   `gh pr review {pr-number} --repo {owner/repo} --approve --body "shipwright:review — fixes verified, approving."`
2. Merge the PR: `gh pr merge {pr-number} --squash --delete-branch`

Check todos.json for newly unblocked tasks (pending tasks whose dependencies are now all merged). Print the completion block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REVIEW COMPLETE — {session}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Merged:  {list "#{pr} {id}: {title}"}
Blocked: {list with reason, or "none"}

{If newly unblocked tasks:}
Ready for execution:
  {list task IDs}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
