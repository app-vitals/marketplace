---
description: Kick off a planning session with Bodhi — explore the problem, research solutions, and queue tasks for execution
arguments:
  - name: repo
    description: The repo to plan work for (e.g., vitals-os)
    required: true
  - name: session
    description: A short slug for this planning session (e.g., may-billing-refactor). Used to group tasks and PRs.
    required: true
---

# Plan: $ARGUMENTS

Parse `$ARGUMENTS` to extract:
- **repo**: first argument
- **session**: second argument

This is a conversational planning session. Work through the problem with the user. Do not rush to a task breakdown — understand the problem first, then design the solution, then produce tasks.

---

## Step 1: Load Context

Before asking any questions, load context:

1. Read `CLAUDE.md` in the repo worktree if available, otherwise read from `~/src/{repo}/`
2. Glob the repo structure to understand the codebase layout (top-level directories, key files)
3. Read `state/todos.json` — check for any existing tasks in this session to avoid duplicates
4. Check `planning/{session}/` — if a planning folder exists, read any docs there

Present a brief orientation:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLANNING SESSION: {session}
Repo: {repo}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{1-2 sentences on what you found: key layers, recent activity, any existing tasks for this session}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then ask: **"What's the problem we're solving?"**

---

## Step 2: Understand the Problem

Listen to the user's description. Ask clarifying questions until you can answer:

- What's broken or missing?
- Who's affected and how?
- What does done look like?
- Are there constraints (performance, backwards compatibility, deadline)?

Do not move to solution design until the problem is clear. It's better to ask one more question than to build the wrong thing.

---

## Step 3: Explore the Codebase

With the problem understood, explore the relevant code:

1. Find the files most likely affected — read them
2. Look for existing patterns that solve similar problems (search for related functions, types, API shapes)
3. Check for prior art: similar features already in the codebase that can be extended or reused
4. Identify what's NEW vs what's a MODIFICATION of existing code

Surface what you find:
- "This looks like it extends X in `src/billing/...`"
- "There's already a pattern for Y in `src/api/...` we can follow"
- "This would require a new table — here's how the existing schema is structured"

---

## Step 4: Research (if needed)

If the problem involves external patterns, libraries, or approaches that aren't obvious from the codebase, do a web search:

- What are the common approaches to this problem?
- What do popular projects in this ecosystem do?
- Are there libraries that handle this, or is custom code the right call?

Bias toward **the simplest solution that fits the existing codebase patterns**. Novel approaches have a cost — they require more context, more documentation, and more review. Only recommend something new if the simpler path has a genuine limitation.

Summarize your research findings to the user before moving to design.

---

## Step 5: Propose a Design

Present a concrete design — not a vague direction, a specific plan:

- What files will change
- What new code will be added
- What the data model looks like (if applicable)
- How it integrates with existing patterns
- What gets tested and how

Keep it simple. If two approaches exist, recommend one and explain why. The user can push back.

Iterate on feedback. Don't move to task breakdown until the user has signed off on the design.

---

## Step 6: Task Breakdown

Break the approved design into tasks. Each task should be independently shippable (its own PR).

For each task, determine:
- **ID**: `{PREFIX}-{N}.{M}` — prefix is 2-3 letters from the feature name
- **Title**: short, verb-first (e.g., "Add billing schema migration")
- **Description**: what to build, not how
- **Acceptance Criteria**: 2-5 bullet points — specific, testable
- **Dependencies**: which tasks must be `merged` first (task IDs or empty)
- **Branch**: `feat/{id-lowered-dashes}-{first-3-words-kebab}`
- **Layer**: API | Frontend | Database | Shared | Background | CLI
- **Hours**: rough estimate (1-8h; break tasks larger than 8h)

### Dependency Map

After listing all tasks, draw the dependency map explicitly. Tasks with no dependencies are the starting point. The execution cron uses this to know what's ready to run.

Present the full task list and dependency map to the user for review. Iterate until approved.

---

## Step 7: Write to Queue

Once the user approves the task breakdown, write each task to `state/todos.json`.

Read the current `state/todos.json` first. Append the new tasks — do not overwrite existing entries.

Each task entry:

```json
{
  "id": "{PREFIX}-{N}.{M}",
  "source": "shipwright-lite",
  "session": "{session}",
  "repo": "{repo}",
  "title": "...",
  "description": "...",
  "acceptanceCriteria": ["...", "..."],
  "layer": "API | Frontend | Database | Shared | Background | CLI",
  "branch": "feat/...",
  "dependencies": [],
  "status": "pending",
  "pr": null,
  "addedAt": "{ISO timestamp}",
  "hours": 2
}
```

Write the updated todos.json.

Confirm with:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
QUEUED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Session: {session}
Tasks queued: {count}

READY TO START (no dependencies):
{list tasks with no deps}

BLOCKED (waiting on deps):
{list tasks with deps → what they're waiting on}

The execution cron will pick up ready tasks automatically.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Notes

- Planning is a conversation, not a ceremony. Skip steps that don't apply.
- If the user already has a design in mind, go straight to task breakdown.
- If the problem is obvious and the solution is clear, move fast — don't manufacture process.
- The goal is a queue of well-defined, independently-shippable tasks. That's it.
