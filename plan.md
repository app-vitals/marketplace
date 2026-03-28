# App Vitals Marketplace — Plugin Roadmap

New plugins grounded in Anthropic + OpenAI harness engineering research (March 2026). See `app-vitals/strategy/harness-architecture.md` for the full research synthesis.

**Philosophy:** Implement when the need arises — don't build speculatively. Each plugin here solves a real problem identified in production harness engineering. The goal is a composable toolkit that lets teams progressively adopt better harness patterns as their needs mature.

---

## Existing Plugins

| Plugin | What It Does |
|--------|-------------|
| `shipwright` | Full dev pipeline: plan → build → review → merge |
| `damage-control` | Prevents dangerous patterns from entering the repo (hooks-based) |
| `learning-loop` | Captures review findings as learnings, promotes to CLAUDE.md |
| `ralph-orchestrator` | Multi-agent orchestration for large freeform builds |
| `pr-review` | Standalone PR review without full shipwright pipeline |
| `dependabot-review` | Triage and merge Dependabot PRs |
| `distill` | Distill session context into structured docs |
| `meeting-transcripts` | Process and extract action items from meeting transcripts |

---

## Planned Plugins

### `entropy-patrol`

**Problem:** Agents replicate patterns that already exist in the codebase — even suboptimal ones. Over time this leads to drift: inconsistent naming, hand-rolled helpers duplicating shared utilities, validation bypassed in edge cases. `damage-control` prevents new bad patterns from entering; nothing cleans up existing ones.

**What it does:** A recurring cleanup plugin that:
1. Scans the codebase for deviations from project "golden principles" (configurable rules per repo)
2. Grades each deviation by severity and blast radius
3. Opens targeted, reviewable refactoring PRs — one concern at a time, auto-mergeable when safe
4. Updates a quality log tracking drift over time

**Key insight from OpenAI:** Manual cleanup (they spent every Friday on it — 20% of the week) doesn't scale. Human taste needs to be captured once in rules and enforced continuously.

**Commands:** `/entropy-scan` (report only), `/entropy-fix` (scan + open PRs)

**Pairs with:** `damage-control` (prevention), `learning-loop` (promotes patterns to CLAUDE.md → becomes golden principles)

**Scope:** Medium. Plugin needs a configurable rules format, a scanning agent, and PR-opening logic.

---

### `repo-readiness`

**Problem:** Before running `/dev-loop` on a codebase, there's a set of legibility investments that dramatically affect agent performance — but no way to assess or bootstrap them. Teams start with shipwright on a repo that's not agent-ready and get mediocre results without understanding why.

**What it does:** A readiness assessment + bootstrapping plugin:
1. **Audit** — scans the repo and flags: docs living outside the repo (links to Confluence/Notion/Google Docs), missing or oversized CLAUDE.md/AGENTS.md, no layered architecture, missing test coverage, no observability hooks
2. **Score** — produces a readiness score per category with specific, actionable gaps
3. **Bootstrap** (optional) — generates the missing pieces: lean CLAUDE.md map, layered architecture diagram, placeholder `docs/` structure, observability setup guide

**Key insight from OpenAI:** "If it's not in the repo, it doesn't exist to the agent." A repo readiness audit makes this concrete and actionable before the team is frustrated by poor results.

**Commands:** `/repo-readiness` (audit + score), `/repo-readiness --fix` (audit + bootstrap gaps)

**Pairs with:** `shipwright` (ideally run before first `/plan-session`), `entropy-patrol` (readiness → ongoing cleanliness)

**Scope:** Medium–large. Needs audit heuristics, scoring model, and bootstrapping templates.

---

## Future Thinking

These aren't ready to plan yet but are worth tracking:

- **`application-legibility`** — Guide + checklist for making an app observable to agents: worktree-per-change setup, local observability stack (LogQL/PromQL), Chrome DevTools integration. Probably a reference doc rather than a plugin.
- **`quality-dashboard`** — Cross-repo quality tracking: aggregate quality scores from multiple projects, track trends, surface where investment is needed. Useful once `shipwright` quality scoring and `entropy-patrol` are both producing data.

---

_Last updated: March 2026_
