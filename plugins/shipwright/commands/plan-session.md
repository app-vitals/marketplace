---
description: Engineer planning pass — reads the product spec, explores the codebase, flags complexity, and produces a task queue
arguments:
  - name: repo
    description: The repo to plan work for (e.g., vitals-os)
    required: true
  - name: session
    description: A short slug for this planning session (e.g., may-billing-refactor). Used to group tasks and PRs.
    required: true
---

# Plan Session: $ARGUMENTS

Parse `$ARGUMENTS` to extract:
- **repo**: first argument
- **session**: second argument

This is the engineering planning pass. The product spec (what and why) is already done — either from `/brainstorm` or handed in directly. This session translates that spec into a concrete technical design and task queue.

**Input:** `planning/{session}/PRODUCT-SPEC.md` (or a verbal description if no spec exists)
**Output:** Tasks in `state/todos.json`, ready for `dev-task` to execute

---

## Step 1: Load Context

1. Read `CLAUDE.md` in the repo worktree if available, otherwise read from `~/src/{repo}/`
2. Glob the repo structure to understand the codebase layout
3. Read `state/todos.json` — check for any existing tasks in this session to avoid duplicates
4. Read `planning/{session}/PRODUCT-SPEC.md` if it exists — this is the primary input

Present a brief orientation:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN SESSION: {session}
Repo: {repo}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Spec: {found / not found}
{If found: 1-2 sentences summarizing what's being built}
{If not found: "No PRODUCT-SPEC.md found — I'll ask for a description."}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If no spec exists, ask: **"What are we building?"** and collect enough to proceed. Keep it brief — this is an engineering session, not a discovery session.

---

## Step 2: Explore the Codebase

Map the spec to the codebase across four layers. For each layer that the spec touches:

**Business logic** — find where the relevant rules/behaviors currently live; identify what's new vs. what's changing
**Views/UX** — find the affected components or pages; understand the current rendering patterns
**APIs** — find the relevant endpoints and their handlers; note request/response shapes that will change
**DB** — find the schema files and any existing migrations; understand the current data model

For each layer:
1. Read the files most likely affected
2. Look for existing patterns to reuse (functions, types, abstractions)
3. Identify what's NEW vs what's a MODIFICATION

**Flag complexity risks as you go** — call these out before proposing a design:
- Tightly coupled code that's hard to extend without broader refactoring
- Missing abstractions that would need to be built first
- Features that look simple in the spec but are disproportionately complex in the code
- Cross-layer dependencies that constrain the order of implementation
- Anything in the spec that would introduce unjustified complexity — surface it and suggest a simpler alternative

Example flags:
- "⚠ This touches the auth middleware which is shared across all routes — higher risk than it appears"
- "⚠ The spec adds X to the billing API but the billing service has no test coverage — any change here is risky without tests first"
- "⚠ This feature requires a new abstraction that doesn't exist yet — adds ~2h of foundational work before the feature itself"

---

## Step 3: Research (if needed)

If the implementation approach isn't clear from the codebase, do a web search:
- What are the common approaches to this problem?
- Are there libraries that handle this, or is custom code the right call?

Bias toward the simplest solution that fits existing patterns. Summarize findings before moving to design.

---

## Step 4: Propose a Design

Present a concrete technical design organized by layer:

**Business logic** — what rules/behaviors are added or changed and where they live in the code
**Views/UX** — what components or pages change and how
**APIs** — what endpoints change, what request/response shapes look like
**DB** — schema changes, migration approach

Also include:
- Specific files that will change
- How it integrates with existing patterns
- Any complexity risks from Step 2 and how the design addresses (or explicitly accepts) them
- What gets tested and how

Keep it simple. If two approaches exist, recommend one and explain why.

Iterate on feedback. Do not move to task breakdown until the design is approved.

---

## Step 5: Task Breakdown

Break the approved design into tasks. Each task should be independently shippable (its own PR).

For each task:
- **ID**: `{PREFIX}-{N}.{M}` — prefix is 2-3 letters from the feature name
- **Title**: short, verb-first (e.g., "Add billing schema migration")
- **Description**: what to build, not how
- **Acceptance Criteria**: 2-5 bullet points — specific, testable
- **Dependencies**: which tasks must be `merged` first (task IDs or empty)
- **Branch**: `feat/{id-lowered-dashes}-{first-3-words-kebab}`
- **Layer**: API | Frontend | Database | Shared | Background | CLI
- **Hours**: rough estimate (1-8h; break tasks larger than 8h)

### Dependency Map

Present the map in two forms:

**1. Visual graph:**
```
[START]
  ├─ {PREFIX}-1.1: {title} (no deps)
  └─ {PREFIX}-1.2: {title} (no deps)
        └─ {PREFIX}-2.1: {title} (needs 1.1, 1.2)
              └─ {PREFIX}-2.2: {title} (needs 2.1)
```

**2. Summary table:**
```
Task         | Depends on  | Blocks
{PREFIX}-1.1 | —           | 2.1
{PREFIX}-1.2 | —           | 2.1
{PREFIX}-2.1 | 1.1, 1.2    | 2.2
{PREFIX}-2.2 | 2.1         | —
```

Present the task list and dependency map as a first pass. The engineer reviews and iterates — they may catch implementation details, missing edge cases, or better task splits. Iterate until approved.

---

## Step 6: Write to Queue

Once the task breakdown is approved, write each task to `state/todos.json`.

Read the current `state/todos.json` first. Append the new tasks — do not overwrite existing entries.

Each task entry:

```json
{
  "id": "{PREFIX}-{N}.{M}",
  "source": "shipwright",
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
