---
description: Refresh stale planning doc tasks against the current codebase — verify file paths, update dependencies, and regenerate context
arguments:
  - name: folder-name
    description: Planning session folder name under planning/ (e.g., february-2026-workspace-switcher)
    required: true
---

# Refresh Plan: $ARGUMENTS

Refresh a planning doc's stale tasks against the current codebase state. Preserves stable sections (descriptions, acceptance criteria) and updates sections that reference code (file paths, technical details, dependency statuses).

Follow all steps in order.

## Step 1: Load Planning Doc

1. Search for `planning/$ARGUMENTS/*_Task_Breakdown.md`
2. If not found, also try `planning/**/*_Task_Breakdown.md` and match against the folder name
3. If still not found, tell the user: "No task breakdown doc found in planning/$ARGUMENTS/. Check the folder name and try again." and stop.
4. Read the full document
5. Parse the Appendix to build a status summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLANNING DOC STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document: {filename}
Tasks:    {total} total
  [ ]  Not started: {count}
  [🔨] In-progress: {count}
  [x]  Done:        {count}
  [⏸]  Blocked:     {count}
  [—]  Skipped:     {count}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Identify Stale Tasks

Find all `[ ]` (not started) tasks. These are the candidates for refresh — completed and in-progress tasks are left as-is.

List the stale tasks by ID and title.

## Step 3: Verify Each Stale Task

For each `[ ]` task:

### A. File Path Verification
For each file listed in the task's **Technical Details → Location:**
1. Check if the file exists at the listed path using Glob
2. If the file has moved or been renamed, search for it by filename
3. Categorize: **Exists** (at listed path), **Moved** (found elsewhere), **To create** (doesn't exist yet — keep it), **Stale** (path wrong, no match found — remove it)

### B. Dependency Status Check
For each dependency listed:
1. Look up its current status in the Appendix
2. Flag if a dependency has been completed since the doc was last updated — the stale task may need context adjustments

### C. Technical Detail Validation
1. If file paths in Location are stale, update them
2. Check if completed tasks (`[x]`) have already implemented patterns or types this task depends on — note what now exists vs. what still needs to be built
3. Check if the acceptance criteria are already partially met by completed work

### D. Context Regeneration
If the task's **Context** field references things that have changed (e.g., "before X is built" when X is now done), regenerate the context from the current feature Overview and completed task state.

## Step 4: Regenerate

For each stale task that needs updates, prepare the changes:

1. Update **Technical Details → Location** with corrected file paths
2. Update **Context** field if stale
3. Add a note to any acceptance criteria that are already met: `(already implemented by {TASK-ID})`
4. Update **Dependencies** status references if they've changed

## Step 5: Show Changes & Confirm

Display a before/after comparison:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN REFRESH: {doc title}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TASKS REVIEWED: {count} stale tasks checked
TASKS UPDATED:  {count} tasks with changes

{For each updated task:}
─── {TASK-ID}: {title} ───
{List specific changes:}
- Location: {old path} → {new path}
- Context: updated (deps completed since last refresh)
- AC: {criterion} — already met by {DEP-ID}

NO CHANGES NEEDED: {count} tasks still current

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Pause point:** Ask the user to confirm, edit, or skip the update.
- "Apply update" — write changes to the planning doc
- "Edit first" — ask what they want to change, apply edits, re-show summary
- "Skip" — stop without modifying the doc

## Step 6: Apply & Commit

If the user approved:

1. Write all changes to the planning doc
2. Commit: `chore: refresh planning doc for $ARGUMENTS`

Print the completion block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN REFRESHED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document: {filename}
Tasks updated: {count}

AVAILABLE TASKS
───────────────
{List [ ] tasks with all deps satisfied:}
- {PREFIX-N.M}: {task title} ({hours}h)

NEXT: /dev-task {first-available-task-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
