# Session Boundaries Reference

How phase isolation manages token context limits through explicit session boundaries and selective artifact loading.

## The Token Problem

Claude Code has a 200k token context window. Complex feature development can exhaust this in a single session, especially when:

- Exploration reads many source files into context
- Architecture iterates on design decisions
- Implementation writes significant amounts of code
- Iteration loops (like ralph-loop) keep the session alive longer

When context is exhausted, Claude's performance degrades — it may forget earlier decisions, repeat work, or produce inconsistent code.

## Session Boundary Mechanics

A session boundary is a deliberate point where the user exits Claude Code and starts a new session. This resets the token context to zero.

### What Persists Across Boundaries

- Feature state file (`.claude/features/<slug>/state.md`)
- Phase artifacts (REQUIREMENTS.md, EXPLORATION.md, etc.)
- Source code changes (committed or uncommitted)

### What Does NOT Persist

- Conversation history
- Tool call context
- Intermediate reasoning
- File contents that were read but not saved to artifacts

This is why artifacts must be self-contained. Any insight, decision, or finding that a future phase needs must be captured in the artifact file.

## Token Budgets Per Phase

| Phase | Max Iterations | Token Budget | Rationale |
|-------|---------------|--------------|-----------|
| Requirements | 10 | 20-40k | Mostly conversation with user, limited code reading |
| Exploration | 10 | 30-50k | Reads existing code files, but summarizes into artifact |
| Architecture | 15 | 40-60k | Design iteration, may reference code patterns |
| Implementation | 25 | 60-100k | Largest phase — writes and reads source code |
| Review | 10 | 30-50k | Reads implementation + architecture, produces report |
| Testing | 15 | 40-60k | Writes test code, runs tests, iterates on failures |
| Documentation | 5 | 15-25k | Usually straightforward, limited iteration needed |

These budgets assume selective artifact loading per the context loading rules. If all artifacts were loaded in every phase, budgets would be significantly higher.

## Context Loading Strategy

### Minimal Loading Principle

Each phase loads only the artifacts it directly needs. This is the key mechanism that keeps sessions within budget.

### Why Implementation Only Loads Architecture

Phase 4 (Implementation) deliberately does NOT load REQUIREMENTS.md or EXPLORATION.md. This is intentional:

1. **Token efficiency:** ARCHITECTURE.md should contain all information the implementer needs
2. **Decision authority:** The architecture is the source of truth for implementation decisions
3. **Artifact quality incentive:** Forces the architect to produce a complete, actionable blueprint

If the implementer finds the architecture incomplete, they should note the gap and make a reasonable choice (or raise `<phase-blocked>` for major issues). This feedback loop improves architecture quality over time.

### Why Later Phases Avoid Earlier Artifacts

Phases 5-7 do not load EXPLORATION.md because:
- Exploration findings are already synthesized into ARCHITECTURE.md
- Loading redundant artifacts wastes token budget
- The architecture is the canonical design reference

## Artifact Sizing Guidelines

Artifacts should be concise enough to fit within the consuming phase's token budget alongside the phase's own work.

| Artifact | Target Size | Max Size |
|----------|-------------|----------|
| REQUIREMENTS.md | 500-1500 words | 3000 words |
| EXPLORATION.md | 800-2000 words | 4000 words |
| ARCHITECTURE.md | 1000-3000 words | 5000 words |
| REVIEW.md | 300-1000 words | 2000 words |
| TESTING.md | 500-1500 words | 3000 words |
| DOCS.md | 300-1000 words | 2000 words |

### How to Keep Artifacts Lean

- Summarize findings, don't include raw code listings
- Focus on decisions and rationale, not exhaustive analysis
- Use tables for structured data
- Reference file paths instead of inlining file contents
- Keep the "Current Phase Context" section of state.md under 2000 tokens

## Iteration Limits

Each phase has a maximum iteration count enforced by the stop hook. When the limit is reached:

1. The hook allows the session to exit
2. State file records current progress
3. User can run `/feature-continue` to resume in a new session
4. The new session starts with fresh context but picks up from the last checkpoint

This prevents any single session from running indefinitely and exhausting the context window through accumulated conversation history.

## Mid-Phase Session Boundaries

If a phase's iteration limit is reached before completion (common in Phase 4 Implementation):

1. The state file records which implementation steps are complete
2. The next session loads ARCHITECTURE.md and checks the state file
3. Work resumes from the last completed step
4. The iteration counter resets for the new session

This allows large phases like Implementation to span multiple sessions while keeping each session within token budget.

## State File as Session Handoff

The state file serves as the handoff mechanism between sessions. The "Current Phase Context" section is especially important — it captures:

- **Key Decisions Made:** Decisions from the current phase that shouldn't be re-debated
- **Open Questions:** Unresolved items that need attention in the next iteration
- **Blockers:** Anything preventing progress

Keep this section under 2000 tokens to avoid bloating session startup.
