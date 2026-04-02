# Shipwright v1.4.0

A structured dev pipeline plugin for Claude Code. Plan sessions, execute tasks, run autonomous dev loops, and perform multi-agent code reviews — for any software project.

A shipwright builds ships. This one ships software.

## Installation

```
/plugin install shipwright@app-vitals/marketplace
```

## Commands

| Command | Description |
|---------|-------------|
| `/plan-session {folder}` | Structured planning — reads input docs, analyzes codebase, produces a stateful task breakdown |
| `/dev-task {task-id}` | Single task execution — branch, implement, test, simplify, review, PR |
| `/dev-task {task-id} --merge` | Same as above, but auto-merges after review (used by dev-loop) |
| `/dev-loop {folder?}` | Autonomous continuous dev — picks next task, runs dev-task --merge in a loop |
| `/metrics {project?}` | Analyze pipeline metrics — fix cascade trends, quality rates, and recommendations |
| `/refresh-plan {folder}` | Syncs planning doc against current codebase state |
| `/review` | Auto-detecting multi-agent code review for the current branch |

## Workflow

```
/plan-session → /dev-task (or /dev-loop) → /review → merge
```

### 1. Plan Session

Feed it a folder of requirements docs (PRDs, specs, wireframes) and it produces a structured task breakdown with:
- Auto-detected project layers and toolchain
- Granular tasks (1-8h each) with acceptance criteria
- Pre-answered implementation decisions for autonomous execution
- Branch names, dependency chains, and coverage targets
- Permission pre-flight for unattended operation

### 2. Dev Task

Picks up a task from the planning doc and runs end-to-end:
1. Extract task details from planning doc
2. Check dependencies
3. Create feature branch
4. Implement (discovery → architecture → code → tests → validate)
5. Simplify (DRY, dead code, naming, complexity)
6. Verify acceptance criteria against the diff
7. Run pre-ship checks (lint, types, tests, coverage)
8. Push and create PR
9. Update from main, wait for CI checks to pass (auto-fix failures up to 3 times)

With `--merge` flag, continues automatically:
10. Launch parallel review agents (code review, silent failure hunting, test analysis, etc.)
11. Auto-fix review findings
12. Update planning doc status
13. Squash-merge PR and delete branch
14. Capture learnings (if learning-loop plugin installed)

### 3. Dev Loop

Runs `/dev-task --merge` in a continuous loop until all tasks are done or blocked:

1. Pick next task with satisfied dependencies
2. Launch subagent running `/dev-task --merge` (steps 1–14 above)
3. Confirm task merged, loop to next task

Pauses only when human judgment is genuinely needed (NOT MET criteria, build failures, AC gaps). Offers to roll back pipeline permissions when complete.

### 4. Review

Multi-agent code review that:
- Auto-detects branch and PR context
- Recovers the task ID from the branch name
- Launches parallel review agents (code review, silent failure hunting, test analysis, comment review, type design)
- Verifies acceptance criteria against the diff
- Runs coverage checks
- Presents a structured report with confidence-scored findings
- Optionally captures learnings (if learning-loop plugin is installed)

### 5. Refresh Plan

Updates stale tasks in a planning doc:
- Verifies file paths still exist
- Checks if dependencies have been completed
- Regenerates context fields
- Marks already-met acceptance criteria

### 6. Metrics

Analyzes pipeline metrics across planning sessions to measure code quality and identify improvements:

```
/metrics                              # all projects, all time
/metrics my-project                   # single project
/metrics --from 2026-03-01            # date filter
/metrics --compare projectA projectB  # side-by-side
/metrics --export posthog             # push to PostHog
```

**The fix cascade** — Shipwright's dev-task pipeline has three phases after initial implementation that catch and fix issues: Simplify (Step 8), PR Review (Steps 12b-d), and CI Gate (Step 11b). Each fix applied in these phases is a signal that upstream code generation could be better. `/metrics` measures this rework and tracks it over time.

Key metrics:
- **First-time quality rate** — % of tasks that ship with zero simplify fixes, a clean review verdict, and CI passing on first try
- **Simplify fix breakdown** — DRY violations, dead code, naming, complexity, consistency
- **Review verdict distribution** — SHIP IT / NEEDS FIXES / NEEDS WORK
- **CI first-pass rate** — % of PRs where CI passes without fix attempts
- **Coverage trend** — whether test coverage is improving or declining

The command also generates actionable recommendations (e.g., "Simplify is catching 4.2 DRY violations per task — consider adding DRY enforcement to implementation prompts").

**PostHog export:** Use `--export posthog` to push metrics to PostHog for historical dashboards. Requires `POSTHOG_PROJECT_API_KEY` environment variable. See the command for setup instructions.

## Toolchain Support

Shipwright auto-detects your project's toolchain and adapts all commands accordingly:

| Ecosystem | Detection | Build | Test | Lint |
|-----------|-----------|-------|------|------|
| Node.js | `package.json` + lockfile | from scripts | from scripts | from scripts |
| Rust | `Cargo.toml` | `cargo build` | `cargo test` | `cargo clippy` |
| Go | `go.mod` | `go build ./...` | `go test ./...` | `golangci-lint run` |
| Python | `pyproject.toml` | varies | `pytest` | `ruff check` |
| Ruby | `Gemfile` | — | `rspec` | `rubocop` |
| Make | `Makefile` | `make build` | `make test` | `make lint` |

Multi-ecosystem projects (e.g., Node.js + Rust) are fully supported — validation runs for each detected ecosystem.

Monorepo detection: pnpm workspaces, npm/yarn workspaces, Lerna, Nx, Turborepo, Cargo workspaces, Go workspaces.

## Recommended Plugins

Shipwright works standalone using Claude Code's built-in agent types (`feature-dev:code-reviewer`, `general-purpose`) for all core functionality. However, it's designed to integrate with these plugins for the full experience:

| Plugin | Source | Used By | What It Enables |
|--------|--------|---------|-----------------|
| `learning-loop` | [app-vitals marketplace](https://github.com/app-vitals/marketplace) | `/review`, `/dev-task --merge` | After code review, captures patterns and recurring issues as learnings, then promotes them to CLAUDE.md so the project gets smarter over time |
| `frontend-design` | [Claude Code plugins](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design) | `/dev-task` | When a task is tagged with `Design Skill: frontend-design` in the planning doc, produces distinctive, high-quality UI instead of generic AI-generated interfaces |
| `posthog` (optional) | [PostHog plugin](https://github.com/PostHog/posthog-mcp) | `/metrics --export posthog` | Enables pushing pipeline metrics to PostHog for historical dashboards and trend visualization. Only needs `POSTHOG_PROJECT_API_KEY` env var — the MCP server is optional for querying |

### How Plugin Checks Work

Each command (`/plan-session`, `/dev-task`, `/review`) runs a plugin check at startup:

1. Checks for each recommended plugin by looking for its skills in the available skills list
2. If any are missing, displays which are installed vs. missing with one-liner install commands
3. Asks: "Continue without them? (Yes / Install first)"
4. In merge-mode (`/dev-task --merge`, `/dev-loop`), the check is silent — logs missing plugins and auto-proceeds

### What Happens Without Them

| Plugin | Without It | With It |
|--------|-----------|---------|
| `learning-loop` | Review findings are presented but not persisted. No `/learn` or `/learn-promote` runs. | Review findings that reveal patterns or missing conventions are captured as learnings and routed to CLAUDE.md or global config. |
| `frontend-design` | UI tasks are implemented using standard code generation following existing codebase patterns. | UI tasks tagged with Design Skill get a dedicated design pass that produces polished, distinctive interfaces. |

### Installation

```
/plugin install learning-loop@app-vitals/marketplace
/plugin install frontend-design
```

## Configuration

### Coverage Threshold

Default: 90%. Set during `/plan-session` and stored in the planning doc's Project Metadata section.

### Planning Doc Location

All commands look for planning docs at `planning/**/*_Task_Breakdown.md`. Create your planning folder under `planning/` before running `/plan-session`.

### Permissions

`/plan-session` Phase 7 auto-detects needed permissions and pre-populates `.claude/settings.local.json`. After `/dev-loop` completes, it offers to roll back pipeline-specific permissions.

## Architecture

```
shipwright/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/
│   ├── plan-session.md          # Planning session workflow
│   ├── dev-task.md              # Single task execution
│   ├── dev-loop.md              # Autonomous continuous loop
│   ├── metrics.md               # Pipeline metrics analysis
│   ├── refresh-plan.md          # Planning doc refresh
│   └── review.md                # Multi-agent code review
├── references/
│   ├── metrics-schema.md        # Metrics JSONL schema reference
│   ├── planning-doc-template.md # Task breakdown document template
│   └── toolchain-patterns.md    # Config file → command mapping
├── README.md
└── TESTING.md
```
