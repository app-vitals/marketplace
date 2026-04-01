# Shipwright Testing

Manual test scenarios for each command across different project types.

## Prerequisites

- Claude Code installed
- Shipwright plugin installed (`/plugin install shipwright@app-vitals/marketplace`)
- GitHub CLI (`gh`) authenticated
- A test repository (or use the scenarios below)

---

## Test Matrix

| # | Command | Project Type | Scenario | Key Verification |
|---|---------|-------------|----------|-----------------|
| 1 | `/plan-session` | Node.js (pnpm) | New feature planning | Toolchain detected, layers auto-detected, template correct |
| 17 | `/plan-session` | Any | Complexity scoring | Complexity column (1-5) in task table, scores correlate with task characteristics |
| 18 | `/dev-loop` | Any | Cross-session handoff | Handoff section written after each batch, restored on restart |
| 19 | `/dev-task --merge` | Any | Persistent metrics | metrics.jsonl appended after each merge, plan-session reads historical data |
| 2 | `/plan-session` | Python (poetry) | API feature planning | Python toolchain, pytest commands, coverage threshold |
| 3 | `/plan-session` | Rust (cargo) | CLI feature planning | Cargo commands, clippy in permissions |
| 4 | `/plan-session` | Go | Service planning | Go commands, golangci-lint detection |
| 5 | `/plan-session` | Multi (Node+Rust) | Full-stack planning | Both ecosystems detected, dual validation |
| 6 | `/dev-task` | Node.js | Single task execution | Branch created, tests run, PR created |
| 7 | `/dev-task --merge` | Node.js | Merge-mode task | Full pipeline including review and merge |
| 8 | `/dev-loop` | Node.js | Multi-task loop | All tasks processed, planning doc updated |
| 9 | `/review` | Node.js | Standalone review | Agents launched, findings reported, AC verified |
| 10 | `/refresh-plan` | Any | Stale doc refresh | File paths updated, context regenerated |
| 11 | `/plan-session` | Any | Planning retrospective | Phase 9 metrics, quality ratings, learnings staged |
| 12 | `/dev-loop` | Any | Loop retrospective | Actual vs estimated, accuracy ratio, learnings staged |
| 13 | `/dev-loop` | Any | Bug-fix task insertion | HF-N generated, picked up in next iteration |
| 14 | `/dev-task` + `/dev-loop` | Any | PR/branch cleanup on failure | Orphan PRs closed, branches deleted, retry logic |
| 15 | `/dev-loop` | Any | Parallel task execution | Batch selection, worktree isolation, post-sync |
| 16 | `/plan-session` | Any | Task consolidation | Merge criteria applied, consolidation report |

---

## Scenario 1: Plan Session — Node.js (pnpm)

### Setup
1. Create a test repo with `package.json`, `pnpm-lock.yaml`, and basic `src/` structure
2. Add `src/components/`, `src/api/`, `src/lib/` directories
3. Create `planning/test-feature/` with a requirements doc

### Run
```
/plan-session test-feature
```

### Verify
- [ ] Phase 0 detects pnpm as package manager
- [ ] Phase 0 reads package.json scripts correctly
- [ ] Phase 3 auto-detects layers: Frontend, API, Shared
- [ ] Phase 4 generates planning doc with correct template
- [ ] Phase 4 uses detected layers (not Chrome extension layers)
- [ ] Phase 5 quality checks all pass
- [ ] Phase 7 generates correct pnpm permission patterns
- [ ] No Chrome extension references anywhere in output
- [ ] No hardcoded `pnpm validate` — uses detected commands

---

## Scenario 2: Plan Session — Python (poetry)

### Setup
1. Create a test repo with `pyproject.toml` (poetry build system), `poetry.lock`
2. Add `src/api/`, `src/db/`, `src/lib/` directories
3. Create `planning/test-feature/` with a requirements doc

### Run
```
/plan-session test-feature
```

### Verify
- [ ] Phase 0 detects Poetry as package manager
- [ ] Phase 0 identifies pytest, ruff check commands
- [ ] Phase 3 auto-detects layers: API, Database, Shared
- [ ] Phase 7 generates poetry/pytest permission patterns
- [ ] Planning doc template uses correct Python toolchain

---

## Scenario 3: Plan Session — Rust (cargo)

### Setup
1. Create a test repo with `Cargo.toml`, `src/main.rs`
2. Add `src/cli/`, `src/lib/` directories
3. Create `planning/test-feature/` with a requirements doc

### Run
```
/plan-session test-feature
```

### Verify
- [ ] Phase 0 detects Cargo
- [ ] Phase 0 identifies `cargo build`, `cargo test`, `cargo clippy`
- [ ] Phase 3 auto-detects layers: CLI, Shared
- [ ] Phase 7 includes `Bash(cargo:*)` permission
- [ ] Planning doc references cargo commands (not pnpm)

---

## Scenario 4: Dev Task — Single Execution

### Setup
1. Complete Scenario 1 (have a planning doc with tasks)
2. Identify the first available task ID

### Run
```
/dev-task {TASK-ID}
```

### Verify
- [ ] Step 0 detects toolchain
- [ ] Step 1 finds the planning doc
- [ ] Step 2 extracts all task fields correctly
- [ ] Step 3 checks dependencies
- [ ] Step 4 marks task [🔨] and commits
- [ ] Step 6 creates feature branch from main
- [ ] Step 7 implements using inline workflow (not /feature-dev)
- [ ] Step 8 runs simplification pass (not /simplify)
- [ ] Step 9 verifies acceptance criteria
- [ ] Step 10 runs detected validation commands (not hardcoded)
- [ ] Step 11 creates PR with correct body format
- [ ] Step 12 shows handoff block (standalone mode)

---

## Scenario 5: Dev Task — Merge Mode

### Setup
Same as Scenario 4

### Run
```
/dev-task {TASK-ID} --merge
```

### Verify
- [ ] All pause points are skipped
- [ ] Step 12 runs inline review (not /review command)
- [ ] Review uses generic Agent types (not pr-review-toolkit)
- [ ] PR is squash-merged automatically
- [ ] Planning doc status updated to [x] PR #{N}
- [ ] Learning capture only runs if learning-loop plugin is installed

---

## Scenario 6: Dev Loop

### Setup
1. Have a planning doc with 3+ tasks, first 2 with no dependencies
2. Third task depends on first two

### Run
```
/dev-loop test-feature
```

### Verify
- [ ] Phase 0 locates planning doc
- [ ] Phase 1 picks first available task
- [ ] Phase 2 launches subagent with /dev-task --merge
- [ ] Phase 3 confirms completion, loops to next task
- [ ] Dependency chain respected (task 3 runs after 1 and 2)
- [ ] Loop ends with COMPLETE or BLOCKED summary
- [ ] Permission cleanup offered if pipeline-permissions-added.json exists

---

## Scenario 7: Review — Standalone

### Setup
1. Complete a /dev-task (without --merge) to have a branch with PR
2. Switch to a new session on the feature branch

### Run
```
/review
```

### Verify
- [ ] Step 0 detects toolchain
- [ ] Step 1 auto-detects branch and PR
- [ ] Step 2 recovers task ID from branch name
- [ ] Step 3 gathers context in parallel
- [ ] Step 4 launches appropriate agents based on diff analysis
- [ ] Step 4 uses feature-dev:code-reviewer and general-purpose agents (not pr-review-toolkit)
- [ ] Step 5 validates findings against source files
- [ ] Step 5b runs coverage with detected commands
- [ ] Step 6 evaluates acceptance criteria
- [ ] Step 7 presents structured report
- [ ] Step 8 fixes use detected validation commands
- [ ] Step 11 learning capture is conditional on plugin availability

---

## Scenario 8: Refresh Plan

### Setup
1. Have a planning doc with some [x] and some [ ] tasks
2. Modify some source files referenced by [ ] tasks (move or rename)

### Run
```
/refresh-plan test-feature
```

### Verify
- [ ] Step 1 loads and parses the planning doc
- [ ] Step 2 identifies [ ] tasks correctly
- [ ] Step 3 detects stale file paths
- [ ] Step 3 checks dependency status updates
- [ ] Step 4 proposes correct changes
- [ ] Step 5 shows before/after diff
- [ ] Step 6 commits after user approval

---

## Anti-Pattern Checks

Run these across ALL scenarios to verify genericization:

- [ ] No references to "Chrome extension", "WXT", "MV3", "content script", "service worker lifecycle"
- [ ] No hardcoded `pnpm validate`, `pnpm -r check` — uses detected commands
- [ ] No hardcoded `cargo clippy`, `cargo test` — uses detected commands
- [ ] No references to hardcoded packages like "extension", "desktop", "packages/shared"
- [ ] No `/feature-dev` skill invocation — replaced with inline implementation
- [ ] No `/simplify` skill invocation — replaced with inline simplification
- [ ] No `pr-review-toolkit:*` agent types — replaced with generic agents
- [ ] No required `Skill(learn)` or `Skill(learning-loop:learn-promote)` — optional only
- [ ] Coverage threshold defaults to 90% (configurable)
- [ ] No `frontend-design` as required — optional Design Skill tag
- [ ] No hardcoded layer names "Background/UI/Content Script/Shared" — uses auto-detected layers

---

## Scenario 11: Planning Retrospective (plan-session Phase 9)

### Setup
1. Complete a full plan-session (any of Scenarios 1-5)

### Verify
- [ ] Phase 9a evaluates all 6 dimensions with ratings (1-5)
- [ ] Phase 9b prints metrics block with correct task counts, hours, and quality scores
- [ ] Phase 9c stages learnings via `/learn` if `learning-loop` plugin is available
- [ ] Phase 9c prints learnings as text if `learning-loop` is not available
- [ ] Learnings use `Shipwright/planning:` prefix
- [ ] Learnings are specific and actionable (not "planning went well")
- [ ] Only dimensions rated 3 or below generate learnings

### Without learning-loop
- [ ] Findings are appended as `## Planning Retrospective` section in the planning doc
- [ ] No errors or missing plugin warnings

---

## Scenario 12: Dev Loop Retrospective

### Setup
1. Complete a full dev-loop (Scenario 8) with 3+ tasks

### Verify
- [ ] Retrospective section appears after loop summary, before permission cleanup
- [ ] Metrics table shows actual vs estimated hours for each completed task
- [ ] Delta percentages are calculated correctly
- [ ] Accuracy ratio (actual/estimated) is computed
- [ ] Retry count and orphan PR count are tracked
- [ ] Bug-fix task count (HF-*) is included
- [ ] Learnings staged with `Shipwright/dev-loop:` prefix if plugin available
- [ ] Retrospective summary block prints with all metric fields populated

### Metrics accuracy
- [ ] Actual hours derived from git commit timestamps (first commit on branch → merge)
- [ ] Accuracy ratio = actual / estimated
- [ ] Orphan PR count matches actual cleanup actions taken
- [ ] Permission settings diff correctly counts runtime additions

---

## Scenario 13: Dynamic Bug-Fix Task Insertion

### Setup
1. Create a planning doc with 3+ tasks
2. In the second task's source files, introduce a deliberate bug that a later task's tests will catch (e.g., wrong property name in a response object)
3. Run `/dev-loop`

### Verify
- [ ] Phase 3b scans subagent output for bug-indicating phrases
- [ ] `HF-1` task is generated with correct fields (ID, Hours, Layer, Dependencies, Branch)
- [ ] HF task appended to planning doc (feature section + Appendix)
- [ ] Warning printed: "⚠ BUG DETECTED after {task-id} — created HF-1: {description}"
- [ ] HF task picked up in next loop iteration (its dependency is already `[x]`)
- [ ] HF task fixes the bug and merges
- [ ] Final summary includes HF tasks in the shipped list
- [ ] HF task has `minimal` architecture approach
- [ ] HF task branch follows `fix/hf-{n}-{description}` convention

### Edge case checks
- [ ] False positive: subagent mentions "bug" in a comment but no actual bug → no HF task created
- [ ] Multiple bugs in one task → creates HF-1, HF-2, etc.
- [ ] HF task numbering continues across the entire loop run (not per-task)

---

## Scenario 14: Failed PR/Branch Cleanup

### Setup (dev-task)
1. Create a planning doc with a task that will fail during PR creation
2. Run `/dev-task {task-id} --merge`

### Verify (dev-task)
- [ ] PR creation or merge fails
- [ ] Orphaned PR detected via `gh pr list --head {branch}`
- [ ] Open PRs closed with cleanup comment
- [ ] Remote branch deleted
- [ ] Local branch deleted, returned to main
- [ ] Task status reset from `[🔨]` to `[ ]` in planning doc
- [ ] Cleanup summary printed with PR list and branch name
- [ ] Commit created: `chore: reset {task-id} after PR failure`

### Setup (dev-loop)
1. Create a planning doc where one task is designed to fail (e.g., references nonexistent file)
2. Run `/dev-loop`

### Verify (dev-loop)
- [ ] Failed subagent triggers Phase 3a-retry
- [ ] Cleanup runs (close orphan PRs, delete branch)
- [ ] First failure: task re-queued (status reset to `[ ]`)
- [ ] Second failure: task marked `[⏸]` (blocked)
- [ ] retryMap tracks per-task retry count correctly
- [ ] Warning printed with failure/retry status
- [ ] Other tasks continue processing after the failed task

---

## Scenario 15: Parallel Task Execution

### Setup
1. Create a planning doc with 6 tasks:
   - T-1 (no deps), T-2 (no deps), T-3 (depends on T-1), T-4 (depends on T-2), T-5 (depends on T-3 + T-4), T-6 (no deps, same Layer/file as T-1)
2. Run `/dev-loop`

### Verify
- [ ] Phase 1 identifies ALL ready tasks, not just the first
- [ ] T-1 and T-2 launch as parallel subagents (different worktrees)
- [ ] T-6 does NOT parallelize with T-1 (same primary file — file overlap check works)
- [ ] Each parallel subagent uses `isolation: "worktree"`
- [ ] Post-batch sync pulls main between parallel batches
- [ ] T-3 starts only after T-1 completes
- [ ] T-4 starts only after T-2 completes
- [ ] T-3 and T-4 parallelize (independent, different files)
- [ ] T-5 waits for both T-3 and T-4
- [ ] All PRs merge cleanly (no conflicts from parallel work)
- [ ] Batch plan printed with task IDs, branches, layers
- [ ] Wall-clock time is measurably less than sequential (compare git timestamps)

### Anti-pattern checks
- [ ] Never launches > 3 parallel subagents (resource guard)
- [ ] Falls back to sequential if worktree creation fails
- [ ] Single-task fallback works correctly when only 1 task is ready

---

## Scenario 16: Task Consolidation (plan-session Phase 4b)

### Setup
1. Create a planning folder with requirements that will naturally produce:
   - Two schema additions to the same file (e.g., two Prisma models)
   - Two CLI commands in the same file
   - Two independent API endpoints in different files (should NOT merge)
2. Run `/plan-session`

### Verify
- [ ] Phase 4b runs after task generation, before Phase 5 quality checks
- [ ] Schema tasks meeting ALL merge criteria are consolidated into 1 task
- [ ] CLI tasks meeting ALL merge criteria are consolidated into 1 task
- [ ] API tasks remain separate (different primary files)
- [ ] Merged task uses the earlier task's ID and branch
- [ ] Merged task hours = sum minus ~15% context-switch reduction
- [ ] Merged task notes "Consolidated from {original-ids}"
- [ ] Acceptance criteria are unioned and deduplicated
- [ ] Implementation Decisions are merged (more detailed answer for each field)
- [ ] Retired task ID removed from Appendix and Feature Summary
- [ ] No task references a retired ID as a dependency
- [ ] Consolidation report printed (pairs merged, before/after counts, hours saved)

### Guard rails
- [ ] Tasks > 4h combined are NOT merged
- [ ] Tasks with conflicting dependencies are NOT merged
- [ ] Tasks in different features are NOT merged
- [ ] Non-additive changes (create vs refactor) are NOT merged

---

## Scenario 17: Complexity Scoring (plan-session)

### Setup
1. Create a test repo with a Node.js project
2. Create `planning/test-feature/` with a requirements doc covering:
   - A simple config field addition (expect Complexity 1-2)
   - A 5+ file cross-layer feature (expect Complexity 4-5)

### Run
```
/plan-session test-feature
```

### Verify
- [ ] Every task in output has a `Complexity` column with a value 1-5
- [ ] Config-only task scores 1-2
- [ ] Cross-layer task scores 4-5
- [ ] Phase 5 quality check reports Complexity as a required field
- [ ] Phase 5 fails if any task is missing a Complexity score

### With historical metrics
- [ ] Place a `planning/test-feature/metrics.jsonl` file with 5 sample entries
- [ ] Re-run `/plan-session test-feature` — verify historical estimation accuracy is printed before hour assignment
- [ ] Delete `metrics.jsonl` — verify no errors on next run (graceful degradation)

---

## Scenario 18: Cross-Session Handoff (dev-loop)

### Setup
1. Have a planning doc with 4+ tasks, first 2 with no dependencies

### Interrupt test
1. Start `/dev-loop`
2. After the first task completes (watch for `✓ {task-id}` line), manually interrupt the session (`/clear` or kill)
3. Open the planning doc — verify `## Handoff` section was written with:
   - [ ] `Last completed: {task-id}`
   - [ ] `Timestamp:` (valid ISO timestamp)
   - [ ] `Batch:` field
   - [ ] `Recent changes:` list (at least 1 entry)

### Resume test
1. Restart `/dev-loop` on the same planning doc
2. Verify:
   - [ ] Loop prints `↩ Resuming from handoff (last: {task-id}, batch N)`
   - [ ] Loop does NOT re-run already-completed tasks
   - [ ] `recentChanges[]` is populated from the Handoff section (visible in Phase 2a context briefings)

### Completion cleanup
1. Let the loop run to completion
2. Verify:
   - [ ] `## Handoff` section is removed from the planning doc
   - [ ] Final commit message: `chore: remove handoff state — loop complete`

### Orphan recovery (dev-task)
1. Create a planning doc with a task marked `[🔨]` and a matching branch on the remote
2. Run `/dev-task {task-id}`
3. Verify:
   - [ ] Orphan check runs before marking in-progress
   - [ ] If a PR exists, it is closed with cleanup comment
   - [ ] Branch is deleted before fresh start

---

## Scenario 19: Persistent Metrics (dev-task + dev-loop + plan-session)

### Artifact check — metrics.jsonl written
1. Complete any `/dev-task {task-id} --merge` on a task that has a Complexity score
2. Verify:
   - [ ] `planning/{folder}/metrics.jsonl` exists after merge
   - [ ] Contains exactly one new JSON line with fields: `task`, `title`, `estimated_h`, `actual_h`, `complexity`, `retries`, `pr`, `hotfixes`, `files_changed`, `ts`
   - [ ] `complexity` matches the task's Complexity field in the planning doc
   - [ ] `pr` matches the merged PR number

### Artifact check — dev-loop reads metrics
1. Complete a `/dev-loop` run with 3+ tasks (metrics.jsonl will be populated)
2. In the Loop Retrospective, verify:
   - [ ] "Historical data" block appears with mean estimation error
   - [ ] Model distribution shows counts per complexity tier
   - [ ] Per-task table uses actuals from metrics.jsonl (not just git timestamps)

### Artifact check — plan-session reads historical data
1. After a dev-loop run that produced `metrics.jsonl`, run `/plan-session` on the same folder
2. Verify:
   - [ ] Historical estimation accuracy is reported before hour assignment
   - [ ] Message format: "Historical data ({N} tasks): avg estimation error {+/-N}%..."

### Graceful degradation
1. Run `/plan-session` on a folder with NO `metrics.jsonl` — no errors, no warnings
2. Run `/dev-loop` on a folder with NO `metrics.jsonl` — retrospective still runs using git timestamps

---

## Versioning Checklist (for every PR to this repo)

- [ ] Does this PR change any file under `commands/`, `skills/`, `agents/`, or `hooks/`?
  - **Yes** → bump `plugins/shipwright/.claude-plugin/plugin.json` version (patch for fixes, minor for features)
  - **No** (docs-only, like ADOPTION-ROADMAP.md) → no version bump needed
- [ ] Bump `.claude-plugin/marketplace.json` version whenever any plugin version changes
- [ ] Version bump is in the **same PR** as command changes — never separate
- [ ] After merging: verify `/plugin marketplace update` + `/plugin update shipwright` picks up the new version
