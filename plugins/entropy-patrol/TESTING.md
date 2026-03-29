# Testing entropy-patrol

_Test plan will be written in EP-4.1 (entropy-fix command). This file is a placeholder._

## What gets tested

- `/entropy-scan --init` copies default `golden-principles.yaml` to `.claude/entropy-patrol/`
- Scanner reads default rules when no local config exists
- Scanner reads local config when `.claude/entropy-patrol/golden-principles.yaml` exists
- `entropy-report.md` output shape matches expected format
- `/entropy-fix` only opens PRs for rules with `pr_worthy: true`
- Blast radius cap: no PR touches more than 3 files

## How to run a manual smoke test

_Instructions will be added after EP-3.1 (scan command) is complete._
