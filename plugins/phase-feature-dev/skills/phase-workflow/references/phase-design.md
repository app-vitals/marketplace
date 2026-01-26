# Phase Design Reference

Detailed descriptions of each phase in the phase-isolated feature development workflow.

## Phase 1: Requirements

**Agent:** requirements-agent
**Max Iterations:** 10
**Estimated Token Budget:** 20-40k tokens
**Input:** Feature description from user
**Output:** REQUIREMENTS.md

The requirements phase focuses on gathering and clarifying what needs to be built. The agent acts as a senior product engineer, asking focused questions (max 3 at a time) to avoid overwhelming the user. The goal is to produce a REQUIREMENTS.md that downstream phases can consume without ambiguity.

Key activities:
- Understand the initial request and identify ambiguities
- Ask clarifying questions about scope, constraints, and acceptance criteria
- Document functional and non-functional requirements
- Explicitly define what is out of scope
- Get user approval before marking complete

The requirements artifact should be self-contained — an architect reading it should understand what to build without needing the original conversation.

## Phase 2: Exploration

**Agent:** explorer-agent
**Max Iterations:** 10
**Estimated Token Budget:** 30-50k tokens
**Input:** REQUIREMENTS.md
**Output:** EXPLORATION.md

The exploration phase analyzes the existing codebase to inform architecture decisions. The agent searches for similar patterns, identifies files that need modification, maps dependencies, and surfaces risks.

Key activities:
- Search for similar features and established patterns
- Check CLAUDE.md for project-specific guidelines
- Identify integration points and modification targets
- Document internal and external dependencies
- Flag technical debt or missing abstractions that could complicate implementation

The exploration artifact should focus on decisions the findings inform, not exhaustive code listings. Keep it concise enough that the architect can absorb it alongside REQUIREMENTS.md.

## Phase 3: Architecture

**Agent:** architect-agent
**Max Iterations:** 15
**Estimated Token Budget:** 40-60k tokens
**Input:** REQUIREMENTS.md + EXPLORATION.md
**Output:** ARCHITECTURE.md

The architecture phase synthesizes requirements (what) with exploration findings (where/how) into an actionable blueprint. This is the phase where key technical decisions are made.

Key activities:
- Define component boundaries and interfaces
- Document data flow between components
- Make decisive technical choices (pick one approach, document rationale)
- Sequence the implementation work (what must be built first)
- Identify risk points and parallelizable work
- Leave clear notes for the implementer on any ambiguities

The architecture artifact is the primary input for implementation. It should be specific enough that the implementer does not need to re-read requirements or exploration.

## Phase 4: Implementation

**Agent:** implementer-agent
**Max Iterations:** 25
**Estimated Token Budget:** 60-100k tokens
**Input:** ARCHITECTURE.md only
**Output:** Source code files

The largest phase. The implementer follows the architecture blueprint step by step, writing actual code. This phase deliberately does NOT load REQUIREMENTS.md or EXPLORATION.md — the architecture should contain everything needed.

Key activities:
- Read ARCHITECTURE.md completely before starting
- Follow the implementation sequence defined in the architecture
- Build one component at a time, verifying each works before proceeding
- Track progress in state.md with completed steps
- Document any deviations from architecture with rationale
- Raise `<phase-blocked>` for major architectural issues

If the iteration limit is reached before completion, the state file captures progress so the next session can continue from where implementation left off.

## Phase 5: Review

**Agent:** reviewer-agent
**Max Iterations:** 10
**Estimated Token Budget:** 30-50k tokens
**Input:** ARCHITECTURE.md + implementation code
**Output:** REVIEW.md

The review phase examines the implementation against the architecture for correctness, code quality, and security. Issues are categorized as critical (must fix), recommended (should fix), or notes (optional).

Key activities:
- Verify implementation matches architecture
- Check edge case handling
- Review error handling completeness
- Assess code quality against project conventions
- Check for security vulnerabilities (injection, validation, secrets)

The review produces one of three verdicts:
- **PASS** — proceed to testing
- **PASS_WITH_NOTES** — proceed with minor improvements noted
- **NEEDS_CHANGES** — critical issues found, triggers `<phase-blocked>` requiring re-implementation

## Phase 6: Testing (Stub)

**Agent:** tester-agent
**Max Iterations:** 15
**Estimated Token Budget:** 40-60k tokens
**Input:** ARCHITECTURE.md + implementation code
**Output:** TESTING.md

Writes and runs tests for the implemented feature. Currently a stub — the agent structure exists but detailed test generation logic is deferred.

Key activities:
- Design test strategy based on architecture
- Write unit tests for individual components
- Write integration tests for component interactions
- Execute tests and capture results
- Document coverage and any gaps

## Phase 7: Documentation (Stub)

**Agent:** documenter-agent
**Max Iterations:** 5
**Estimated Token Budget:** 15-25k tokens
**Input:** REQUIREMENTS.md + ARCHITECTURE.md
**Output:** DOCS.md

Updates project documentation to reflect the new feature. Currently a stub — the agent structure exists but detailed documentation generation logic is deferred.

Key activities:
- Update README or relevant docs with feature description
- Document any new APIs or configuration options
- Add usage examples
- Update architectural documentation if needed
