---
description: Autonomous dev loop — continuously processes all tasks from the planning doc until every task is done or blocked
arguments:
  - name: folder-name
    description: Planning session folder under planning/ (e.g., february-2026-workspace-switcher). Optional — auto-detected if only one planning doc exists with [ ] tasks remaining.
    required: false

---

# Dev Loop

Continuous autonomous development loop. Processes **every task** in the planning doc — implement, review, merge, pick next, repeat — until all tasks are `[x]` or the remaining tasks are blocked.

**No task IDs, no branch names, no PR numbers, no /clear between tasks.** Everything is auto-detected from the planning doc. You run this once and walk away.

---

## Phase 0: Locate Planning Doc (once)

{If $ARGUMENTS provided:}
- Search `planning/$ARGUMENTS/*_Task_Breakdown.md`

{If no arguments:}
- Glob all `planning/**/*_Task_Breakdown.md` files
- For each, count `[ ]` (not started) tasks in the Appendix
- If exactly one doc has remaining tasks, use it
- If multiple docs have remaining tasks, list them and ask the user which one to use
- If no docs have remaining tasks, print "All tasks complete!" and stop

Extract the **Project Metadata** section from the planning doc header and store the toolchain info for use in Phase 2a context briefings:
- **Toolchain**: ecosystem and package manager (e.g., "Node.js (pnpm)")
- **Validate command**: the full validation command (e.g., `pnpm validate`)
- **Test command**: the test command (e.g., `pnpm test`)
- **Lint command**: the lint command (e.g., `pnpm lint`)

If the planning doc's Project Metadata section doesn't include explicit commands, derive them from the toolchain and package manager using the same detection logic as `plan-session` Phase 0b (see `references/toolchain-patterns.md`).

### Handoff Restoration

Check the planning doc for a `## Handoff` section. If present, restore prior session state:

1. Read the `## Handoff` section fields: `Last completed`, `Timestamp`, `Batch`, `Recent changes`, `Retry map`, `Notes`
2. Restore `recentChanges[]` from the `Recent changes` list
3. Restore `retryMap` from the `Retry map` entries (parse `{taskId}: {count}` lines)
4. Print:
   ```
   ↩ Resuming from handoff (last: {Last completed}, batch {Batch})
   ```

If no `## Handoff` section is present, start with empty `recentChanges[]` and `retryMap` as normal.

Print the initial status:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEV LOOP — STARTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Document: {filename}
Toolchain: {ecosystem} ({package manager})
Tasks:    {total} total, {done} done, {remaining} remaining
Hours:    ~{remaining_hours}h estimated remaining
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## LOOP START — repeat for each task

### Phase 1: Pick Ready Tasks

Re-read the planning doc Appendix (it may have been updated by the previous iteration). Find **ALL** `[ ]` tasks whose dependencies are all satisfied (`[x]` status or no dependencies).

**If no `[ ]` tasks remain** → go to LOOP END (all done)

**If `[ ]` tasks exist but none have satisfied deps** → go to LOOP END (blocked)

#### Parallel Eligibility

From the ready tasks, build a parallel batch (max 3 concurrent):

1. Start with all ready tasks
2. For each pair of ready tasks, check if they modify the **same primary files** (compare the `Location` fields in Technical Details). If they share any files, they CANNOT run in parallel — keep only the first one in this batch.
3. Take up to 3 non-conflicting tasks for the batch
4. If only 1 task is eligible, run it solo (same as previous single-task behavior)

**Constraint:** Tasks in the same Layer that modify the same files (e.g., two Database tasks editing `schema.prisma`) must NOT be parallelized — run those sequentially to avoid merge conflicts.

Print the batch plan and proceed without pausing:

```
{If batch size > 1:}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PARALLEL BATCH: {batch_size} tasks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{For each task in batch:}
  {N}/{total}: {task-id} — {task title}
    Branch: {branch} | Layer: {layer} | Hours: {hours}
Progress: {done_count}/{total_count} tasks complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{If batch size == 1:}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TASK {N}/{total}: {task-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{Task title}
Branch:   {branch}
Layer:    {layer} | Hours: {hours}
Approach: {architecture}
Progress: {done_count}/{total_count} tasks complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Phase 2: Develop, Review & Merge (via subagent)

Do NOT run any git commands or planning doc edits in the main context — everything happens inside subagent(s) via `/dev-task --merge` (which handles mark-in-progress, branch setup, implementation, PR, review, and merge).

#### 2a. Build Context Briefing

Before launching the subagent, construct a context briefing to reduce exploration overhead. Each subagent gets this briefing prepended to its prompt.

1. **Project structure**: List the top-level directories and their purpose (from Phase 0 or first-iteration scan via `ls` on key directories)

2. **Recent changes** (rolling last 3): Use the `recentChanges[]` array maintained across loop iterations (updated in Phase 3c). For the first iteration, this array is empty.
   ```
   Format per entry:
   - {taskId}: {title} — changed {filesChanged count} files ({summary})
   ```

3. **Key files for this task**: From the current task's Technical Details → Location fields, list the primary files that will be modified. Also flag overlaps with recent changes:
   ```
   ⚠ {file} was also modified by {recent taskId} — check for conflicts
   ```

4. **Validation commands**: The test, lint, and build commands detected in Phase 0 (so the subagent doesn't re-detect).

Format the briefing:

```
CONTEXT BRIEFING (from dev-loop)
─────────────────────────────────
Project: {top-level directory summary}
Toolchain: {ecosystem} ({package manager})
Validate: {validate command}
Test: {test command}
Lint: {lint command}

Recent changes (last {N} tasks):
{For each entry in recentChanges[]:}
- {taskId}: {title} — changed {count} files ({summary})

Key files for this task:
{file paths from Technical Details}
{If overlapping: ⚠ {file} was also modified by {taskId}}
─────────────────────────────────
```

#### 2b. Launch Subagent(s)

##### Single task (batch size == 1)

Launch a **general-purpose Agent** subagent with the context briefing prepended:

**Launch subagent** with this prompt:

```
{CONTEXT BRIEFING from 2a}

You are running a fully autonomous development task. Do NOT use
AskUserQuestion or pause for user input at any point. All design
decisions have been pre-made during planning.

Run: /dev-task {task-id} --merge

This will execute the full pipeline: implement → simplify → verify →
create PR → review → merge. All pause points are suppressed in
merge-mode.

If any skill or workflow asks clarifying questions, answer them using
the Implementation Decisions from the planning doc for this task:
- Edge Cases: {value}
- Error Handling: {value}
- Scope Boundaries: {value}
- Backward Compatibility: {value}
- Performance: {value}

For architecture choice, use: {architecture}
For quality review issues: auto-fix all fixable issues.
```

Wait for the subagent to complete, then proceed to Phase 3.

##### Parallel batch (batch size > 1)

Launch up to 3 subagents **in parallel**, each using the Agent tool with `isolation: "worktree"` so they work on isolated copies of the repository with no merge conflicts during implementation:

For each task in the batch, launch an Agent in **the same message** (multiple tool calls) with:

```
Agent(
  type: "general-purpose",
  isolation: "worktree",
  prompt: """
    {CONTEXT BRIEFING for this specific task — from 2a}

    You are running a fully autonomous development task. Do NOT use
    AskUserQuestion or pause for user input at any point. All design
    decisions have been pre-made during planning.

    Run: /dev-task {task-id} --merge

    {same Implementation Decisions and instructions as single-task prompt}
  """
)
```

Wait for **ALL** subagents in the batch to complete before proceeding.

##### Post-Batch Sync (parallel batches only)

After all parallel subagents complete:

1. Return to the main worktree: `git checkout main && git pull`
2. Re-read the planning doc — verify all tasks in the batch are marked `[x]`
3. For any task that failed, handle via Phase 3's failure recovery (3a-retry)
4. Process Phase 3 (bug scan, context update) for each completed task in the batch

**Resource guard:** Never launch more than 3 parallel subagents. If worktree creation fails, fall back to sequential execution for that task.

---

### Phase 3: Post-Task Processing & Loop Back

After the subagent completes, run the following checks before looping:

#### 3a. Confirm Completion

Re-read the planning doc to check the task's status:
- If marked `[x]` → task succeeded, continue to 3b
- If still `[🔨]` → task failed, go to 3a-retry

#### 3a-retry. Subagent Failure Recovery

If the subagent failed (task still `[🔨]` not `[x]`):

1. **Clean up orphaned PR/branch:**
   - Check: `gh pr list --head {branch} --state open --json number,title`
   - If orphaned PRs found: `gh pr close {N} --comment "Shipwright cleanup — subagent failed"`
   - Delete remote branch: `git push origin --delete {branch}` (if it exists)
   - Return to main: `git checkout main && git branch -D {branch}` (if local branch exists)

2. **Reset task status** from `[🔨]` to `[ ]` in the planning doc, commit: `chore: reset {task-id} after subagent failure`

3. **Retry logic** (max 1 retry per task):
   - Track retry counts in a local `retryMap` object: `{ [taskId]: retryCount }`
   - If this is the **first failure** for this task (retryMap[taskId] == 0): increment count, re-queue the task by continuing to Phase 1 (it will be picked up again as a `[ ]` task with satisfied deps)
   - If this is the **second failure** (retryMap[taskId] >= 1): mark task as `[⏸]` (blocked) in the planning doc, commit: `chore: mark {task-id} blocked after 2 failures`

4. Print:
   ```
   ⚠ TASK FAILED: {task-id} — {first attempt: retrying | second attempt: blocked}
   {If cleanup happened: "Cleaned: PR #{N}, branch {branch}"}
   ```

→ Continue to 3b (scan the failed output too) then 3c (loop back)

#### 3b. Bug Scan

Scan the subagent's output for phrases indicating discovered bugs or issues:

**Bug indicators:**
- `FIXME`, `TODO`, `HACK`, `WORKAROUND`
- `regression`, `broke`, `broken`, `breaking change`, `mismatch`
- `TypeError`, `ReferenceError`, `panic`, `segfault`
- `coverage.*below`, `coverage.*dropped`
- `pre-existing`, `doesn't work`, `known issue`

**False-positive guard:** Require the bug indicator to appear alongside evidence of an actual problem (error trace, failing test output, or explicit "this is a bug" statement). A comment mentioning "bug" in passing does not qualify.

If a genuine bug is found:

1. Generate a hotfix task ID: `HF-{N}` (where N increments from 1 across the entire loop run)

2. Create the hotfix task:
   ```
   #### Task HF-{N}: Hotfix — {brief description of the bug}
   | Field | Value |
   |-------|-------|
   | **ID** | HF-{N} |
   | **Hours** | 1 |
   | **Layer** | {same layer as triggering task} |
   | **Dependencies** | {triggering task ID} |
   | **Branch** | `fix/hf-{n}-{brief-description-kebab}` |
   | **Context** | Bug detected during {triggering task ID} execution: {description} |
   | **Architecture** | `minimal` |

   **Description**: Fix {description} introduced or discovered during {task-id}.
   **Acceptance Criteria**:
   - [ ] Bug is resolved
   - [ ] All existing tests pass
   - [ ] No regression in coverage
   ```

3. Append the hotfix task to the planning doc — both in the relevant feature section and the Appendix. Commit: `chore: add hotfix task HF-{N} discovered during {task-id}`

4. Print:
   ```
   ⚠ BUG DETECTED after {task-id}
   Generated: HF-{N} — {description}
   Will be picked up in next loop iteration.
   ```

5. If multiple bugs are found in one task's output, create multiple HF tasks (HF-1, HF-2, etc.)

The hotfix task will naturally be picked up in Phase 1 of the next iteration — its only dependency is the task that just completed, which is now `[x]`.

#### 3c. Update Context & Loop Back

1. **Update recentChanges[]**: Push the completed task's summary to the rolling array (used by Phase 2a context briefing):
   ```
   { taskId, title, branch, filesChanged: [from git diff --stat], summary: "1-line" }
   ```
   Keep only the last 3 entries.

2. **Write Handoff section**: Update (or create) the `## Handoff` section in the planning doc with current state, then commit:

   ```markdown
   ## Handoff
   <!-- Auto-updated by dev-loop. Do not edit manually. -->

   Last completed: {task-id}
   Timestamp: {ISO timestamp}
   Batch: {current_batch} of {estimated_remaining}

   Recent changes:
   {For each entry in recentChanges[]:}
   - {taskId}: {title} — changed {count} files ({summary})

   Retry map:
   {For each entry in retryMap with count > 0:}
   - {taskId}: {count}
   {If retryMap is empty: (none)}

   Notes:
   {Any notable issues, warnings, or context from this iteration}
   ```

   Commit: `chore: update handoff state after {task-id}`

3. Print a brief completion line:
   ```
   ✓ {task-id}: {task title} — merged ({done_count}/{total_count})
   ```

→ **Go to Phase 1** (pick next task batch)

---

## LOOP END

When the loop exits:

1. **Remove Handoff section**: Delete the `## Handoff` section from the planning doc (loop is complete, no resumption needed). Commit: `chore: remove handoff state — loop complete`

2. Print the final summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEV LOOP — COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{If all tasks [x]:}
ALL TASKS COMPLETE
PRs shipped: {list of PR numbers}
Total tasks: {count}

{If remaining tasks are blocked:}
STOPPED — BLOCKED TASKS
Completed: {done_count}/{total_count}
PRs shipped: {list of PR numbers}

Blocked tasks (unsatisfied dependencies):
- {task-id}: {title} — waiting on {dep-ids}

These tasks likely have [🔨] in-progress dependencies
that need to be completed in a separate session.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Loop Retrospective

After the loop summary, collect and present pipeline metrics before permission cleanup.

#### Collect Metrics

If `planning/{folder-name}/metrics.jsonl` exists (written by dev-task Step 12e.2 during this run), read it to get per-task actuals. For any tasks not in metrics.jsonl, fall back to git log timestamps.

For each completed task, gather from metrics.jsonl or git log and planning doc:

1. **Actual vs estimated hours**: From `metrics.jsonl` if available (field: `actual_h`); otherwise use git commit timestamps — first commit on branch to merge commit — compared against the task's planned hours
2. **Retry count**: From `metrics.jsonl` (field: `retries`), or from retryMap if not in file
3. **Orphan PRs cleaned**: Count of PRs closed during cleanup (0 if none)
4. **Bug-fix tasks generated**: Count of `HF-*` tasks created during the run
5. **Permission settings diff**: Compare `.claude/settings.local.json` before vs after the run — count new entries added at runtime (not by plan-session)

**Aggregate from metrics.jsonl** (if file exists):
- Mean estimation error: `mean(actual_h / estimated_h - 1)` across all tasks, as a percentage
- Model distribution: count of tasks per complexity tier (1-2, 3, 4-5)
- Files changed: total across all tasks

**Fix cascade aggregates** (from enriched metrics.jsonl fields — v1.4.0+; skip if records lack these fields):
- **First-time quality rate**: percentage of tasks where `simplify.total == 0` AND `review.verdict == "SHIP IT"` AND `ci_fix_attempts == 0`
- **Simplify fix rate**: mean `simplify.total` across tasks; breakdown by category (dry, dead_code, naming, complexity, consistency)
- **Review verdict distribution**: count of SHIP IT / NEEDS FIXES / NEEDS WORK
- **CI first-pass rate**: percentage of tasks where `ci_fix_attempts == 0`
- **Coverage trend**: mean `coverage.delta` across tasks where coverage data exists

If any task record lacks the fix cascade fields (old format), exclude it from fix cascade aggregates but include it in the basic aggregates above.

#### Present Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEV LOOP — RETROSPECTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan vs Reality:
  Estimated:  {sum_est}h
  Actual:     {sum_actual}h ({ratio}x)

| Task | Est. | Actual | Delta | Retries | Notes |
|------|------|--------|-------|---------|-------|
{one row per completed task}

Quality:
  Tasks:      {completed}/{total}
  Retries:    {total_retries}
  Orphan PRs: {orphan_count}
  Bugs found: {hf_count} ({fixed_count} auto-fixed)

Efficiency:
  Parallel batches: {batch_count}

{If fix cascade data exists (any task has simplify/review/ci fields):}
Fix Cascade:
  First-time quality:  {ftq_rate}% ({ftq_count}/{review_enriched_count} tasks needed zero post-impl fixes)
  Simplify fixes:      {mean_simplify} avg/task (DRY {dry_avg} | Dead code {dc_avg} | Naming {name_avg} | Complexity {cx_avg} | Consistency {con_avg})
  Review verdicts:     {ship_it_count} SHIP IT / {needs_fixes_count} NEEDS FIXES / {needs_work_count} NEEDS WORK
  CI first-pass rate:  {ci_first_pass_rate}%
  Coverage delta:      {mean_delta}% avg

Permissions:
  Pre-configured: {plan_session_count}
  Added at runtime: {runtime_count}

Learnings staged: {learning_count}
  Run /learn-review to see them
  Run /learn-promote to route to plugin improvements
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Stage Learnings

If `learning-loop` plugin is available:

1. If estimation accuracy is off by >30% on average, stage a learning:
   `Shipwright/dev-loop: {ecosystem} projects take ~{percent}% longer/shorter than estimated — {layer} tasks are the primary driver`
2. If retries > 0, stage a learning about each failure pattern:
   `Shipwright/dev-loop: Tasks on {layer} layer commonly fail due to {pattern} — consider adding {mitigation} to planning`
3. If permission prompts occurred at runtime (settings diff > 0), stage a learning:
   `Shipwright/dev-loop: Missing permission pattern for {command} — add to plan-session Phase 7 detection`
4. If bug-fix tasks were generated, stage a learning:
   `Shipwright/dev-loop: {count} bugs discovered during execution — {pattern} tasks are most likely to surface bugs`
5. If first-time quality rate < 70% (fix cascade data required), stage a learning:
   `Shipwright/dev-loop: First-time quality rate is {rate}% — most common simplify category is {category}. Consider adding {category} enforcement to implementation prompts.`
6. If simplify fix rate > 3 per task on average (fix cascade data required), stage a learning:
   `Shipwright/dev-loop: Simplify phase is catching an average of {N} fixes per task (top category: {category}). Add a pre-simplify checklist to the implementation brief.`
7. Run `/learn-promote`

If not available, print the findings as part of the retrospective summary block.

---

## Pause Summary

The loop runs continuously and pauses ONLY when human judgment is genuinely needed:

| Situation | Pauses? | Why |
|-----------|---------|-----|
| Dependencies not met | No | Pre-checked each iteration |
| Implementation clarifying questions | No | Subagent answers from Implementation Decisions |
| Implementation architecture choice | No | Subagent picks pre-decided approach |
| Implementation authorization | No | Subagent auto-approves |
| Requirements PARTIAL | No | Acceptable — auto-proceed in merge-mode |
| Requirements NOT MET | **Yes** | Human must decide: skip or fix |
| Build/lint/type failure | **Yes** | May need human intervention |
| Coverage below threshold | No | Logged, auto-proceed in merge-mode |
| Review verdict NEEDS WORK | **Yes** | AC gaps routed through dev-task merge-mode |
| PR creation + merge | No | Handled by dev-task --merge |
| CI check failure (fix loop) | No | Subagent auto-fixes, up to 3 retries |
| CI check failure (exhausted) | No | Triggers PR Failure Cleanup, dev-loop re-queues |
| Between tasks | No | **Loops automatically** |
| Parallel batch completion | No | All subagents complete before proceeding |
| Post-batch main sync | No | Automatic pull after parallel batch |
| Subagent failure (1st) | No | Auto-cleanup and re-queue |
| Subagent failure (2nd) | No | Auto-mark blocked |
| All other steps | No | Fully autonomous |
