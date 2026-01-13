# Ralph Freeform & Ralph Loop Guide

A practical guide to using `/ralph-freeform` and `/ralph` for autonomous development loops in Claude Code.

---

## What Problem Does This Solve?

When working on multi-step tasks, it's easy to lose track of progress, forget what you've tried, or get stuck in loops. The Ralph system provides:

- **Structured planning** before diving into implementation
- **Persistent memory** across iterations (file-based, not in-context)
- **Automatic escape hatches** when stuck
- **Clear completion criteria** so the loop knows when to stop

---

## The Two Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/ralph-freeform` | Create a structured plan | Before starting work |
| `/ralph` | Execute the plan in a loop | After plan is ready |

**Workflow**: `/ralph-freeform` → review plan → `/ralph`

---

## What is /ralph-freeform?

`/ralph-freeform` is an interactive planning command that helps you create a structured plan before starting autonomous work. It asks clarifying questions, generates phases, and outputs both human-readable and machine-readable plan files.

### Three Task Types

When you run `/ralph-freeform`, the first question is always:

    What type of task is this?

    A) Code Implementation (default) - Write or modify code, fix bugs, add features
    B) Analysis/Documentation - Research, estimate, document, or produce a written deliverable
    C) Investigation/Debugging - Find root cause of an issue, explore unknowns

Each task type has a different question flow and generates phases tailored to that kind of work.

### Output Files

After completing the Q&A flow, `/ralph-freeform` creates:

| File | Format | Purpose |
|------|--------|---------|
| `PLAN.md` | Markdown | Human-readable plan you can review and edit |
| `plan.json` | JSON | Machine-readable status tracking for `/ralph` |

Both are stored in `.claude/ralph/<task-name>/`.

### When to Use /ralph-freeform vs /prd

| Use `/ralph-freeform` | Use `/prd` |
|----------------------|------------|
| Single goal/feature | Multiple features |
| 2-5 phases of work | 5+ user stories |
| Simpler verification | Complex acceptance criteria |
| "Add a health endpoint" | "Build authentication system" |
| "Fix the login bug" | "Implement user management" |
| "Create cost estimate" | "Multi-phase project planning" |

---

## Use Cases

### Code Implementation

**Example tasks:**
- "Add a /health endpoint that returns server status"
- "Fix the bug where login fails on mobile Safari"
- "Add input validation to the user registration form"
- "Refactor the authentication middleware"

**Typical phases:**
1. Understand current setup
2. Implement the feature
3. Add tests
4. Final verification

### Analysis/Documentation

**Example tasks:**
- "Create a cost estimate for 3 new features"
- "Write architecture documentation for the auth system"
- "Produce a technical comparison of two approaches"
- "Create sprint planning breakdown with story points"

**Typical phases:**
1. Gather and review input materials
2. Analyze each major area
3. Draft document structure and content
4. Review and finalize deliverable

### Investigation/Debugging

**Example tasks:**
- "Investigate intermittent login failures on iOS"
- "Debug memory leak in the worker process"
- "Understand how the face matching pipeline works"
- "Find root cause of API performance degradation"

**Typical phases:**
1. Reproduce or observe the issue
2. Form and test hypotheses
3. Confirm root cause with evidence
4. Document findings (and optionally fix)

---

## Step-by-Step Example

This section walks through a real session creating a documentation task.

### 1. Start the Freeform Workflow

    /ralph-freeform

The system first gathers context about your project (config files, MCP servers, etc.).

### 2. Select Task Type

    What type of task is this?

    A) Code Implementation (default)
    B) Analysis/Documentation
    C) Investigation/Debugging

**Selection:** B (Analysis/Documentation)

### 3. Answer Clarifying Questions

The system asks questions one at a time:

**Task Name:**

    What should I call this task?

Answer: ralph-presentation

**Deliverable:**

    What document or deliverable are you producing?

Answer: "A presentation for the marketplace repo explaining how to use ralph-freeform and ralph loop"

**Required Sections:**

    What sections or information MUST be included?

Answer: "What ralph-freeform is, examples of use cases, step-by-step example, how to use results with ralph loop"

**Input Sources:**

    What materials need to be analyzed?

Answer: "The plugin codebase plus the conversation session as a live example"

**Verification Method:**

    How will completion be validated?

Answer: D (Self-review against criteria)

**Out of Scope:**

    Anything that should NOT be included?

Answer: "Deep dive into /prd - mention only"

### 4. Review Generated Plan

The system generates phases and presents them for review:

    ## Phases

    ### P1: Gather and Review Source Materials
    Steps:
    - Read ralph-freeform command definition
    - Read ralph command definition
    - Review SKILL.md and templates
    - Note key concepts, workflow steps, file outputs
    Verify: Have notes on all key components

    ### P2: Outline Presentation Structure
    Steps:
    - Define section order and flow
    - Identify key snippets from this session
    - Plan visual hierarchy
    Verify: Have complete outline

    ... (additional phases)

    Would you like to:
    1. Approve this plan as-is
    2. Add/remove phases
    3. Adjust steps within a phase

### 5. Approve the Plan

    approve the plan

The system creates the working directory and files:

    Plan created successfully!

    Location: .claude/ralph/ralph-presentation/
    Files:
      - PLAN.md (human-readable)
      - plan.json (machine-readable)

    To start the Ralph loop:
      /ralph ralph-presentation

### 6. Generated PLAN.md Structure

    # Plan: ralph-presentation

    **Created**: 2026-01-13T10:30:00Z
    **Status**: draft
    **Type**: freeform
    **Task Type**: documentation

    ## Deliverable

    A presentation for the marketplace repo...

    ## Success Criteria

    - [ ] Explains what ralph-freeform is and its purpose
    - [ ] Provides clear use case examples
    - [ ] Includes step-by-step walkthrough
    - [ ] Shows how to take plan output into ralph loop

    ## Phases

    ### P1: Gather and Review Source Materials
    **Steps**:
    - [ ] Read ralph-freeform command definition
    - [ ] Read ralph command definition
    ...
    **Verify**: Have notes on all key components
    **Status**: pending

### 7. Generated plan.json Structure

    {
      "name": "ralph-presentation",
      "status": "draft",
      "type": "plan",
      "task_type": "documentation",
      "goal": "Create a presentation...",
      "success_criteria": ["..."],
      "phases": [
        {
          "id": "P1",
          "name": "Gather and Review Source Materials",
          "steps": ["..."],
          "verification": "Have notes on all key components",
          "complete": false,
          "notes": ""
        }
      ]
    }

---

## From Plan to Ralph Loop

### Starting the Loop

Once your plan is ready, start the loop:

    /ralph ralph-presentation

The system detects your plan.json and shows a confirmation:

    Ready to start Ralph loop!

    **Task**: ralph-presentation
    **Mode**: Plan-based
    **Max iterations**: 50
    **Completion promise**: ALL PHASES COMPLETE

    **Phases**:
    - [ ] P1: Gather and Review Source Materials
    - [ ] P2: Outline Presentation Structure
    - [ ] P3: Draft 'What is ralph-freeform' Section
    ...

    Start the loop now?

### How the Loop Works

Ralph loops use **file-based memory**. Each iteration:

1. Claude receives the same master prompt
2. Claude reads state files (progress.md, plan.json)
3. Claude works on the current phase
4. Claude updates state files with progress
5. Loop continues until completion promise detected

**Key insight:** Claude doesn't remember previous iterations through context. Memory persists through files on disk:

| File | Purpose |
|------|---------|
| progress.md | Append-only learnings, current state, iteration history |
| plan.json | Phase completion status |
| AGENTS.md | Task-specific patterns discovered |

### Monitoring Progress

While the loop runs, you can:

- Watch progress in `.claude/ralph/<task-name>/progress.md`
- Check phase status in plan.json
- Review patterns in AGENTS.md
- Monitor git commits for code progress

### Completion and Escape Hatches

**Normal completion:** When all phases are done, Claude outputs:

    <promise>ALL PHASES COMPLETE</promise>

**Escape hatches:** If stuck after 3 attempts on the same issue:
1. Document the blocker in progress.md
2. Try one alternative approach
3. If still stuck, mark phase as blocked and move to next
4. Never output false completion promise

**Canceling:** To stop early, use /cancel-ralph

---

## Quick Reference

### Commands

| Command | Description |
|---------|-------------|
| `/ralph-freeform` | Create a structured plan |
| `/ralph <task-name>` | Start the loop for a planned task |
| `/ralph <task> --max-iterations 20` | Limit iterations |
| `/ralph <task> --phase P2` | Start from specific phase |
| `/cancel-ralph` | Stop the current loop |

### Key Files

| File | Location | Purpose |
|------|----------|---------|
| PLAN.md | .claude/ralph/<task>/ | Human-readable plan |
| plan.json | .claude/ralph/<task>/ | Machine-readable status |
| progress.md | .claude/ralph/<task>/ | Iteration history, learnings |
| AGENTS.md | .claude/ralph/<task>/ | Task-specific patterns |

### Tips for Success

1. **Be specific in your goal** - Vague goals lead to vague results
2. **Keep phases small** - Each should be completable in 1-2 iterations
3. **Use testable success criteria** - "It works" is not testable
4. **Review before starting** - Edit PLAN.md if phases need adjustment
5. **Let escape hatches work** - Better to skip a blocked phase than spin forever

### Completion Promises

| Mode | Promise |
|------|---------|
| Plan-based | `<promise>ALL PHASES COMPLETE</promise>` |
| PRD-based | `<promise>ALL STORIES PASS</promise>` |
| Raw freeform | `<promise>TASK COMPLETE</promise>` |
