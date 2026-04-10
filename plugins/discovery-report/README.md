# Discovery Report

Generate a polished dark-theme HTML discovery report for any technical or organizational investigation. Interviews you, gathers evidence, and produces a single self-contained HTML file you can open in a browser or upload to Confluence.

Use it for incident post-mortems, root-cause write-ups, latency investigations, capacity reviews, or any structured document that explains *what happened, why, and what was done about it*.

## Installation

```
/plugin install discovery-report@app-vitals/marketplace
```

No commands to remember — the skill activates automatically when you ask Claude to "write a discovery report", "summarize an investigation", "generate a post-mortem", or similar.

## What It Does

Runs a 6-phase workflow:

1. **Context detection** — Is this a new report or an update to an existing one?
2. **Interview** — Walks through 8 structured sections (problem, pain/impact, discovery journey, metrics, root cause, fix, before/after, sources). Collects evidence cues as you go (Grafana queries, source files, commits, Confluence pages, etc.).
3. **Visual component selection** — Picks the right components for each section from a decision matrix (stat cards, timelines, arch flow diagrams, before/after cards, formula boxes, callouts, tables, code blocks, phase lists).
4. **HTML generation** — Writes a self-contained HTML file with complete dark-theme CSS. Every factual claim traces to an entry in the auto-populated Sources & Evidence section.
5. **Optional Confluence upload** — If you have the Atlassian MCP available, offers to publish the report as a Confluence page.
6. **Optional PDF export** — Offers to also produce a PDF via Playwright + headless Chromium. Off-the-shelf HTML→PDF tools (wkhtmltopdf, weasyprint, browser print CLIs) routinely fail on modern CSS used by the template; Playwright renders the report 1:1 with a real browser. Requires `uv` and a one-time chromium download (~200MB).

## What You Get

- A single `.html` file named `<slug>-discovery-report.html`
- Fully self-contained (no external CSS/JS) — works offline, easy to email or attach
- Dark-theme CSS with 9 reusable component types
- Every claim backed by an entry in the Sources & Evidence table
- Mandatory visual components per section — no all-prose walls of text

## Hard Rules

The skill enforces:

- **Every data section has a visual component** — no prose-only sections when evidence exists
- **Section 3 (Discovery Journey) uses a timeline** if any dead-ends existed
- **Section 4 (Key Metrics) has stat cards AND code/table evidence**
- **Section 7 (Before/After) uses before/after cards**
- **Section 8 (Sources & Evidence) is always present and always populated**
- **Credentials are never written to the HTML file**

## Quick Start

Tell Claude:

> "Write a discovery report for the checkout-api 504 incident from last Tuesday. The root cause was a Redis connection leak. Just generate it — skip the full interview."

The skill has an escape hatch: if you ask to skip the interview, it only requires the problem statement, root cause, and fix — then generates the file.

For a full-fidelity report, let the interview run its course. It will ask evidence-tracking questions so the Sources section captures every Grafana query, source file, and Confluence page you touched.

## Plugin Structure

```
discovery-report/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── TESTING.md
├── references/
│   ├── report-structure.md    # 8-section interview guide
│   ├── html-template.md       # Complete CSS + copy-paste HTML components
│   └── pdf-generation.md      # Playwright-based HTML→PDF invocation + troubleshooting
├── scripts/
│   └── html-to-pdf.py         # Standalone Playwright conversion script
└── skills/discovery-report/
    └── SKILL.md               # Core skill — 6-phase workflow
```

Note: `references/` live at the plugin root (not inside `skills/discovery-report/`) because SKILL.md uses `${CLAUDE_PLUGIN_ROOT}/references/...` paths. Both layouts are valid per Claude Code spec.
