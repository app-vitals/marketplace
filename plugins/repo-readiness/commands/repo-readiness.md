# /repo-readiness

Audit the current codebase for agent-readiness gaps. Score each category. Optionally bootstrap missing pieces.

## Usage

```
/repo-readiness [--fix] [--category <id>] [--no-report]
```

## Flags

| Flag | Description |
|------|-------------|
| _(none)_ | Full audit + write `readiness-report.md` |
| `--fix` | Audit + generate bootstrap assets for each failing check |
| `--category <id>` | Audit only one category (e.g. `agent_context`, `test_coverage`) |
| `--no-report` | Print summary to stdout; skip writing `readiness-report.md` |

## Examples

```
/repo-readiness
/repo-readiness --fix
/repo-readiness --category test_coverage
/repo-readiness --no-report
```

## Output

- **Audit only:** writes `readiness-report.md` with per-category scores and gap list
- **With --fix:** writes `readiness-report.md` + generates missing assets (CLAUDE.md, test stubs, ADR template, health endpoint, etc.)

## Pairs With

- `/entropy-scan` — run after readiness is established for ongoing drift detection
- `/plan-session` — run after readiness is established for structured planning
