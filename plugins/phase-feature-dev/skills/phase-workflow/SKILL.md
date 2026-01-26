---
name: Phase Workflow
description: This skill should be used when the user asks to "start a feature", "continue a feature", "check feature status", "reset a phase", or discusses phase-isolated feature development, token management across sessions, or multi-session feature workflows. Provides the philosophy, artifact flow, and operational guidance for the 7-phase feature development system.
---

# Phase-Isolated Feature Development

A structured workflow that breaks complex feature development into 7 discrete phases, each running in its own Claude Code session. Only distilled markdown artifacts pass between sessions, keeping each within token budget.

## Why Phase Isolation

Complex features exhaust the 200k token context window when developed in a single session. Wrapping with iteration loops compounds the problem. Phase isolation solves this by:

- Defining clear session boundaries between phases
- Persisting only structured artifact files (not conversation history)
- Loading only the artifacts relevant to the current phase
- Enforcing per-phase iteration limits to prevent runaway sessions

## The 7 Phases

| # | Phase | Agent | Max Iter | Input Artifacts | Output Artifact |
|---|-------|-------|----------|-----------------|-----------------|
| 1 | Requirements | requirements-agent | 10 | description | REQUIREMENTS.md |
| 2 | Exploration | explorer-agent | 10 | REQUIREMENTS.md | EXPLORATION.md |
| 3 | Architecture | architect-agent | 15 | REQUIREMENTS + EXPLORATION | ARCHITECTURE.md |
| 4 | Implementation | implementer-agent | 25 | ARCHITECTURE.md | source code |
| 5 | Review | reviewer-agent | 10 | ARCHITECTURE + code | REVIEW.md |
| 6 | Testing | tester-agent | 15 | ARCHITECTURE + code | TESTING.md |
| 7 | Documentation | documenter-agent | 5 | REQUIREMENTS + ARCHITECTURE | DOCS.md |

Each phase ends by emitting `<phase-complete>PHASE_N_NAME</phase-complete>` or `<phase-blocked>` if stuck.

## Artifact Flow

Artifacts are the only data that crosses session boundaries. Each artifact is a structured markdown file written to `.claude/features/<slug>/`.

### Context Loading Rules

Load only what the current phase needs — never the full history:

- **Phase 2:** REQUIREMENTS.md
- **Phase 3:** REQUIREMENTS.md + EXPLORATION.md
- **Phase 4:** ARCHITECTURE.md only
- **Phase 5:** ARCHITECTURE.md + examine code
- **Phase 6:** ARCHITECTURE.md + examine code
- **Phase 7:** REQUIREMENTS.md + ARCHITECTURE.md

This selective loading is what keeps each session within token budget.

## State Management

Feature state lives in `.claude/features/<slug>/state.md` — a markdown file with structured sections (not YAML frontmatter). The state file tracks:

- Current phase and iteration count
- Phase completion status with timestamps
- Artifact status table
- Session history
- Current phase context (key decisions, open questions, blockers)

### State Operations

Use the scripts in `${CLAUDE_PLUGIN_ROOT}/scripts/`:

- **`state-manager.sh`** — Read state: find active features, get current phase, get/update iteration counts
- **`checkpoint.sh`** — Write state: initialize features, save/archive artifacts, complete/reset phases

All scripts use macOS-compatible bash (no `declare -A`, no `grep -oP`, atomic writes via temp+mv).

## Iteration Pattern

Each phase runs a ralph-loop style iteration cycle via the stop hook:

1. Command dispatches the appropriate agent
2. Agent works toward phase completion
3. On stop, hook checks for `<phase-complete>` or `<phase-blocked>` markers
4. If neither found and iteration limit not reached, hook increments iteration and continues
5. If limit reached, hook allows exit for checkpoint

## Templates

Artifact templates live in `${CLAUDE_PLUGIN_ROOT}/skills/phase-workflow/assets/templates/`:

- `feature-state.md` — State tracking with all 7 phases
- `requirements.md` — Functional/non-functional requirements structure
- `exploration.md` — Codebase patterns, files, dependencies, risks
- `architecture.md` — Components, data flow, implementation sequence
- `review.md` — Critical/recommended/notes issue format
- `testing.md` — Test strategy, cases, results

## Session Boundary Protocol

When a phase completes:

1. Agent writes the phase artifact to `.claude/features/<slug>/`
2. Agent emits `<phase-complete>PHASE_N_NAME</phase-complete>`
3. Stop hook detects the marker and allows session to end
4. User starts a new session and runs `/feature-continue <slug>`
5. New session loads only the artifacts needed for the next phase

This is the core mechanism that resets token usage between phases.

## Additional Resources

### Reference Files

For detailed phase descriptions and session boundary mechanics:
- **`references/phase-design.md`** — Detailed per-phase descriptions, agent responsibilities, expected token budgets
- **`references/session-boundaries.md`** — Token budget rationale, context reset mechanics, artifact sizing guidelines
