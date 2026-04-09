---
name: discovery-report
description: Use when asked to write a discovery report, investigation summary, incident post-mortem, root cause analysis, or any structured document that explains what happened, why, and what was done about it. Produces a self-contained dark-theme HTML file.
---

# Discovery Report Skill

## Reference Files

Load these files as needed during execution:
- `${CLAUDE_PLUGIN_ROOT}/references/report-structure.md` — section-by-section interview questions
- `${CLAUDE_PLUGIN_ROOT}/references/html-template.md` — complete CSS + copy-paste HTML components
- `${CLAUDE_PLUGIN_ROOT}/references/pdf-generation.md` — Playwright-based HTML→PDF conversion (Phase 6)

---

## Phase 1 — Context Detection

First, determine the starting point.

**If the user references an existing report file** (e.g., "update the discovery report" or names an
existing `.html` file in the working directory):
- Read that file
- Ask: "What would you like to add or change?"
- Jump to Phase 3 with the new information

**If this is a new investigation:**
- Proceed to Phase 2

---

## Phase 2 — Interview

Load `${CLAUDE_PLUGIN_ROOT}/references/report-structure.md`.

Work through the sections in order. For each section:
1. Ask the section's key questions (from report-structure.md)
2. Listen for evidence cues — any time the user mentions a number, metric, query result, file, or
   system, note the evidence source in your working context:
   - **Grafana** — PromQL or CloudWatch metric queries
   - **CloudWatch** — AWS-native metrics via Grafana CloudWatch datasources
   - **Source file** — specific file path and line in a repo
   - **Git commit** — SHA and message
   - **Confluence page** — URL or space/title
   - **Notion page** — URL or title
   - **Web search** — URL or search query used
   - **Kubernetes object** — resource type, namespace, name
   - **Verbal** — information from a named person (note their name)
3. If the user says a section is not applicable, skip it

As you gather answers, actively gather evidence:
- If the user says "we looked at the Grafana data," ask for the query or run it yourself if the
  grafana skill is available
- If the user references a file, read it
- If the user mentions a Confluence page, fetch it if the Atlassian MCP is available

Do not move to Phase 3 until you have answers for at least sections 1, 3, and 5 (the minimum
required for a coherent report). Section 8 (Sources) is auto-populated — never ask about it.

---

## Phase 3 — Visual Component Selection

Load `${CLAUDE_PLUGIN_ROOT}/references/html-template.md`.

For each section with content, select visual components using this decision matrix:

| Situation | Component |
|-----------|-----------|
| Multiple key numbers to highlight at a glance (failure rates, latency values, counts) | **Stat cards row** — `.stats-row` + `.stat-card.bad/.good/.info/.warn` |
| Sequence of investigation steps, especially with wrong turns or dead ends | **Timeline** — `.timeline` + `.tl-item` with `.dead-end` and `.success` markers |
| How systems connect to each other, data flow, or topology | **Architecture flow** — `.arch-flow` + `.arch-box` + `.arch-arrow` |
| Side-by-side before/after comparison | **Before/After cards** — `.before-after` + `.ba-card.before` and `.ba-card.after` |
| A calculation with visible inputs, formula, and derived result | **Formula box** — `.formula` + `.result` |
| A single key insight, warning, root cause statement, or resolution | **Callout** — `.callout.red` (critical), `.callout.yellow` (warning), `.callout.blue` (info), `.callout.green` (resolution) |
| Tabular data: query results, scope table, metric breakdown, environment list | **Table** with optional `.badge.fix/.skip/.done` cells |
| Exact commands, queries, config diffs, or YAML changes | **Code block** — `<pre><code>` with `.diff-add`, `.diff-ctx`, `.comment`, `.keyword`, `.string`, `.number` spans |
| Numbered steps (deployment path, fix phases, remediation plan) | **Phase list** — `.phase-list` + `.phase-item` + `.phase-num` |

**Mandatory rules:**
- Every section that contains data MUST have at least one visual component
- Section 3 (Discovery Journey) MUST use a timeline if any dead-ends or wrong turns existed
- Section 4 (Key Metrics) MUST use stat cards for headline numbers AND at least one table or code block showing evidence
- Section 7 (Before/After) MUST use before/after cards
- Callouts are best used sparingly — one per section maximum, for the single most important point
- Never render a section as plain paragraphs only if data or structure is present

---

## Phase 4 — HTML Generation

### Output File

Name the file using the investigation slug: `<slug>-discovery-report.html`
Examples: `issue-1-discovery-report.html`, `latency-spike-discovery-report.html`

Write it to the current working directory unless the user specifies otherwise.

### Structure

```
<!DOCTYPE html>
<html>
  <head>
    <!-- Complete CSS from html-template.md — DO NOT abbreviate -->
  </head>
  <body>
    <div class="page">
      <header class="report-header">...</header>  <!-- header block -->
      <section><!-- Section 1 --></section>
      <section><!-- Section 2 --></section>
      <section><!-- Section 3 --></section>
      <section><!-- Section 4 --></section>
      <section><!-- Section 5 --></section>
      <section><!-- Section 6 --></section>
      <section><!-- Section 7 --></section>
      <section><!-- Section 8: Sources & Evidence --></section>
      <footer class="report-footer">...</footer>
    </div>
  </body>
</html>
```

### CSS Fidelity

Copy the complete CSS from `html-template.md` verbatim. Do not:
- Abbreviate the `:root` block
- Omit component styles for components you are using
- Inline styles instead of using the class system (except for one-off color overrides)

### Section 8 — Sources & Evidence (always present)

Build a table of every piece of evidence used in the report:

| Source Type | Name / URL / Query | What It Proved | Used In |
|-------------|-------------------|----------------|---------|
| Grafana query | `<metric expression>` | `<claim it supports>` | Section N |
| CloudWatch query | `namespace/metric @ datasource UID` | ... | ... |
| Source file | `path/to/file.yaml:42` | ... | ... |
| Git commit | `abc1234 — commit message` | ... | ... |
| Confluence page | `Space/Title (URL)` | ... | ... |
| Notion page | `Title (URL)` | ... | ... |
| Web search | `query string` | ... | ... |
| Kubernetes object | `kind/namespace/name` | ... | ... |
| Verbal | `Person's name` | ... | ... |

Every factual claim that appears in Sections 1–7 must trace back to at least one row in this table.
If a claim came from the user without an external source, use **Verbal** with the user's name.

### Footer

```html
<footer class="report-footer">
  Generated with Claude Code · <em>discovery-report</em> skill ·
  Report date: <date>
</footer>
```

---

## Phase 5 — Optional Confluence Upload

After the HTML file is written, offer once:

> "Would you like me to create a Confluence page from this report? If so, tell me the space key
> and folder name."

If the user says yes:
1. Use `searchConfluenceUsingCql` to find the target folder/ancestor page ID
2. Convert the report to Markdown (structured content, not raw HTML)
3. Create the page with `contentFormat: "markdown"` using `createConfluencePage`
4. Return the URL

---

## Phase 6 — Optional PDF Export

After Phase 5 completes (whether the user accepted or declined the Confluence upload), offer once:

> "Would you like a PDF version of this report as well? It uses Playwright + headless Chromium,
> which renders the dark theme and all visual components faithfully. Requires `uv` and a one-time
> ~200MB chromium download."

If the user says yes:

1. Load `${CLAUDE_PLUGIN_ROOT}/references/pdf-generation.md` for the full invocation and
   troubleshooting guidance
2. Check prerequisites: `uv --version` must succeed
3. If this is the first run (no `~/.cache/ms-playwright/` directory), run:
   ```bash
   uv run --with playwright playwright install chromium
   ```
   Warn the user this takes 1–2 minutes on first run only
4. Run the conversion script against the HTML file:
   ```bash
   uv run --with playwright python "${CLAUDE_PLUGIN_ROOT}/scripts/html-to-pdf.py" \
     <path-to-report.html> <path-to-report.pdf>
   ```
   By default, write the PDF next to the HTML file with the same slug (replace `.html` → `.pdf`)
5. Return the absolute path to the PDF and its size

**Why Playwright:** Other HTML→PDF tools (wkhtmltopdf, weasyprint, browser print-to-PDF CLIs)
regularly fail on modern CSS features used in the template — CSS grid, flexbox, CSS variables,
and custom background colors. Chromium via Playwright renders the file exactly as a browser
does, so the PDF matches the HTML 1:1 with no layout drift.

If `uv` is not installed, fall back to instructing the user:
- Install uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Or use pip: `pip install playwright && playwright install chromium`, then run the script
  directly with `python scripts/html-to-pdf.py`

---

## Hard Rules

- **Never** skip the Sources & Evidence section — it is mandatory in every report
- **Never** produce a report with all-prose sections when data is available; always use a visual component
- **Never** write the session cookie or any credential to the HTML file or any other file
- **Always** write the file to disk — do not output the HTML to the chat only
- If the user asks to skip the interview ("just generate it"), ask for the minimum: problem statement, root cause, and fix — then generate
