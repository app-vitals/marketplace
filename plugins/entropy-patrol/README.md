# entropy-patrol

Continuous code health enforcement for Claude Code projects.

## What it does

entropy-patrol scans your repo against a configurable set of "golden principles" — quality rules your team has agreed on — and surfaces drift before it compounds. When issues are found, it opens focused, human-reviewable PRs to fix them (one concern per PR, max 3 files changed).

Built to run as a daily cron or as an on-demand slash command.

## Commands

| Command | What it does |
|---------|-------------|
| `/entropy-scan` _(planned — EP-3.1)_ | Scan repo against golden principles, produce `entropy-report.md` |
| `/entropy-fix` _(planned — EP-4.1)_ | Consume `entropy-report.md`, open targeted fix PRs |

## Default golden principles

Out of the box, entropy-patrol checks for:

| Category | What it catches |
|----------|----------------|
| `dead_code` | Unused exports, unreferenced files, commented-out blocks |
| `missing_tests` | Source files without a corresponding `.test.ts` |
| `inconsistent_patterns` | Hand-rolled utilities that duplicate shared lib functions |
| `todo_debt` | TODO/FIXME/HACK comments older than the age threshold |
| `documentation_gaps` | Public functions without JSDoc, missing README sections |
| `security` | Ungated outbound HTTP POST/PUT, email sends, webhooks |

Customize these or add your own in `.claude/entropy-patrol/golden-principles.yaml`. See `skills/entropy-scan/references/customization.md`.

## Installation

_Installation instructions will be added in a future task._

## Configuration

Copy `skills/entropy-scan/golden-principles.yaml` to `.claude/entropy-patrol/golden-principles.yaml` in your project and edit. Local config takes priority over plugin defaults. See `skills/entropy-scan/references/customization.md` for the full override path.
