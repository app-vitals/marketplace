# Shipwright Lite

A streamlined dev pipeline plugin built on top of what Claude Code now does natively.

Shipwright is an excellent piece of work — it established the planning doc format, the CI fix loop, metrics tracking, and the review pipeline that this team runs on. This plugin is not a replacement. It's an experiment: **start with the minimum viable harness, measure it against Shipwright, and add back proven pieces as needed.**

## Why

Shipwright was built when Claude Code was younger. Over the past year, the platform has grown significantly — native plan mode, the Agent tool with worktree isolation, TodoWrite for task tracking, and stronger out-of-the-box code intelligence. Features that required custom scaffolding in early 2025 are now handled natively or with lighter prompting.

This creates an opportunity to test a leaner pipeline:

- Planning happens conversationally (in Slack with Bodhi) rather than through a structured 10-phase command
- Execution and review run as autonomous crons rather than manually-invoked skills
- Token costs are visible per-task (headless runs expose usage) — enabling direct cost comparison
- The todos queue is the shared state, replacing the planning doc as the execution artifact

The goal is a metrics-grounded answer to: **how much of Shipwright's scaffolding does the job actually need?**

## Comparison

| Capability | Shipwright | Shipwright Lite |
|---|---|---|
| Planning | 10-phase `/plan-session` command | Conversational planning with Bodhi in Slack |
| Web research during planning | Via `/research` agent | Built into planning conversation |
| Codebase exploration | Phase 3 structured scan | Natural exploration during planning |
| Task format | Planning doc markdown | `todos.json` entries with session grouping |
| Execution trigger | Manual `/dev-task {id}` | Cron-driven (picks next ready task) |
| Parallelism | Up to 3 parallel tasks (dev-loop) | Sequential (one task per cron tick, tunable frequency) |
| Autonomous loop | `/dev-loop` | Not needed — cron handles iteration |
| Review trigger | Manual `/review` | Cron-driven, session-aware PR grouping |
| Token cost tracking | Not tracked | Per-task (input/output/cost split by phase) |
| Metrics | `metrics.jsonl` per session | Same format — directly comparable |
| Learning loop | learning-loop plugin | Built into execution and review phases |
| Toolchain detection | Explicit Phase 0 in every command | Inline when needed |
| Plugin checks | Every command startup | Not needed |
| Complexity scoring | Yes (for dev-loop routing) | Not needed (no dev-loop) |
| Permission pre-flight | Phase 7 of plan-session | Not needed (tools pre-approved) |
| Planning retrospective | Phase 9 (rates planning quality) | Not needed |
| 5-agent parallel review | Always | Single agent (extend if quality insufficient) |

**What's deliberately excluded (for now):**
- `dev-loop` — sequential cron is simpler; add back if throughput becomes a bottleneck
- Multi-agent review — single agent review first; add back if quality data warrants it
- Complexity scoring — useful if model routing is needed; add back with autonomous mode
- Permission pre-flight — tools are pre-approved in the Bodhi cron context
- Planning retrospective — useful for tuning Shipwright itself; not needed for lean experiment

## Commands

| Command | Description |
|---|---|
| `/plan` | Kick off a planning session with Bodhi — explore the problem, research solutions, produce tasks in the queue |
| `/dev-task` | Execute the next ready task — implement, test, lint, create PR, update queue, capture metrics |
| `/review` | Review open PRs grouped by session — patch CI failures, address blocking comments, merge when green |

## Workflow

```
/plan (Slack with Bodhi) → todos.json queue → /dev-task cron → /review cron → merged
```

### 1. Plan (human in the loop)

Start a Slack conversation with Bodhi. Describe the problem. Bodhi will:
- Explore the relevant codebase
- Research what others are doing (web search)
- Work toward the simplest solution that fits the existing patterns
- Break work into tasks with explicit acceptance criteria and dependencies
- Write tasks to `todos.json` with the full schema (session, repo, deps, command)

### 2. Execute (autonomous cron)

The execution cron picks the next ready task (all dependencies `merged`) and runs end-to-end:
- Set up a worktree on a fresh branch
- Implement (code + tests + doc updates)
- Run lint and tests
- Create PR
- Update task status in todos
- Write per-task metrics
- Capture learnings to CLAUDE.md

### 3. Review (autonomous cron)

The review cron processes open PRs grouped by planning session:
- Review code against acceptance criteria
- Patch failing CI checks
- Address blocking review comments
- Merge when green and approved
- Update task status to `merged`
- Write review metrics
- Capture learnings to CLAUDE.md

## Metrics

Every task writes a metrics record to `planning/{session}/metrics.jsonl` — the same location and format as Shipwright, enabling direct comparison.

```json
{
  "task_id": "TS-1.1",
  "session": "may-billing-refactor",
  "repo": "vitals-os",
  "queued_at": "...",
  "execution_started_at": "...",
  "pr_created_at": "...",
  "merged_at": "...",
  "ci_attempts": 1,
  "review_iterations": 0,
  "first_time_merge": true,
  "learnings_captured": 2,
  "tokens": {
    "execution": { "input": 28000, "output": 6000, "cost_usd": 0.12 },
    "review": { "input": 14000, "output": 2500, "cost_usd": 0.06 },
    "total_cost_usd": 0.18
  }
}
```

## Roadmap

Features from Shipwright that may be added back as the metrics justify them:

- **Multi-agent review** — if single-agent review quality is insufficient (measure: review iteration rate)
- **Parallel execution** — if sequential throughput becomes a bottleneck (measure: time-to-merge)
- **Complexity scoring** — if model routing is needed for cost optimization
- **Dev-loop** — if cron-per-task overhead outweighs the simplicity benefit
- **Planning retrospective** — if planning quality becomes a bottleneck (measure: rework rate)

The metrics format is intentionally compatible with Shipwright so the comparison is apples-to-apples.
