# Discovery Report Structure

Interview guide for the `discovery-report` skill. Work through sections in order.
Skip any section the user says is not applicable. Section 8 is auto-populated — never ask about it.

---

## Section 1 — The Problem in Plain English

**Goal:** A jargon-free explanation any engineer can follow.

**Key questions:**
- What failed or went wrong? Describe it as a user/operator would experience it.
- Who first noticed the problem? When was it first reported?
- What is the system involved? Give a one-sentence description of what it normally does.
- Is this a recurring issue, a new one, or something discovered during investigation?

**Recommended components:**
- `.callout.red` — one sentence stating the core problem
- `.arch-flow` — if the failure involves an interaction between systems (not required for simple single-system issues)

**Skip if:** The report is purely analytical with no failure event (e.g., capacity planning report).

---

## Section 2 — The Pain & Impact

**Goal:** Quantify the cost so the reader understands why the fix matters.

**Key questions:**
- What is the user-visible symptom? What does the on-call engineer see?
- How often does the failure occur? Is it every deploy, intermittent, or one-time?
- Which environments or regions are affected?
- What is the manual workaround? How long does it take per occurrence?
- How many times has it happened in the last week/month?

**Recommended components:**
- `.stats-row` with `.stat-card.bad` — headline numbers (failure rate, frequency, blast radius)
- `.callout.yellow` — the ongoing cost or urgency

**Skip if:** The investigation is purely exploratory with no user-visible impact.

---

## Section 3 — The Discovery Journey

**Goal:** Show the path taken — including wrong turns — so others can learn from it.

**Key questions:**
- What was your first hypothesis? What did you check first?
- Were any hypotheses ruled out? Why? What was the dead end?
- What was the turning point that led you to the real cause?
- What tools, queries, or data sources were used at each step?
- Were there any surprising findings (e.g., a metric that returned no data)?

**Recommended components:**
- `.timeline` with `.tl-item.dead-end` for wrong turns and `.tl-item.success` for the breakthrough
  — REQUIRED if any dead-ends existed
- Code blocks for any queries run during investigation

**Skip if:** The root cause was immediately obvious with no investigation steps.

**Tips:**
- Mark each step as "dead end," "neutral step," or "breakthrough" to set `.tl-item` class
- Include the specific tool used (Grafana, `kubectl`, `git log`, etc.) in each timeline entry

---

## Section 4 — Key Metrics & Data

**Goal:** Show the raw evidence. This is the "proof" section.

**Key questions:**
- What specific query or command produced the key data point?
- What were the exact numbers? Across which dimensions (regions, clusters, time ranges)?
- Was there any surprising absence of data (e.g., zero results for certain environments)?
- What time window was measured? Why that window?

**Recommended components:**
- `.stats-row` with `.stat-card` — headline numbers (REQUIRED)
- `<pre><code>` — the exact query that was run (REQUIRED)
- `<table>` — results broken down by region/cluster/service
- `.formula` + `.result` — if a value was calculated from observed data
- `.callout.blue` — explanation of why certain data was absent or surprising

**Tips:**
- For Grafana/CloudWatch queries, include the datasource UID in a comment in the code block
- For tables, use `.badge.fix` / `.badge.skip` / `.badge.done` in the Action column to indicate scope

---

## Section 5 — Root Cause

**Goal:** One clear sentence stating why the problem occurred.

**Key questions:**
- Complete this sentence: "The failure occurred because ___"
- What system property or configuration made this possible?
- What assumption was wrong?
- Is this a code bug, configuration gap, timing issue, infrastructure behavior, or process gap?

**Recommended components:**
- `.callout.red` — the one-sentence root cause (REQUIRED)
- Brief prose explanation (1-3 paragraphs max) — no additional components needed unless explaining
  a multi-system interaction, in which case `.arch-flow` is appropriate

---

## Section 6 — The Fix

**Goal:** Explain what changed and why it works — mechanistically.

**Key questions:**
- What file(s) were changed? (include exact paths)
- What is the mechanism by which the change fixes the problem?
- Is the fix opt-in (conditional) or applied to all environments?
- Are there any environments that should NOT get the fix? Why?
- What is the deployment path? (e.g., Helm chart → Flux → Kubernetes)

**Recommended components:**
- `<pre><code>` with `.diff-add` / `.diff-ctx` — the actual code/config diff (REQUIRED)
- `.phase-list` — if there are multiple steps in the fix (e.g., 3 file changes + PR + merge)
- `.callout.blue` — if there is an important opt-in/scope note

**Tips:**
- Use `.diff-add` (green) for added lines and `.diff-ctx` (muted) for unchanged context lines
- Include a comment line with the filename above each diff block

---

## Section 7 — Before & After

**Goal:** Side-by-side comparison showing the behavioral difference.

**Key questions:**
- What was the behavior before the fix?
- What will the behavior be after the fix?
- Are there any secondary effects (positive or negative)?

**Recommended components:**
- `.before-after` with `.ba-card.before` and `.ba-card.after` — REQUIRED for this section
- Each card should have 3-5 bullet points with `✕` icons on the Before side and `✓` icons on the After side

**Skip if:** The report is purely analytical (no fix was implemented or proposed).

---

## Section 8 — Sources & Evidence

**Auto-populated. Do not ask the user about this section.**

Build from evidence gathered during the interview and investigation.

Source types to track:

| Type | When to use |
|------|-------------|
| **Grafana query** | Any PromQL metric queried via Grafana |
| **CloudWatch query** | Any AWS metric via Grafana CloudWatch datasource |
| **Source file** | Any repo file read during investigation (include path and line if relevant) |
| **Git commit** | Any commit referenced as evidence (SHA + message) |
| **Confluence page** | Any Confluence page consulted (space/title + URL) |
| **Notion page** | Any Notion page consulted (title + URL) |
| **Web search** | Any external search used to verify behavior (query string + key URL) |
| **Kubernetes object** | Any live k8s resource inspected (kind/namespace/name) |
| **Verbal** | Any information provided directly by a person (use their name) |

Every factual claim in Sections 1–7 must trace to at least one entry here.

---

## Component Selection Quick Reference

| Section | Mandatory | Optional |
|---------|-----------|----------|
| 1 — Problem | `.callout.red` | `.arch-flow` |
| 2 — Pain | `.stats-row` | `.callout.yellow`, table |
| 3 — Journey | `.timeline` (if dead-ends) | code blocks |
| 4 — Metrics | `.stats-row`, code block | table, `.formula`, `.callout.blue` |
| 5 — Root Cause | `.callout.red` | `.arch-flow` |
| 6 — Fix | code diff | `.phase-list`, `.callout.blue` |
| 7 — Before/After | `.before-after` | — |
| 8 — Sources | table | — |
