# Phase-Isolated Feature Development Plugin

A custom Claude Code plugin that combines the structured workflow of `feature-dev` with the persistent iteration of `ralph-wiggum`, designed to work around token context window limits.

## Problem Statement

The `feature-dev` plugin provides excellent structured workflows but can exhaust the 200k token window on complex features (see [issue #15849](https://github.com/anthropics/claude-code/issues/15849)). The `ralph-wiggum` plugin enables persistent iteration but compounds the token problem when wrapping long workflows.

**Solution:** Break feature development into discrete phases with explicit session boundaries, persisting only distilled outputs between phases.

---

## Architecture Overview

### Directory Structure

```
phase-feature-dev/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── feature-start.md        # Initialize feature, create state file
│   ├── feature-continue.md     # Resume from last checkpoint
│   ├── feature-status.md       # Show progress across phases
│   └── feature-reset.md        # Reset a phase for re-work
├── agents/
│   ├── requirements-agent.md   # Phase 1: Gather and clarify requirements
│   ├── explorer-agent.md       # Phase 2: Analyze existing codebase
│   ├── architect-agent.md      # Phase 3: Design implementation approach
│   ├── implementer-agent.md    # Phase 4: Write the code
│   ├── reviewer-agent.md       # Phase 5: Review and identify issues
│   ├── tester-agent.md         # Phase 6: Write and run tests
│   └── documenter-agent.md     # Phase 7: Update documentation
├── hooks/
│   └── stop-hook.sh            # Phase-aware ralph-style iteration
├── scripts/
│   ├── state-manager.sh        # Read/write feature state
│   └── checkpoint.sh           # Save phase outputs
├── templates/
│   ├── feature-state.md        # Template for state tracking
│   ├── requirements.md         # Template for requirements output
│   ├── exploration.md          # Template for exploration output
│   └── architecture.md         # Template for architecture output
├── skills/
│   └── phase-workflow.md       # Skill doc explaining the workflow
└── README.md
```

---

## Token Management Strategy

### Session Boundaries Between Phases

```
Phase 1: Requirements    ──┐
   (ralph loop ≤10 iter)   │ Session 1 (~20-40k tokens)
   → writes REQUIREMENTS.md┘
         ↓
   [SESSION BOUNDARY - context resets]
         ↓
Phase 2: Exploration     ──┐
   (ralph loop ≤10 iter)   │ Session 2 (~30-50k tokens)
   → reads REQUIREMENTS.md │
   → writes EXPLORATION.md ┘
         ↓
   [SESSION BOUNDARY - context resets]
         ↓
Phase 3: Architecture    ──┐
   (ralph loop ≤15 iter)   │ Session 3 (~40-60k tokens)
   → reads prior artifacts │
   → writes ARCHITECTURE.md┘
         ↓
   [SESSION BOUNDARY - context resets]
         ↓
Phase 4: Implementation  ──┐
   (ralph loop ≤25 iter)   │ Session 4 (~60-100k tokens)
   → reads ARCHITECTURE.md │
   → implements feature    ┘
         ↓
   [SESSION BOUNDARY - context resets]
         ↓
Phase 5: Review          ──┐
   (ralph loop ≤10 iter)   │ Session 5 (~30-50k tokens)
   → reviews implementation│
   → writes REVIEW.md      ┘
         ↓
   [SESSION BOUNDARY - may loop back to Phase 4]
         ↓
Phase 6: Testing         ──┐
   (ralph loop ≤15 iter)   │ Session 6 (~40-60k tokens)
   → writes and runs tests ┘
         ↓
Phase 7: Documentation   ──┐
   (ralph loop ≤5 iter)    │ Session 7 (~15-25k tokens)
   → updates docs          ┘
```

Each session starts with only **distilled artifacts** from prior phases, not conversation history.

### Token Budget Per Phase

| Phase | Max Iterations | Estimated Token Budget | Rationale |
|-------|---------------|------------------------|-----------|
| Requirements | 10 | 20-40k | Mostly conversation, clarification |
| Exploration | 10 | 30-50k | Reading existing code, summarizing |
| Architecture | 15 | 40-60k | Design decisions, may need iteration |
| Implementation | 25 | 60-100k | Largest phase, actual code writing |
| Review | 10 | 30-50k | Analysis, may trigger re-implementation |
| Testing | 15 | 40-60k | Test code, running, fixing |
| Documentation | 5 | 15-25k | Usually straightforward |

---

## State Management

### Feature State File

Location: `.claude/features/<feature-slug>/state.md`

```markdown
# Feature State: <feature-name>

## Metadata
- **Feature ID:** <slug>
- **Description:** <one-line description>
- **Created:** <ISO timestamp>
- **Last Updated:** <ISO timestamp>
- **Current Phase:** PHASE_3_ARCHITECTURE
- **Status:** IN_PROGRESS | BLOCKED | COMPLETE

## Phase Progress
- [x] PHASE_1_REQUIREMENTS (completed: 2026-01-26T10:30:00Z, iterations: 3)
- [x] PHASE_2_EXPLORATION (completed: 2026-01-26T11:45:00Z, iterations: 7)
- [ ] PHASE_3_ARCHITECTURE (started: 2026-01-26T14:00:00Z, iteration: 4/15)
- [ ] PHASE_4_IMPLEMENTATION
- [ ] PHASE_5_REVIEW
- [ ] PHASE_6_TESTING
- [ ] PHASE_7_DOCUMENTATION

## Artifacts
| Phase | File | Status |
|-------|------|--------|
| Requirements | ./REQUIREMENTS.md | ✓ Complete |
| Exploration | ./EXPLORATION.md | ✓ Complete |
| Architecture | ./ARCHITECTURE.md | In Progress |
| Implementation | (code files) | Pending |
| Review | ./REVIEW.md | Pending |
| Testing | ./TESTING.md | Pending |
| Documentation | ./DOCS.md | Pending |

## Current Phase Context
<!-- Compact summary for session handoff - kept under 2000 tokens -->

### Key Decisions Made
- Decision 1: <brief description>
- Decision 2: <brief description>

### Open Questions
- Question 1: <needs resolution in current phase>

### Blockers
- None | <description of blocker>

## Session History
| Session | Phase | Iterations | Tokens Used | Outcome |
|---------|-------|------------|-------------|---------|
| 1 | Requirements | 3 | ~25k | Complete |
| 2 | Exploration | 7 | ~42k | Complete |
| 3 | Architecture | 4 | ~35k | In Progress |
```

### Artifact Templates

Each phase produces a structured markdown artifact that the next phase consumes.

**REQUIREMENTS.md structure:**
```markdown
# Requirements: <feature-name>

## Summary
<2-3 sentence description>

## Functional Requirements
1. <requirement>
2. <requirement>

## Non-Functional Requirements
- Performance: <constraints>
- Security: <constraints>
- Compatibility: <constraints>

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Out of Scope
- <explicitly excluded items>
```

**EXPLORATION.md structure:**
```markdown
# Codebase Exploration: <feature-name>

## Relevant Existing Patterns
### Pattern 1: <name>
- Location: <file paths>
- Description: <how it works>
- Relevance: <why it matters for this feature>

## Key Files to Modify
| File | Purpose | Modification Type |
|------|---------|-------------------|
| path/to/file.ts | <purpose> | Modify / Create / Delete |

## Dependencies
- Internal: <list>
- External: <list>

## Risks Identified
- Risk 1: <description and mitigation>
```

**ARCHITECTURE.md structure:**
```markdown
# Architecture: <feature-name>

## Overview
<High-level description of the approach>

## Component Design
### Component 1: <name>
- Responsibility: <what it does>
- Interface: <key methods/APIs>
- Location: <where it lives>

## Data Flow
<Description or diagram of how data moves>

## Implementation Sequence
1. Step 1: <what to build first>
2. Step 2: <what depends on step 1>

## Key Technical Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| <decision> | <choice> | <why> |

## Open Questions for Implementation
- <questions the implementer needs to resolve>
```

---

## Commands

### `/feature-start <description>`

**Purpose:** Initialize a new feature and run the requirements phase.

```markdown
---
name: feature-start
description: Start a new feature development workflow with phase-isolated sessions
arguments:
  - name: description
    description: Brief description of the feature to build
    required: true
  - name: max-iterations
    description: Override default iteration limit for requirements phase
    required: false
    default: "10"
---

# Feature Start Command

You are initiating a new phase-isolated feature development workflow.

## Steps

1. **Create Feature Directory**
   - Generate a URL-safe slug from the description
   - Create `.claude/features/<slug>/`
   - Initialize state.md from template

2. **Run Requirements Phase**
   - Use the requirements-agent to gather and clarify requirements
   - Iterate using ralph-loop pattern until requirements are clear
   - Maximum iterations: {{ max-iterations }}

3. **Checkpoint and Exit**
   - Write REQUIREMENTS.md artifact
   - Update state.md with phase completion
   - Instruct user to run `/feature-continue` in a new session

## Completion Marker

When requirements are complete and written to REQUIREMENTS.md, output:

<phase-complete>PHASE_1_REQUIREMENTS</phase-complete>

Then inform the user:

"✓ Requirements phase complete. Artifacts saved to `.claude/features/<slug>/`.
To continue with codebase exploration, start a new session and run:
`/feature-continue <slug>`"
```

### `/feature-continue [slug]`

**Purpose:** Resume feature development from the last checkpoint.

```markdown
---
name: feature-continue
description: Continue feature development from the last checkpoint
arguments:
  - name: slug
    description: Feature slug (optional if only one feature in progress)
    required: false
---

# Feature Continue Command

You are resuming a phase-isolated feature development workflow.

## Steps

1. **Load State**
   - Read `.claude/features/<slug>/state.md`
   - Identify current phase
   - Load relevant artifacts from prior phases

2. **Context Loading**
   - Only load artifacts needed for current phase:
     - Phase 2 (Exploration): Load REQUIREMENTS.md
     - Phase 3 (Architecture): Load REQUIREMENTS.md, EXPLORATION.md
     - Phase 4 (Implementation): Load ARCHITECTURE.md only
     - Phase 5 (Review): Load ARCHITECTURE.md, examine implementation
     - Phase 6 (Testing): Load ARCHITECTURE.md, examine implementation
     - Phase 7 (Documentation): Load REQUIREMENTS.md, ARCHITECTURE.md

3. **Run Current Phase**
   - Dispatch to appropriate agent
   - Use ralph-loop pattern with phase-specific iteration limit
   - Monitor for phase completion or blockers

4. **Checkpoint and Exit**
   - Write phase artifact
   - Update state.md
   - Instruct user for next steps

## Phase Completion

On phase completion, output:

<phase-complete>PHASE_N_NAME</phase-complete>

## Blocker Handling

If blocked, output:

<phase-blocked>
Blocker: <description>
Needs: <what is needed to unblock>
</phase-blocked>
```

### `/feature-status [slug]`

**Purpose:** Show progress and status across all phases.

```markdown
---
name: feature-status
description: Display feature development progress and status
arguments:
  - name: slug
    description: Feature slug (optional, shows all if omitted)
    required: false
---

# Feature Status Command

Display the current status of feature development.

## Output Format

### Feature: <name>
**Status:** <IN_PROGRESS | BLOCKED | COMPLETE>
**Current Phase:** <phase name> (iteration <n>/<max>)

| Phase | Status | Iterations | Duration |
|-------|--------|------------|----------|
| Requirements | ✓ | 3/10 | 12 min |
| Exploration | ✓ | 7/10 | 28 min |
| Architecture | ⏳ | 4/15 | -- |
| Implementation | ○ | --/25 | -- |
| Review | ○ | --/10 | -- |
| Testing | ○ | --/15 | -- |
| Documentation | ○ | --/5 | -- |

**Next Step:** `/feature-continue <slug>`
```

### `/feature-reset <slug> <phase>`

**Purpose:** Reset a specific phase to re-do it.

```markdown
---
name: feature-reset
description: Reset a phase to redo it (preserves prior phase artifacts)
arguments:
  - name: slug
    description: Feature slug
    required: true
  - name: phase
    description: Phase number or name to reset (e.g., "4" or "implementation")
    required: true
---

# Feature Reset Command

Reset a phase while preserving prior phase artifacts.

## Behavior

- Archives the current phase artifact (if any) to `./archive/`
- Resets phase status in state.md
- Does NOT reset subsequent phases (they will re-run with new input)

## Confirmation Required

Before resetting, confirm with user:

"This will reset Phase <N> (<name>) and require re-running phases <N> through 7.
Existing artifact will be archived. Continue? (yes/no)"
```

---

## Stop Hook (Phase-Aware Ralph Loop)

### hooks/stop-hook.sh

```bash
#!/bin/bash

# Phase-Isolated Feature Dev - Stop Hook
# Implements ralph-wiggum pattern with phase awareness

set -e

# Parse hook input
HOOK_INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')
STOP_REASON=$(echo "$HOOK_INPUT" | jq -r '.stop_reason // "unknown"')

# Find active feature state
FEATURE_DIR=$(find .claude/features -name "state.md" -exec grep -l "Status: IN_PROGRESS" {} \; | head -1 | xargs dirname)

if [ -z "$FEATURE_DIR" ]; then
    # No active feature, allow normal exit
    echo '{"decision": "allow"}'
    exit 0
fi

STATE_FILE="$FEATURE_DIR/state.md"

# Extract current phase info
CURRENT_PHASE=$(grep "Current Phase:" "$STATE_FILE" | sed 's/.*: //')
ITERATION_LINE=$(grep -E "^\- \[ \] $CURRENT_PHASE" "$STATE_FILE")
CURRENT_ITERATION=$(echo "$ITERATION_LINE" | grep -oP 'iteration: \K\d+' || echo "1")

# Phase iteration limits
declare -A MAX_ITERATIONS=(
    ["PHASE_1_REQUIREMENTS"]=10
    ["PHASE_2_EXPLORATION"]=10
    ["PHASE_3_ARCHITECTURE"]=15
    ["PHASE_4_IMPLEMENTATION"]=25
    ["PHASE_5_REVIEW"]=10
    ["PHASE_6_TESTING"]=15
    ["PHASE_7_DOCUMENTATION"]=5
)

MAX_FOR_PHASE=${MAX_ITERATIONS[$CURRENT_PHASE]:-10}

# Check for phase completion in recent output
RECENT_OUTPUT=$(tail -100 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")

if echo "$RECENT_OUTPUT" | grep -q "<phase-complete>"; then
    # Phase completed, allow exit for session boundary
    echo '{"decision": "allow", "message": "Phase complete. Start new session with /feature-continue"}'
    exit 0
fi

if echo "$RECENT_OUTPUT" | grep -q "<phase-blocked>"; then
    # Phase blocked, allow exit for human intervention
    echo '{"decision": "allow", "message": "Phase blocked. Review blocker and restart."}'
    exit 0
fi

# Check iteration limit
if [ "$CURRENT_ITERATION" -ge "$MAX_FOR_PHASE" ]; then
    # Iteration limit reached, checkpoint and exit
    echo '{"decision": "allow", "message": "Iteration limit reached. Review progress and run /feature-continue"}'
    exit 0
fi

# Otherwise, continue the ralph loop
NEXT_ITERATION=$((CURRENT_ITERATION + 1))

# Update iteration count in state file
sed -i "s/iteration: $CURRENT_ITERATION/iteration: $NEXT_ITERATION/" "$STATE_FILE"

# Build continuation prompt
PROMPT="Continue working on the current phase ($CURRENT_PHASE).

Iteration $NEXT_ITERATION of $MAX_FOR_PHASE.

Review your progress and continue. When the phase is complete, output:
<phase-complete>$CURRENT_PHASE</phase-complete>

If blocked, output:
<phase-blocked>
Blocker: <description>
Needs: <what is needed>
</phase-blocked>"

echo "{\"decision\": \"block\", \"prompt\": $(echo "$PROMPT" | jq -Rs .)}"
```

---

## Agents

### agents/requirements-agent.md

```markdown
---
name: requirements-agent
description: Gathers and clarifies feature requirements through conversation
tools:
  - Read
  - Write
  - AskUser
  - TodoWrite
---

# Requirements Agent

You are a senior product engineer gathering requirements for a new feature.

## Your Goal

Produce a clear, complete REQUIREMENTS.md that the exploration and architecture phases can use without ambiguity.

## Process

1. **Understand the Request**
   - Read the initial feature description
   - Identify what's clear vs. ambiguous

2. **Clarify with User**
   - Ask focused questions (max 3 at a time)
   - Don't assume - verify constraints
   - Understand the "why" not just the "what"

3. **Document Requirements**
   - Functional requirements (what it must do)
   - Non-functional requirements (performance, security, etc.)
   - Acceptance criteria (how we know it's done)
   - Out of scope (what we're explicitly NOT doing)

4. **Validate**
   - Summarize back to user
   - Get explicit approval before marking complete

## Output

Write to `.claude/features/<slug>/REQUIREMENTS.md`

When complete and approved, output:
<phase-complete>PHASE_1_REQUIREMENTS</phase-complete>
```

### agents/explorer-agent.md

```markdown
---
name: explorer-agent
description: Analyzes existing codebase to inform architecture decisions
tools:
  - Read
  - Glob
  - Grep
  - LS
  - Write
---

# Codebase Explorer Agent

You are a senior engineer performing codebase analysis to inform feature implementation.

## Input

Read: `.claude/features/<slug>/REQUIREMENTS.md`

## Your Goal

Produce EXPLORATION.md that gives the architect everything they need to design the implementation.

## Process

1. **Find Similar Patterns**
   - Search for similar features in the codebase
   - Identify established patterns and conventions
   - Note any CLAUDE.md guidelines

2. **Map the Landscape**
   - Identify files that will need modification
   - Find integration points
   - Document dependencies (internal and external)

3. **Identify Risks**
   - Technical debt that might complicate implementation
   - Missing abstractions
   - Potential conflicts with existing code

4. **Document Findings**
   - Keep it concise - architect doesn't need every detail
   - Focus on decisions the findings inform

## Output

Write to `.claude/features/<slug>/EXPLORATION.md`

When complete, output:
<phase-complete>PHASE_2_EXPLORATION</phase-complete>
```

### agents/architect-agent.md

```markdown
---
name: architect-agent
description: Designs feature architecture based on requirements and codebase analysis
tools:
  - Read
  - Write
  - Glob
  - Grep
---

# Architecture Agent

You are a senior software architect designing the implementation approach.

## Input

Read:
- `.claude/features/<slug>/REQUIREMENTS.md`
- `.claude/features/<slug>/EXPLORATION.md`

## Your Goal

Produce ARCHITECTURE.md that gives the implementer a clear, actionable blueprint.

## Process

1. **Synthesize Inputs**
   - Requirements tell you WHAT
   - Exploration tells you WHERE and HOW (patterns)

2. **Design Components**
   - Define clear boundaries
   - Specify interfaces
   - Document data flow

3. **Make Decisions**
   - Be decisive - pick one approach
   - Document rationale for non-obvious choices
   - Note tradeoffs explicitly

4. **Sequence the Work**
   - What must be built first?
   - What can be parallelized?
   - Where are the risk points?

## Output

Write to `.claude/features/<slug>/ARCHITECTURE.md`

When complete, output:
<phase-complete>PHASE_3_ARCHITECTURE</phase-complete>
```

### agents/implementer-agent.md

```markdown
---
name: implementer-agent
description: Implements the feature according to the architecture blueprint
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Implementation Agent

You are a senior engineer implementing a feature from an architecture blueprint.

## Input

Read: `.claude/features/<slug>/ARCHITECTURE.md`

(Do NOT re-read REQUIREMENTS.md or EXPLORATION.md - architecture has what you need)

## Your Goal

Implement the feature following the architecture precisely.

## Process

1. **Understand the Blueprint**
   - Read ARCHITECTURE.md completely
   - Note the implementation sequence
   - Identify the first deliverable

2. **Implement Incrementally**
   - Follow the sequence in ARCHITECTURE.md
   - One component at a time
   - Verify each step works before proceeding

3. **Track Progress**
   - Update state.md with completed steps
   - Note any deviations from architecture (and why)

4. **Handle Blockers**
   - If architecture is unclear, note it and make reasonable choice
   - If architecture is wrong, document and proceed with fix
   - Major blockers should trigger <phase-blocked>

## Output

- Modified/created source files
- Update state.md with implementation progress

When all architecture steps complete, output:
<phase-complete>PHASE_4_IMPLEMENTATION</phase-complete>
```

### agents/reviewer-agent.md

```markdown
---
name: reviewer-agent
description: Reviews implementation for issues and improvements
tools:
  - Read
  - Glob
  - Grep
  - Write
---

# Review Agent

You are a senior engineer reviewing a feature implementation.

## Input

Read: `.claude/features/<slug>/ARCHITECTURE.md`
Examine: Implementation files (from ARCHITECTURE.md file list)

## Your Goal

Identify issues that must be fixed before testing.

## Review Criteria

1. **Correctness**
   - Does implementation match architecture?
   - Are edge cases handled?
   - Is error handling complete?

2. **Code Quality**
   - Follows project conventions?
   - No obvious bugs or anti-patterns?
   - Reasonable performance?

3. **Security**
   - No injection vulnerabilities?
   - Proper input validation?
   - Secrets handled correctly?

## Output

Write to `.claude/features/<slug>/REVIEW.md`:

```markdown
# Review: <feature-name>

## Summary
<PASS | PASS_WITH_NOTES | NEEDS_CHANGES>

## Issues Found

### Critical (must fix)
- [ ] Issue 1: <description> in <file:line>

### Recommended (should fix)
- [ ] Issue 2: <description>

### Notes (optional improvements)
- Note 1: <suggestion>
```

If NEEDS_CHANGES with critical issues:
<phase-blocked>
Blocker: Critical issues found in review
Needs: Fix issues in REVIEW.md, then re-run review
</phase-blocked>

If PASS or PASS_WITH_NOTES:
<phase-complete>PHASE_5_REVIEW</phase-complete>
```

---

## Plugin Configuration

### .claude-plugin/plugin.json

```json
{
  "$schema": "https://anthropic.com/claude-code/plugin.schema.json",
  "name": "phase-feature-dev",
  "version": "1.0.0",
  "description": "Phase-isolated feature development with token-aware session boundaries. Combines structured feature-dev workflow with ralph-wiggum iteration patterns.",
  "author": {
    "name": "Your Name",
    "email": "you@company.com"
  },
  "commands": [
    {
      "name": "feature-start",
      "source": "./commands/feature-start.md"
    },
    {
      "name": "feature-continue", 
      "source": "./commands/feature-continue.md"
    },
    {
      "name": "feature-status",
      "source": "./commands/feature-status.md"
    },
    {
      "name": "feature-reset",
      "source": "./commands/feature-reset.md"
    }
  ],
  "agents": [
    {
      "name": "requirements-agent",
      "source": "./agents/requirements-agent.md"
    },
    {
      "name": "explorer-agent",
      "source": "./agents/explorer-agent.md"
    },
    {
      "name": "architect-agent",
      "source": "./agents/architect-agent.md"
    },
    {
      "name": "implementer-agent",
      "source": "./agents/implementer-agent.md"
    },
    {
      "name": "reviewer-agent",
      "source": "./agents/reviewer-agent.md"
    }
  ],
  "hooks": [
    {
      "event": "Stop",
      "source": "./hooks/stop-hook.sh"
    }
  ],
  "settings": {
    "phase_iterations": {
      "requirements": 10,
      "exploration": 10,
      "architecture": 15,
      "implementation": 25,
      "review": 10,
      "testing": 15,
      "documentation": 5
    }
  }
}
```

---

## Usage Examples

### Starting a New Feature

```bash
# Start the workflow
claude
> /feature-start Add Prometheus query caching with Redis backend

# Claude runs requirements phase, asks clarifying questions
# After ~3-10 iterations, requirements complete

# Output:
# ✓ Requirements phase complete. 
# Artifacts saved to `.claude/features/prometheus-query-caching/`
# To continue, start a new session and run:
# /feature-continue prometheus-query-caching
```

### Continuing Development

```bash
# New session (tokens reset!)
claude
> /feature-continue prometheus-query-caching

# Claude loads REQUIREMENTS.md, runs exploration phase
# ...continues through phases with session breaks
```

### Checking Status

```bash
> /feature-status

### Feature: prometheus-query-caching
**Status:** IN_PROGRESS
**Current Phase:** PHASE_4_IMPLEMENTATION (iteration 12/25)

| Phase | Status | Iterations | 
|-------|--------|------------|
| Requirements | ✓ | 3/10 |
| Exploration | ✓ | 7/10 |
| Architecture | ✓ | 11/15 |
| Implementation | ⏳ | 12/25 |
| Review | ○ | --/10 |
| Testing | ○ | --/15 |
| Documentation | ○ | --/5 |
```

---

## Configuration Overrides

Users can override defaults in their project's `.claude/settings.json`:

```json
{
  "plugins": {
    "phase-feature-dev": {
      "phase_iterations": {
        "implementation": 40,
        "testing": 20
      }
    }
  }
}
```

---

## Distribution

For distribution via private GitHub marketplace:

1. Create repo in your org's GitHub
2. Add to marketplace.json in your plugin registry
3. Developers install via: `/plugin install github:your-org/phase-feature-dev`

---

## Future Enhancements

- [ ] MCP integration for querying Mimir/Prometheus during exploration
- [ ] Automatic token estimation before phase start
- [ ] Integration with PR creation after completion
- [ ] Metrics collection on iteration counts and success rates
- [ ] Team-specific agent customizations (Rails patterns, K8s conventions)
