# entropy-patrol

Continuous code health enforcement for Claude Code projects.

---

## The Problem

Code quality isn't a one-time decision — it's a practice. Teams agree on standards, then drift happens. TODOs accumulate. Untested files multiply. Dead exports linger. Nobody's fault; everyone's problem.

OpenAI's research on developer AI tools found that teams that used AI for "Friday cleanup" saw the largest sustained quality gains — not the teams that used it for feature work. The bottleneck isn't knowledge of what to fix; it's the activation energy to do it consistently.

entropy-patrol removes that friction. Scan. Get a report. Open focused PRs. Merge. Repeat.

---

## Quick Start

```
# 1. Initialize project config (copies default golden principles to your project)
/entropy-scan --init

# 2. Run your first scan
/entropy-scan

# 3. Fix pr_worthy violations (opens focused PRs)
/entropy-fix
```

That's the core loop. Three steps from zero to open PRs.

---

## Commands

### `/entropy-scan`

Scans the codebase against golden principles and writes `entropy-report.md`.

**Flags:**
- `--init` — copy default golden principles to `.claude/entropy-patrol/golden-principles.yaml` and exit (no scan)
- `--summary` — print counts to stdout only; skip writing `entropy-report.md` and quality log
- `--trend` — print trend summary from `.entropy-patrol/quality-log.jsonl`; skip scan
- `--trend --window N` — limit trend to last N scan entries (default: 30)

**Output:** `entropy-report.md` in the project root. One finding per line as a checkbox. Findings are sorted security first, then high → medium → low within each category.

**Quality log:** After each full scan, a log entry is appended to `.entropy-patrol/quality-log.jsonl`. Commit this file — it's your trend record. Use `--trend` to read it.

### `/entropy-fix`

Reads `entropy-report.md` and opens targeted PRs for `pr_worthy` violations. One PR per rule. Max 3 files changed per PR.

**Prerequisites:** Run `/entropy-scan` first.

**Flags:**
- `--dry-run` — preview what PRs would be opened; no branches, no changes, no PRs
- `--rule {id}` — fix only one specific rule (e.g., `--rule dead_exports`)

**Safety gates:**
- High-severity destructive fixes (code deletion) require explicit confirmation before proceeding
- All PRs require human review — entropy-patrol never auto-merges
- 10 PRs per run cap — re-run after merging to continue

---

## Default Golden Principles

Out of the box, entropy-patrol checks for 12 rules across 6 categories:

| Category | What it catches |
|----------|----------------|
| `security` | Ungated outbound HTTP POST/PUT, hardcoded secrets (API keys, tokens) |
| `missing_tests` | Source files without a corresponding `.test.ts`/`.spec.ts` |
| `dead_code` | Unused exports, unreferenced files, commented-out code blocks |
| `todo_debt` | TODO/FIXME/HACK comments older than the age threshold (default: 90 days) |
| `inconsistent_patterns` | Hand-rolled utilities that duplicate shared lib functions |
| `documentation_gaps` | Public functions without JSDoc, missing README sections |

Security rules run first (always highest priority). Within each category, high severity runs before medium, medium before low.

### `pr_worthy` flag

Each rule has a `pr_worthy: true/false` flag. Rules marked `pr_worthy: true` are candidates for `/entropy-fix` to open PRs. Rules marked false are reported in the scan but require manual remediation (they're too context-dependent for automated fixing).

---

## Configuration

Run `/entropy-scan --init` to copy the default rules to your project:

```
.claude/entropy-patrol/golden-principles.yaml
```

Edit this file to:
- Disable rules that don't apply to your codebase (`disabled: true`)
- Adjust age thresholds (`todo_max_age_days`)
- Change severity levels
- Add custom rules

Project config takes priority over plugin defaults. See `skills/entropy-scan/references/customization.md` for the full schema and customization patterns.

---

## Quality Log and Trends

After each full scan, entropy-patrol appends to `.entropy-patrol/quality-log.jsonl`:

```json
{"timestamp":"2026-03-28T21:15:00.000Z","commitSha":"abc1234","totalViolations":8,"bySeverity":{"high":0,"medium":5,"low":3},"byRule":{"todo_fixme_hack":4,"missing_test_file":4},"reportPath":"entropy-report.md"}
```

**Commit this file.** It's your trend record — preserved across environments and visible in git history.

View trends:
```
/entropy-scan --trend
/entropy-scan --trend --window 14   # last 14 scans
```

See `skills/entropy-scan/references/quality-log-schema.md` for the full schema.

---

## Plugin Ecosystem

entropy-patrol fits naturally with two other plugins:

| Plugin | Role |
|--------|------|
| **damage-control** | Prevents new drift from being introduced (PreToolUse hooks block dangerous patterns) |
| **entropy-patrol** | Fixes existing drift (scan → report → PRs) |
| **learning-loop** | Promotes patterns that work well into CLAUDE.md, which can then be promoted to golden principles |

Recommended workflow:
1. `damage-control` runs on every tool call — prevents regression
2. `entropy-patrol` runs weekly (or as a daily cron) — repairs accumulated drift
3. `learning-loop` promotes effective patterns — strengthens both prevention and repair over time

---

## Installation

Copy the plugin directory into your project's `.claude/plugins/` directory, or use the marketplace install command (see marketplace README for current install path).

After installation:
1. Run `/entropy-scan --init` to create your project config
2. Edit `.claude/entropy-patrol/golden-principles.yaml` to match your standards
3. Run `/entropy-scan` — review `entropy-report.md`
4. Run `/entropy-fix --dry-run` — preview what PRs would be opened
5. Run `/entropy-fix` — open your first batch of PRs

---

## License

MIT — see [LICENSE](https://github.com/app-vitals/marketplace/blob/main/LICENSE)
