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

Print the initial status:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEV LOOP — STARTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Document: {filename}
Tasks:    {total} total, {done} done, {remaining} remaining
Hours:    ~{remaining_hours}h estimated remaining
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## LOOP START — repeat for each task

### Phase 1: Pick Next Task

Re-read the planning doc Appendix (it may have been updated by the previous iteration). Find the first `[ ]` task whose dependencies are all satisfied (`[x]` status or no dependencies).

**If no `[ ]` tasks remain** → go to LOOP END (all done)

**If `[ ]` tasks exist but none have satisfied deps** → go to LOOP END (blocked)

Print and proceed without pausing:
```
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

Launch a **general-purpose Agent** subagent that runs the full `/dev-task` pipeline in merge-mode. Do NOT run any git commands or planning doc edits in the main context — everything happens inside the subagent via `/dev-task --merge` (which handles mark-in-progress, branch setup, implementation, PR, review, and merge).

**Launch subagent** with this prompt:

```
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

Wait for the subagent to complete.

---

### Phase 3: Task Complete — Loop Back

After the subagent completes, re-read the planning doc to confirm the task is marked `[x]`.

Print a brief completion line and **immediately loop back to Phase 1**:

```
✓ {task-id}: {task title} — merged ({done_count}/{total_count})
```

→ **Go to Phase 1** (pick next task)

---

## LOOP END

When the loop exits, print the final summary:

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

### Permission Cleanup

Check if `.claude/pipeline-permissions-added.json` exists. If it does:

1. Read the `added` array — these are permissions that `/plan-session` added for this pipeline run
2. Present them to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PERMISSION CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/plan-session added these permissions for
the dev pipeline. Roll back?

  - {permission 1}
  - {permission 2}
  - ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

3. Ask: "Remove these pipeline permissions from `.claude/settings.local.json`? (Yes / Keep all / Pick which to keep)"
4. If removing: delete matching entries from `settings.local.json`, then delete `.claude/pipeline-permissions-added.json`
5. If keeping: just delete `.claude/pipeline-permissions-added.json`

If the file doesn't exist, skip this step silently.

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
| Between tasks | No | **Loops automatically** |
| All other steps | No | Fully autonomous |
