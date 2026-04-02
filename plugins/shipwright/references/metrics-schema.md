# Metrics Schema Reference

Single source of truth for `planning/{folder-name}/metrics.jsonl`. Referenced by `dev-task.md` (writer), `dev-loop.md` (retrospective consumer), `plan-session.md` (historical consumer), and `metrics.md` (query command).

---

## File Format

- **Location:** `planning/{folder-name}/metrics.jsonl`
- **Format:** JSONL — one JSON object per line, newline-terminated
- **Mode:** Append-only for new tasks. Existing lines may be updated in-place by `/review` to add review data (see Write Lifecycle below).
- **Created by:** `dev-task.md` Step 12a-standalone or Step 12e.2. File is created if it doesn't exist.

---

## Write Lifecycle

Metrics are written in two phases to support the standalone `/dev-task` → `/review` workflow:

### Phase 1: dev-task (always runs)

`dev-task.md` writes a metrics line at the end of every run, in both standalone and merge-mode:

- **Standalone (Step 12a-standalone):** Writes all fields EXCEPT `review` (which hasn't run yet). Fields populated: core fields, `simplify`, `requirements`, `ci`, `coverage`, `model`.
- **Merge-mode (Step 12e.2):** Writes all fields INCLUDING `review` (inline review ran in Steps 12b-d).

### Phase 2: /review (optional enrichment)

`review.md` Step 10b updates the existing metrics line for the task with `review` data after the verdict is determined. This is a targeted in-place update (find-and-replace the JSON line), not a new append.

### Implications for consumers

- A record **without** a `review` field means `/review` hasn't run yet — NOT that the review passed clean. Exclude from review aggregates and FTQ calculation.
- A record **with** a `review` field is fully enriched and can be used for all aggregates including FTQ.
- The `/metrics` command categorizes records as "enriched" (has `simplify`/`ci`/`coverage`) and "review-enriched" (also has `review`).

---

## Schema

### Core Fields (v1.2.0+)

| Field | Type | Source Step | Default if Absent | Description |
|-------|------|------------|-------------------|-------------|
| `task` | string | Planning doc | — | Task ID (e.g., `"WS-1.1"`) |
| `title` | string | Planning doc | — | Full task title |
| `estimated_h` | number | Planning doc | — | Planned hours from task table |
| `actual_h` | number | Step 6 → 12e.2 | — | Elapsed hours from branch creation to merge |
| `complexity` | integer (1-5) | Planning doc | `0` | Complexity score (`0` = pre-B1.2 planning doc) |
| `retries` | integer | dev-loop retryMap | `0` | Retry count (`0` in standalone dev-task) |
| `ci_fix_attempts` | integer | Step 11b | `0` | CI fix subagent attempts (`0` = passed first try or no CI) |
| `pr` | integer | Step 11 | — | GitHub PR number |
| `hotfixes` | integer | dev-loop Phase 3b | `0` | Hotfix tasks spawned by this task |
| `files_changed` | integer | `git diff --stat` | — | Files changed vs main |
| `ts` | string (ISO-8601) | Step 12e.2 | — | Timestamp when metrics line was written |

### Fix Cascade Fields (v1.4.0+)

These fields measure post-implementation rework. All are optional for backward compatibility.

#### `simplify` — Step 8 fix counts

| Field | Type | Default if Absent | Description |
|-------|------|-------------------|-------------|
| `simplify.total` | integer | `0` | Total fixes applied during simplify |
| `simplify.dry` | integer | `0` | DRY violation fixes (duplicated code extraction) |
| `simplify.dead_code` | integer | `0` | Dead code removals (unused imports, variables, functions) |
| `simplify.naming` | integer | `0` | Naming improvements (unclear or inconsistent names) |
| `simplify.complexity` | integer | `0` | Complexity reductions (over-engineered solutions) |
| `simplify.consistency` | integer | `0` | Consistency fixes (patterns not matching codebase) |

#### `requirements` — Step 9 verification counts

| Field | Type | Default if Absent | Description |
|-------|------|-------------------|-------------|
| `requirements.met` | integer | `0` | Acceptance criteria fully satisfied |
| `requirements.partial` | integer | `0` | Criteria with incomplete implementation |
| `requirements.not_met` | integer | `0` | Criteria with no evidence of implementation |
| `requirements.unverifiable` | integer | `0` | Criteria that cannot be determined from code |
| `requirements.total` | integer | `0` | Total acceptance criteria evaluated |

Omit the `requirements` object entirely if Step 9 was not reached.

#### `review` — Steps 12b-12d review metrics

| Field | Type | Default if Absent | Description |
|-------|------|-------------------|-------------|
| `review.verdict` | string | `null` | One of: `"SHIP IT"`, `"NEEDS FIXES"`, `"NEEDS WORK"` |
| `review.findings` | integer | `0` | Total validated findings across all review agents |
| `review.fixes_applied` | integer | `0` | Findings auto-fixed in Step 12d |
| `review.agents` | string[] | `[]` | Names of review agents that ran |

Omit the `review` object entirely in standalone (non-merge) mode where Steps 12b-d don't run.

#### `ci` — Step 11b CI gate details

| Field | Type | Default if Absent | Description |
|-------|------|-------------------|-------------|
| `ci.fix_attempts` | integer | `0` | Mirrors top-level `ci_fix_attempts` |
| `ci.failures` | string[] | `[]` | One-line description per CI failure (under 100 chars each) |

Falls back to top-level `ci_fix_attempts` if the `ci` object is absent.

#### `model` — execution model

| Field | Type | Default if Absent | Description |
|-------|------|-------------------|-------------|
| `model` | string | `null` | Model tier that executed this task (e.g., `"haiku"`, `"sonnet"`, `"opus"`) |

Read from the planning doc's Model column. `null` if not specified (pre-model-routing planning docs).

#### `coverage` — Step 10 coverage delta

| Field | Type | Default if Absent | Description |
|-------|------|-------------------|-------------|
| `coverage.before` | number | `null` | Baseline coverage % (from main branch, if measurable) |
| `coverage.after` | number | `null` | Coverage % after this task's changes |
| `coverage.delta` | number | `null` | `after - before` (positive = coverage improved) |

Best-effort measurement. Use `null` for any field the toolchain can't provide.

---

## Example Records

### v1.2.0 record (core fields only)

```json
{"task":"WS-1.1","title":"Add workspace model","estimated_h":2,"actual_h":1.5,"complexity":3,"retries":0,"ci_fix_attempts":0,"pr":42,"hotfixes":0,"files_changed":4,"ts":"2026-03-31T14:30:00Z"}
```

### v1.4.0 record (with fix cascade fields)

```json
{"task":"WS-1.2","title":"Add workspace API routes","estimated_h":3,"actual_h":2.8,"complexity":3,"retries":0,"ci_fix_attempts":1,"pr":43,"hotfixes":0,"files_changed":6,"ts":"2026-03-31T16:45:00Z","simplify":{"total":2,"dry":1,"dead_code":0,"naming":1,"complexity":0,"consistency":0},"requirements":{"met":5,"partial":0,"not_met":0,"unverifiable":0,"total":5},"review":{"verdict":"NEEDS FIXES","findings":3,"fixes_applied":2,"agents":["code-reviewer","silent-failure-hunter","test-analyzer"]},"ci":{"fix_attempts":1,"failures":["jest: 1 test suite failed — missing mock for workspace service"]},"model":"sonnet","coverage":{"before":87.2,"after":91.5,"delta":4.3}}
```

---

## Backward Compatibility Rules

1. **New fields are always optional.** Consumers must never error on records missing fix cascade fields.
2. **Absent objects = zero/null defaults.** If `simplify` is absent, treat as zero fixes. If `review` is absent, the task hasn't been reviewed yet — exclude from review aggregates and FTQ calculation (do not treat as "passed").
3. **Top-level `ci_fix_attempts` is kept.** The `ci.fix_attempts` field mirrors it for consistency. Consumers should read `ci.fix_attempts` first, fall back to `ci_fix_attempts`.
4. **Old records are included in basic aggregates** (hours, retries, files changed) but excluded from fix cascade aggregates that require the new fields.

---

## Writers

| Writer | File | What It Writes | When |
|--------|------|----------------|------|
| **Dev-task (standalone)** | `dev-task.md` Step 12a-standalone | All fields except `review` | After PR creation |
| **Dev-task (merge-mode)** | `dev-task.md` Step 12e.2 | All fields including `review` | After inline review + merge |
| **Review** | `review.md` Step 10b | `review.*` fields (updates existing line) | After review verdict |

## Consumers

| Consumer | File | What It Reads | When |
|----------|------|---------------|------|
| **Dev-loop retrospective** | `dev-loop.md` | All fields | LOOP END — aggregates, trends, learnings |
| **Plan-session estimation** | `plan-session.md` | `estimated_h`, `actual_h`, fix cascade summary | Phase 4 — calibrate estimates for new tasks |
| **Metrics command** | `metrics.md` | All fields | On demand — full analysis and recommendations |
| **PostHog export** | `metrics.md` (--export) | All fields | On demand — batch event export |

---

## Derived Metrics

These are computed by consumers, not stored in the JSONL:

| Metric | Formula | Interpretation |
|--------|---------|----------------|
| **First-time quality rate** | % tasks where `simplify.total == 0` AND `review.verdict == "SHIP IT"` AND `ci_fix_attempts == 0` | Higher = less rework after implementation |
| **Simplify fix rate** | Mean `simplify.total` per task | Lower = better initial code quality |
| **Review SHIP IT rate** | % tasks with `review.verdict == "SHIP IT"` | Higher = cleaner code from implementation |
| **CI first-pass rate** | % tasks with `ci_fix_attempts == 0` | Higher = fewer CI surprises |
| **Estimation accuracy** | `mean((actual_h / estimated_h) - 1) * 100` | Closer to 0% = better estimates |
| **Coverage trend** | Mean `coverage.delta` over time | Positive = coverage improving |
