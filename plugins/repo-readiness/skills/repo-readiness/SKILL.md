---
name: repo-readiness
description: Audit a codebase for agent-readiness gaps. Score each category. Optionally bootstrap missing pieces with --fix.
---

# Repo Readiness

Audit the current codebase for legibility gaps that hurt agent performance. Score each category. Write a structured report. Use `--fix` to generate the missing pieces.

This skill **does not modify code** unless `--fix` is passed.

---

## Setup: Parse Arguments

Before starting, check flags:

- `--fix` — run the full audit, then generate bootstrap assets for each failing check
- `--category <id>` — audit only the named category (e.g., `--category agent_context`)
- `--no-report` — print summary to stdout; skip writing `readiness-report.md`

---

## Step 1: Load Criteria

1. Check if `.claude/repo-readiness/criteria.yaml` exists in the project root.
   - If yes, use it as the criteria config (project override).
   - If no, use the plugin's default: `skills/repo-readiness/readiness-criteria.yaml`.

2. If `--category` was passed, filter to only that category. Otherwise audit all.

---

## Step 2: Run Per-Category Checks

For each category in the criteria config, run each check using its `detection_hint` as guidance. Record: pass/fail, severity, and a brief note (e.g., how many files had the issue, or what was missing).

Do not modify any files during this step — read-only.

### How to run checks

Each check has a `detection_hint` describing what to look for. Use Glob, Grep, Read, and Bash (for line counts) to answer each check. Be specific: if a check asks for file counts or link counts, produce the actual number.

**Efficiency tip:** batch Glob/Grep calls where possible. Run category checks in parallel mentally — but write them sequentially in the report.

---

## Step 3: Score Each Category

For each category, compute the score using the methodology in `references/scoring.md`:

1. Sum the point values of passing checks (critical=40, high=20, medium=15, low=10).
2. Sum the maximum possible points for that category.
3. Score = (earned / max) × 100, rounded to nearest integer.

Determine the band for each category and for the overall weighted score.

**Critical gap check:** If AC-1 or TC-1 failed, cap overall band at "Not Ready" regardless of weighted score.

---

## Step 4: Write the Report

Unless `--no-report` was passed:

1. Write `readiness-report.md` to the project root.
2. Use the format from `references/scoring.md`.
3. Sort gaps by severity: critical → high → medium → low.
4. For each gap, write one concrete "what to do" line — not generic advice.

Print a summary to stdout:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REPO READINESS — {repo_name}
Overall: {score}/100 — {band}

Agent Context Files:     {score}/100
In-Repo Documentation:   {score}/100
Codebase Structure:      {score}/100
Test Coverage:           {score}/100
Observability:           {score}/100

{N} critical  {N} high  {N} medium  {N} low gaps found.
Report written: readiness-report.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If `--no-report` was passed, print the same summary but skip writing the file.

---

## Step 5: Bootstrap (--fix only)

Only runs when `--fix` is passed. For each failing check, generate the missing asset and write it to the project.

### AC-1: No CLAUDE.md

Generate a starter `CLAUDE.md` at the repo root:

```markdown
# {repo_name}

## What This Is
{one sentence inferred from README or package.json description}

## Architecture
{bullet list of top-level directories with one-line purpose each}

## Key Conventions
- {primary language/runtime, e.g. "TypeScript/Bun"}
- {test command, e.g. "bun test"}
- {lint command if found}

## What's Not Here
{placeholder — fill in links, external context, etc.}
```

Announce: "Created CLAUDE.md. Fill in the 'What's Not Here' section with any external context (Notion, Confluence, etc.) worth surfacing."

### AC-2: CLAUDE.md not layered

For each subdirectory with more than 5 source files, generate a stub:

```markdown
# {dirname}/

## Purpose
{one-line description inferred from file names and README}

## Key Files
{bullet list of main entry points found in this directory}
```

Write to `{subdir}/CLAUDE.md`. Announce each file created.

### AC-3: CLAUDE.md over 500 lines

Print a warning with the actual line count. Do not auto-edit — CLAUDE.md content is human-reviewed. Suggest splitting by telling the user which sections are candidates for subdirectory files.

### AC-4: External doc links

List all external links found. Print a suggestion for each:

```
Notion link in CLAUDE.md (line 34): consider moving the content to docs/architecture.md
```

Do not auto-remove or auto-replace links.

### DO-1: README gaps

Identify which sections are missing (what/run/test). Generate minimal stubs:

```markdown
## Getting Started
{placeholder — add install + run instructions}

## Running Tests
{placeholder — add test command}
```

Append to existing README.md (or create README.md if absent). Announce.

### DO-3: No ADRs

Create a `docs/decisions/` directory with one template file:

```markdown
# ADR-001: {title}

**Status:** proposed | accepted | deprecated | superseded
**Date:** {today}

## Context
{What is the issue that motivates this decision?}

## Decision
{What is the change that we're proposing or have agreed to implement?}

## Consequences
{What becomes easier or harder as a result of this change?}
```

Announce: "Created docs/decisions/ADR-001-template.md. Document your first architectural decision here."

### ST-1: No module separation

List top-level source files that are flat in a single directory. Print a suggested directory layout based on what the files do (infer from names). Do not move files.

### ST-2: Files over 500 lines

Print a table of offenders with line counts. For each, suggest splitting at its natural seam (e.g., if a 700-line file has 3 exported classes, suggest extracting each to its own file). Do not auto-split.

### TC-1: No test framework

Detect the primary language/runtime and suggest an appropriate test framework:
- TypeScript/Bun → `bun test` (built-in, no install)
- TypeScript/Node → Vitest or Jest
- Python → pytest
- Go → `go test` (built-in)
- Rust → `cargo test` (built-in)

Print setup instructions. Do not auto-install.

### TC-2: Low test file ratio

Print a list of source files with no corresponding test file. Suggest a starter test for the most critical-looking file (e.g., the main entry point or the largest exported module):

```typescript
// Suggested starter: {source_file}.test.ts
import { ... } from './{source_file}';

describe('{module_name}', () => {
  it('should ...', () => {
    // TODO: implement
  });
});
```

Write the starter test file. Announce.

### OB-1: No structured logging

Detect the runtime and suggest a logger:
- Bun/Node → pino or winston (print install command)
- Python → structlog or loguru
- Go → slog (built-in since Go 1.21)

Do not auto-install or auto-replace console.log calls.

### OB-2: No health endpoint (server apps only)

Detect the framework and add a minimal health route:

- Hono: `app.get('/health', (c) => c.json({ ok: true }))`
- Express: `app.get('/health', (req, res) => res.json({ ok: true }))`
- FastAPI: `@app.get('/health') async def health(): return {"ok": True}`

Write the change to the server file. Announce.

---

## Step 6: Summary

After all checks (and bootstrap if `--fix`):

Print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DONE

Score:  {before}/100 → {after}/100   (if --fix ran)
        {score}/100                   (if audit only)

{N} assets generated.   (if --fix)
{N} gaps remain — see readiness-report.md.

Pairs well with:
  /entropy-scan   — ongoing drift detection after readiness is established
  /plan-session   — structured planning once the repo is agent-readable
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
