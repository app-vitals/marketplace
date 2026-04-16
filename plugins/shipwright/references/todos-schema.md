# Todos Schema — Shipwright Tasks

Shipwright tasks live in `state/todos.json` alongside existing workspace todos.
The `source: "shipwright"` field distinguishes them from `eng-execute` tasks.

## Schema

```json
{
  "id": "TS-1.1",
  "source": "shipwright",
  "session": "may-billing-refactor",
  "repo": "vitals-os",
  "title": "Add billing schema migration",
  "description": "Add the new invoices table and billing period columns to the Prisma schema.",
  "acceptanceCriteria": [
    "Prisma schema includes invoices table with required fields",
    "Migration file generated and applies cleanly",
    "Existing tests pass after migration"
  ],
  "layer": "Database",
  "branch": "feat/ts-1-1-billing-schema-migration",
  "dependencies": [],
  "hours": 2,
  "status": "pending",
  "pr": null,
  "addedAt": "2026-04-12T10:00:00Z",
  "startedAt": null,
  "prCreatedAt": null,
  "mergedAt": null
}
```

## Status Flow

```
pending → in_progress → pr_open → approved → merged
                      ↘ blocked            ↗
```

| Status | Set by | Meaning |
|---|---|---|
| `pending` | `plan-session` | Queued, waiting for dependencies |
| `in_progress` | `dev-task` Step 2 | Execution has started |
| `pr_open` | `dev-task` Step 9 | PR created, waiting for review |
| `approved` | `review` | Review passed, merge pending |
| `merged` | `review` Step 13 | Merged, done |
| `blocked` | `dev-task` or `review` | Failed — needs human intervention |

## Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | string | Task ID — `{PREFIX}-{N}.{M}` format |
| `source` | `"shipwright"` | Distinguishes from `eng-execute` tasks |
| `session` | string | Planning session slug — groups tasks and PRs |
| `repo` | string | Repo name (e.g., `vitals-os`) |
| `title` | string | Short, verb-first task title |
| `description` | string | What to build |
| `acceptanceCriteria` | string[] | 2-5 specific, testable criteria |
| `layer` | string | API, Frontend, Database, Shared, Background, CLI |
| `branch` | string | Git branch name for this task |
| `dependencies` | string[] | Task IDs that must be `merged` first |
| `hours` | number | Rough estimate (1-8h) |
| `status` | string | See Status Flow above |
| `pr` | number \| null | PR number once created |
| `addedAt` | ISO string | When queued by `/plan` |
| `startedAt` | ISO string \| null | When execution began |
| `prCreatedAt` | ISO string \| null | When PR was opened |
| `mergedAt` | ISO string \| null | When PR was merged |

## Blocked Tasks

When a task is blocked, set:

```json
{
  "status": "blocked",
  "blockedAt": "2026-04-12T14:00:00Z",
  "note": "CI failing after 3 attempts: TypeScript error in billing/src/invoice.ts line 42 — 'amount' is not assignable to type 'Decimal'"
}
```

Blocked tasks surface in the morning brief and require human intervention before the execution cron picks them up again.

## Coexistence with eng-execute

Eng-execute tasks use `source: "eng-execute"` (or have no `source` field for legacy entries). The execution cron filters by `source: "shipwright"` so there is no conflict.

Status values `pr_open` and `merged` are new — eng-execute only uses `pending`, `done`, and `blocked`. These new values are ignored by the eng-execute cron.
