# Phase-Isolated Feature Development

A Claude Code plugin that breaks complex feature development into 7 discrete phases, each running in its own session. Only distilled markdown artifacts pass between sessions, keeping each within the 200k token context window.

## The Problem

Complex features exhaust the context window when developed in a single session. Wrapping with iteration loops compounds the issue. Phase isolation solves this by defining explicit session boundaries with structured artifact handoffs.

## How It Works

```
Phase 1: Requirements    ──→ REQUIREMENTS.md
   [SESSION BOUNDARY]
Phase 2: Exploration     ──→ EXPLORATION.md
   [SESSION BOUNDARY]
Phase 3: Architecture    ──→ ARCHITECTURE.md
   [SESSION BOUNDARY]
Phase 4: Implementation  ──→ source code
   [SESSION BOUNDARY]
Phase 5: Review          ──→ REVIEW.md
   [SESSION BOUNDARY]
Phase 6: Testing         ──→ TESTING.md
   [SESSION BOUNDARY]
Phase 7: Documentation   ──→ DOCS.md
```

Each phase has its own agent, iteration limit, and artifact template. The stop hook keeps each phase iterating until complete or the limit is reached. Only the artifacts needed for the current phase are loaded into context.

## Quick Start

```bash
# Start a new feature
/feature-start Add user authentication with OAuth2

# Claude gathers requirements through conversation (up to 10 iterations)
# When complete, start a NEW session:

/feature-continue add-user-authentication-with-oauth2

# Claude explores the codebase, then asks you to start another session
# Continue through all 7 phases...

# Check progress at any time
/feature-status

# Reset a phase if needed
/feature-reset add-user-authentication-with-oauth2 3
```

## Commands

| Command | Purpose |
|---------|---------|
| `/feature-start <description>` | Initialize a feature and run Phase 1 (Requirements) |
| `/feature-continue [slug]` | Resume from the last checkpoint in a new session |
| `/feature-status [slug]` | Show progress across all phases |
| `/feature-reset <slug> <phase>` | Reset a phase to redo it |

## Phases

| # | Phase | Agent | Max Iterations | What It Produces |
|---|-------|-------|----------------|------------------|
| 1 | Requirements | requirements-agent | 10 | REQUIREMENTS.md |
| 2 | Exploration | explorer-agent | 10 | EXPLORATION.md |
| 3 | Architecture | architect-agent | 15 | ARCHITECTURE.md |
| 4 | Implementation | implementer-agent | 25 | Source code |
| 5 | Review | reviewer-agent | 10 | REVIEW.md |
| 6 | Testing | tester-agent | 15 | TESTING.md |
| 7 | Documentation | documenter-agent | 5 | DOCS.md |

Phases 6 and 7 are stubs in v1 — the agent structure exists but detailed logic is deferred.

## Context Loading

Each phase loads only what it needs:

| Phase | Loads |
|-------|-------|
| Exploration | REQUIREMENTS.md |
| Architecture | REQUIREMENTS.md + EXPLORATION.md |
| Implementation | ARCHITECTURE.md only |
| Review | ARCHITECTURE.md + code |
| Testing | ARCHITECTURE.md + code |
| Documentation | REQUIREMENTS.md + ARCHITECTURE.md |

## State Management

Feature state lives in `.claude/features/<slug>/state.md`. This file tracks:
- Current phase and iteration count
- Phase completion status with timestamps
- Artifact status
- Session history
- Key decisions, open questions, and blockers

## Installation

```bash
# Test locally
claude --plugin-dir /path/to/plugins/phase-feature-dev

# Or add to your project
# Copy to your plugin directory and reference in your settings
```

## Architecture

```
phase-feature-dev/
├── .claude-plugin/plugin.json     # Plugin manifest
├── commands/                       # 4 slash commands
├── agents/                         # 7 phase agents
├── hooks/
│   ├── hooks.json                 # Stop hook config
│   └── stop-hook.sh               # Phase-aware iteration loop
├── scripts/
│   ├── state-manager.sh           # Read state operations
│   └── checkpoint.sh              # Write state operations
└── skills/phase-workflow/
    ├── SKILL.md                   # Workflow philosophy
    ├── assets/templates/          # 6 artifact templates
    └── references/                # Phase design + session boundaries
```

## References

Combines patterns from:
- **ralph-loop** — Stop hook iteration pattern, defensive error handling
- **feature-dev** — Structured development phases with specialized agents
