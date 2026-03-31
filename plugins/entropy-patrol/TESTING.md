# Testing entropy-patrol

_Test plan will be written in EP-4.1 (entropy-fix command). This file is a placeholder._

## What will be tested

- `/entropy-scan --init` copies default `golden-principles.yaml` to `.claude/entropy-patrol/` _(planned — EP-3.1)_
- Scanner reads default rules when no local config exists _(planned — EP-3.1)_
- Scanner reads local config when `.claude/entropy-patrol/golden-principles.yaml` exists _(planned — EP-3.1)_
- `entropy-report.md` output shape matches expected format _(planned — EP-3.1)_
- `/entropy-fix` only opens PRs for rules with `pr_worthy: true` _(planned — EP-4.1)_
- Blast radius cap: no PR touches more than 3 files _(planned — EP-4.1)_

## How to run a manual smoke test

_Instructions will be added after EP-3.1 (scan command) is complete._
