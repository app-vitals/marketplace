# Readiness Score Reference

## How Scores Are Calculated

Each category produces a score from 0–100.

**Per check:**
- critical pass: +40
- high pass: +20
- medium pass: +15
- low pass: +10
- (raw totals are normalized to 0–100 per category)

**Overall score** = weighted average across categories, using `weight` values from `readiness-criteria.yaml`.

Default weights:
- Agent Context Files: 30%
- In-Repo Documentation: 20%
- Codebase Structure: 20%
- Test Coverage: 15%
- Observability: 15%

## Score Bands

| Score | Label | Meaning |
|-------|-------|---------|
| 90–100 | Agent-Ready | Ready for `/dev-loop`. Minimal coaching needed. |
| 75–89 | Mostly Ready | Ready for shipwright tasks with light scaffolding. A few gaps to fill. |
| 50–74 | Needs Investment | `/dev-loop` will underperform. Fix critical + high gaps first. |
| 25–49 | Not Ready | Agent sessions will be slow and prone to mistakes. Bootstrap required. |
| 0–24 | Unprepared | Starting from scratch. Run `--fix` to generate baseline assets. |

## Critical Gaps

If any `critical` check fails, the overall band is capped at **Not Ready**, regardless of weighted score.

Critical checks:
- AC-1: CLAUDE.md or AGENTS.md exists
- TC-1: Test framework is configured

These two gaps cause the most agent failure. Even a perfect score on everything else doesn't compensate.

## Report Format

The readiness report (`readiness-report.md`) uses this structure:

```
REPO READINESS REPORT — {repo_name}
Generated: {date}
Overall: {score}/100 — {band}

CATEGORY BREAKDOWN
━━━━━━━━━━━━━━━━━━
Agent Context Files      {score}/100  {band}
  [✓] AC-1 CLAUDE.md exists
  [✗] AC-2 Not layered
  [✓] AC-3 Under 500 lines
  [✗] AC-4 Notion links found (3)

In-Repo Documentation    {score}/100  {band}
  ...

GAPS (sorted by severity)
━━━━━━━━━━━━━━━━━━━━━━━━━━
critical
  AC-1 — No CLAUDE.md or AGENTS.md found.
         Run /repo-readiness --fix to generate a starter CLAUDE.md.

high
  AC-4 — Architecture links to external docs (Notion, Confluence).
         Move key context into docs/ or ARCHITECTURE.md.
  ...

NEXT STEPS
━━━━━━━━━━
Run /repo-readiness --fix to bootstrap the missing pieces.
Or address gaps manually using the descriptions above.
```
