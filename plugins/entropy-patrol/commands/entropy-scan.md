---
name: entropy-scan
description: Scan codebase for golden principle deviations and generate an entropy report. Flags: --init (create starter config), --summary (print summary only, skip report file).
---

# /entropy-scan

Scan the codebase against your golden principles and generate `entropy-report.md`. Report only — no code changes.

**Flags:**
- `--init` — copy the default `golden-principles.yaml` to `.claude/entropy-patrol/` so you can customize rules for this project, then stop
- `--summary` — print a category summary to stdout without writing the full report file (useful for quick checks or CI)

Invoke the entropy-scan skill.
