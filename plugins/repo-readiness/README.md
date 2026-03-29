# repo-readiness

> Agent-readiness audit and bootstrapping for codebases.

Scores a repo across 5 categories and tells you exactly what's missing before you unleash `/dev-loop` on it.

**Key insight:** "If it's not in the repo, it doesn't exist to the agent." — OpenAI agent engineering research. A repo readiness audit makes this concrete and actionable.

---

## The Problem

Teams run `/dev-loop` on a repo that isn't agent-ready and get mediocre results without understanding why. Common gaps:

- No CLAUDE.md — agent starts cold every session
- Architecture documented in Notion — agent can't see it
- No tests — agent can't verify its changes
- Docs in one giant file — agent skips or misses the key parts
- Raw `console.log` everywhere — agent can't tell if the system is working

`repo-readiness` finds these gaps in 30 seconds. `--fix` generates the missing pieces.

---

## Quick Start

```bash
# Audit the current repo
/repo-readiness

# Audit + generate missing assets
/repo-readiness --fix

# Audit only one category
/repo-readiness --category agent_context

# Print summary without writing a report file
/repo-readiness --no-report
```

---

## Categories

| Category | Weight | What It Checks |
|----------|--------|----------------|
| Agent Context Files | 30% | CLAUDE.md exists, layered, not bloated, no external doc links |
| In-Repo Documentation | 20% | README covers what/run/test, docs live in-repo, ADRs present |
| Codebase Structure | 20% | Module separation, no giant files, shared utilities extracted |
| Test Coverage | 15% | Test framework configured, test files exist, tests runnable without secrets |
| Observability | 15% | Structured logging, health endpoint, error paths distinguishable |

---

## Score Bands

| Score | Band | What It Means |
|-------|------|---------------|
| 90–100 | Agent-Ready | Ready for `/dev-loop`. Minimal coaching needed. |
| 75–89 | Mostly Ready | Light gaps. Shipwright tasks will work well. |
| 50–74 | Needs Investment | `/dev-loop` will underperform. Fix critical + high gaps first. |
| 25–49 | Not Ready | Agent sessions will be slow and error-prone. Bootstrap required. |
| 0–24 | Unprepared | Starting from scratch. Run `--fix` to generate baseline assets. |

**Critical gap rule:** If no CLAUDE.md exists, or no test framework is configured, the overall band is capped at "Not Ready" — regardless of everything else.

---

## Output

Running `/repo-readiness` writes `readiness-report.md` to the project root:

```
REPO READINESS REPORT — my-project
Generated: 2026-03-29
Overall: 62/100 — Needs Investment

CATEGORY BREAKDOWN
━━━━━━━━━━━━━━━━━━
Agent Context Files      40/100  Not Ready
  [✓] AC-1 CLAUDE.md exists
  [✗] AC-2 Not layered — single CLAUDE.md, no subdirectory files
  [✓] AC-3 Under 500 lines
  [✗] AC-4 Notion link found in CLAUDE.md (line 12)
...

GAPS (sorted by severity)
━━━━━━━━━━━━━━━━━━━━━━━━━━
high
  AC-2 — CLAUDE.md is not layered. Add CLAUDE.md files to key subdirectories.
  AC-4 — Architecture linked to Notion (1 link). Move content to docs/architecture.md.
...
```

---

## Customization

Copy the default criteria to your project and edit:

```bash
mkdir -p .claude/repo-readiness
cp <plugin-path>/skills/repo-readiness/readiness-criteria.yaml .claude/repo-readiness/criteria.yaml
```

The project-level criteria file takes precedence. You can:
- Adjust category weights (must sum to 100)
- Add custom checks with your own `detection_hint`
- Disable checks by setting `severity: skip`

---

## Pairs With

- **`/entropy-scan`** — ongoing drift detection after readiness is established
- **`/plan-session`** — structured planning once the repo is agent-readable
- **`damage-control`** — prevents regressions after the repo is cleaned up

---

## Installation

```bash
claude mcp add repo-readiness <plugin-path>
```

Or load the plugin directly in your Claude Code session by pointing to the plugin directory.
