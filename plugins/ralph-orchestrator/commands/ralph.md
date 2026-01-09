---
name: ralph
description: Start an orchestrated Ralph loop with full scaffolding. Supports PRD-based execution (from /prd), plan-based execution (from /ralph-freeform), or raw freeform prompts. Includes progress tracking, TDD guidance, verification steps, and escape hatches.
---

# Ralph Orchestrator

Start a structured Ralph loop with progress tracking, TDD guidance, and escape hatches.

**Arguments**: $ARGUMENTS

Parse the arguments to extract:
- `<task-name>` or `<freeform-prompt>` - Required, first positional argument
- `--max-iterations N` - Optional, defaults to 50
- `--story US-XXX` - Optional, start with specific story (PRD mode)
- `--phase P1` - Optional, start with specific phase (Plan mode)
- `--freeform` - Optional, force raw freeform mode even if PRD/plan exists

## Workflow

### Step 1: Determine Input Mode

Check for existing task files:

```bash
# Check for PRD or Plan files
ls .claude/ralph/<task-name>/prd.json 2>/dev/null
ls .claude/ralph/<task-name>/plan.json 2>/dev/null
```

**Mode A: PRD-based** (if prd.json exists and --freeform not specified):
- Read `.claude/ralph/<task-name>/prd.json`
- Use structured story-based execution
- Completion promise: "ALL STORIES PASS"

**Mode B: Plan-based** (if plan.json exists and --freeform not specified):
- Read `.claude/ralph/<task-name>/plan.json`
- Use phase-based execution (created via `/ralph-freeform`)
- Completion promise: "ALL PHASES COMPLETE"

**Mode C: Raw Freeform** (if no PRD/plan or --freeform flag):
- Use the provided text as the task description
- Create minimal working files
- Completion promise: "TASK COMPLETE"

### Step 2: Initialize Working Files

Create working directory if needed:
```bash
mkdir -p .claude/ralph/<task-name>/
```

**For PRD mode or Plan mode**, ensure these files exist (create from templates if not):

1. Read existing progress.md or create from template:
   - Template: `skills/ralph-orchestrator/assets/templates/progress_template.md`
   - Location: `.claude/ralph/<task-name>/progress.md`

2. Read existing AGENTS.md or create from template:
   - Template: `skills/ralph-orchestrator/assets/templates/agents_template.md`
   - Location: `.claude/ralph/<task-name>/AGENTS.md`

**For Raw Freeform mode**, create minimal files:

1. Create progress.md with:
   ```markdown
   # Progress: <task-name>

   **Started**: <timestamp>
   **Current Iteration**: 0
   **Mode**: freeform

   ## Learnings (append-only)

   ## Current State

   **Working on**: Not started
   **Blockers**: none
   **Last verification**: not yet run

   ## Iteration History
   ```

2. Create minimal AGENTS.md:
   ```markdown
   # AGENTS.md - <task-name>

   **Task**: <task-name>
   **Created**: <timestamp>

   ## Task Description

   <freeform prompt text>

   ## Discovered Patterns

   ## Commands Reference
   ```

### Step 3: Build Master Prompt

Invoke the ralph-orchestrator skill to build the complete master prompt:

```
Use the ralph-orchestrator skill to build the master prompt for:
- Task: <task-name>
- Mode: <prd|plan|freeform>
- Max iterations: <from --max-iterations or 50>
- Focus story: <from --story or first incomplete> (PRD mode)
- Focus phase: <from --phase or first incomplete> (Plan mode)
```

The skill will:
1. Read prd.json (PRD mode), plan.json (Plan mode), or parse raw prompt
2. Read current state from progress.md
3. Build structured prompt with all scaffolding
4. Return the complete master prompt

### Step 4: Confirm with User

Before starting the loop, confirm:

```
Ready to start Ralph loop!

**Task**: <task-name>
**Mode**: <PRD-based | Plan-based | Raw Freeform>
**Max iterations**: <N>
**Completion promise**: "<promise>"

**Stories** (PRD mode only):
- [ ] US-001: <title>
- [ ] US-002: <title>
- [x] US-003: <title> (already passing)

**Phases** (Plan mode only):
- [ ] P1: <phase name>
- [ ] P2: <phase name>
- [x] P3: <phase name> (already complete)

**Working files**:
- .claude/ralph/<task-name>/progress.md
- .claude/ralph/<task-name>/AGENTS.md
- .claude/ralph/<task-name>/prd.json (PRD mode)
- .claude/ralph/<task-name>/plan.json (Plan mode)
- ./CLAUDE.md (project root - receives promoted patterns)

**To cancel the loop once started**: /cancel-ralph

Start the loop now? (The loop will run until completion or max iterations)
```

Wait for user confirmation.

### Step 5: Invoke Ralph Loop

Once confirmed, invoke the official ralph-loop command:

**For PRD mode**:
```
/ralph-loop "<master-prompt>" --max-iterations <N> --completion-promise "ALL STORIES PASS"
```

**For Plan mode**:
```
/ralph-loop "<master-prompt>" --max-iterations <N> --completion-promise "ALL PHASES COMPLETE"
```

**For Raw Freeform mode**:
```
/ralph-loop "<master-prompt>" --max-iterations <N> --completion-promise "TASK COMPLETE"
```

The ralph-loop plugin will:
- Feed the prompt to Claude
- Intercept exit attempts
- Re-feed the same prompt
- Continue until completion promise detected or max iterations

## Options Reference

| Option | Description | Default |
|--------|-------------|---------|
| `--max-iterations N` | Stop after N iterations | 50 |
| `--story US-XXX` | Start with specific story (PRD mode) | First incomplete |
| `--phase P1` | Start with specific phase (Plan mode) | First incomplete |
| `--freeform` | Force raw freeform mode | Auto-detect |

## Examples

**Start PRD-based loop** (after running /prd):
```
/ralph todo-api
```

**Start Plan-based loop** (after running /ralph-freeform):
```
/ralph health-endpoint
```

**Start with iteration limit**:
```
/ralph todo-api --max-iterations 30
```

**Start from specific story** (PRD mode):
```
/ralph todo-api --story US-003
```

**Start from specific phase** (Plan mode):
```
/ralph health-endpoint --phase P2
```

**Raw freeform task** (no PRD or plan):
```
/ralph "Add a health check endpoint that returns {status: ok}" --freeform --max-iterations 10
```

## Monitoring the Loop

While the loop runs:
- Watch progress in `.claude/ralph/<task-name>/progress.md`
- Check story status in `.claude/ralph/<task-name>/prd.json` (PRD mode)
- Check phase status in `.claude/ralph/<task-name>/plan.json` (Plan mode)
- Review patterns in `.claude/ralph/<task-name>/AGENTS.md`
- Check project-wide patterns promoted to `./CLAUDE.md`
- Monitor git commits for progress

## CLAUDE.md Updates

During the loop, Claude will update two pattern files with different purposes:

**AGENTS.md** (task-specific):
- Located in `.claude/ralph/<task-name>/AGENTS.md`
- Contains patterns specific to this task
- Includes architectural decisions for this feature
- Stays with the task working files

**CLAUDE.md** (project-wide):
- Located in project root `./CLAUDE.md`
- Receives patterns that apply across the entire project
- Updated when Claude discovers project-wide conventions
- Persists beyond this task for future work

Patterns are promoted from AGENTS.md to CLAUDE.md when they:
- Apply to the whole project (naming conventions, structure)
- Represent gotchas future tasks should know about
- Establish architectural decisions affecting multiple features

## Canceling the Loop

To stop the loop before completion:
```
/cancel-ralph
```

This will:
- Stop the current iteration
- Preserve all progress in working files
- Allow resuming later with `/ralph <task-name>`

## Resuming a Loop

If a loop was canceled or hit max iterations:
```
/ralph <task-name>
```

The skill will:
- Read existing progress.md to understand state
- Continue from where you left off
- Preserve all learnings from previous sessions
