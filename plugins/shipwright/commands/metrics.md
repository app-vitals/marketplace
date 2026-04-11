---
description: Analyze pipeline metrics — fix cascade trends, quality rates, and actionable recommendations across planning sessions
arguments:
  - name: options
    description: "Optional: project name, --from YYYY-MM-DD, --to YYYY-MM-DD, --compare projectA projectB, --export posthog"
    required: false
allowed-tools: Bash(git:*), Bash(find:*), Bash(grep:*), Bash(wc:*), Bash(jq:*), Bash(cat:*), Bash(curl:*)
---

# Pipeline Metrics

Analyze shipwright pipeline metrics across planning sessions. Surfaces fix cascade trends, code quality rates, and actionable recommendations for improving execution.

---

## Step 1: Parse Arguments

Parse `$ARGUMENTS` to extract:
- **project**: A project folder name (filters to `planning/{project}/metrics.jsonl`)
- **--from YYYY-MM-DD**: Start date filter (inclusive, compared against `ts` field)
- **--to YYYY-MM-DD**: End date filter (inclusive)
- **--compare projectA projectB**: Side-by-side analysis of two projects
- **--export posthog**: Trigger PostHog event export after analysis

If no arguments provided, analyze all `planning/*/metrics.jsonl` files.

---

## Step 2: Load Data

1. Glob `planning/*/metrics.jsonl` (or `planning/{project}/metrics.jsonl` if project filter specified)
2. If no files found:
   ```
   No metrics data found. Run /dev-task to generate metrics.
   ```
   Stop.

3. Read each file line by line, parse each line as JSON
4. Filter by date range if `--from` and/or `--to` specified (compare against `ts` field)
5. Categorize records:
   - **Enriched**: has at least one of `simplify`, `ci` (nested object), or `coverage` fields. Note: the `review` field may be absent on enriched records if `/review` hasn't run yet — this does NOT make them legacy.
   - **Review-enriched**: enriched records that also have the `review` field (added by `/review` Step 10b)
   - **Legacy**: core fields only (v1.2.0 format)

6. Print:
   ```
   Loaded {N} records from {M} projects ({K} enriched, {R} with review data, {N-K} legacy)
   ```

---

## Step 3: Compute Fix Cascade Aggregates

These are the core quality metrics. Only enriched records contribute to fix cascade calculations.

### 3a. First-Time Quality Rate (north star metric)

A task has "first-time quality" if ALL of these are true:
- `simplify.total == 0` (no fixes needed during simplify)
- `review.verdict == "SHIP IT"` (review passed clean)
- `ci_fix_attempts == 0` (CI passed on first try)

FTQ can only be computed for review-enriched records (records that have the `review` field). Tasks where `/review` hasn't run yet are excluded from FTQ calculation — they lack the review verdict needed for a complete quality assessment.

```
ftq_rate = (count of first-time-quality tasks / count of review-enriched tasks) * 100
```

If no review-enriched records exist, report a partial FTQ based on simplify + CI only:
```
partial_ftq_rate = (count where simplify.total == 0 AND ci_fix_attempts == 0 / count of enriched tasks) * 100
```
Label it: "Partial FTQ (review data pending): {rate}%"

### 3b. Simplify Phase

For enriched records with `simplify` data:
- Mean `simplify.total` per task
- Mean per category: `dry`, `dead_code`, `naming`, `complexity`, `consistency`
- Top category: the category with the highest average

### 3c. Review Phase

For review-enriched records (records that have the `review` field — added by `/review` Step 10b):
- Verdict distribution: count and percentage of SHIP IT / NEEDS FIXES / NEEDS WORK
- Mean `review.findings` per task (finding density)
- Mean `review.fixes_applied` per task

### 3d. CI Gate

For all records (both enriched and legacy have `ci_fix_attempts`):
- CI first-pass rate: percentage where `ci_fix_attempts == 0`
- Mean `ci_fix_attempts` for tasks that failed CI (i.e., where `ci_fix_attempts > 0`)
- If enriched `ci.failures` data exists, collect and count the most common failure patterns

### 3e. Coverage

For enriched records with `coverage` data:
- Mean `coverage.delta`
- Mean `coverage.after`

### 3f. Research Context Loading

For enriched records with `research` data:
- Mean `research.docs_selected / research.docs_scanned` (research hit rate — what fraction of docs are relevant per task)
- Web search frequency: % of tasks where `research.web_search == true`
- Most loaded docs: rank `research.docs_loaded` entries by frequency across all tasks

### 3g. Estimation Accuracy

For all records:
- Mean estimation error: `mean((actual_h / estimated_h) - 1) * 100` as percentage
- Breakdown by complexity tier: 1-2 (simple), 3 (standard), 4-5 (complex)

---

## Step 4: Compute Trends

If 10 or more enriched records exist, split them into two halves by timestamp (first half = older, second half = newer) and compare:

| Metric | First Half | Second Half | Trend |
|--------|-----------|-------------|-------|
| First-time quality rate | {ftq_1}% | {ftq_2}% | {improving/declining/stable} |
| Simplify fixes/task | {avg_1} | {avg_2} | {improving/declining/stable} |
| Review SHIP IT rate | {rate_1}% | {rate_2}% | {improving/declining/stable} |
| CI first-pass rate | {rate_1}% | {rate_2}% | {improving/declining/stable} |

A metric is "improving" if the second half is better by 5+ percentage points (or 0.5+ for per-task counts), "declining" if worse by the same margin, "stable" otherwise.

If fewer than 10 enriched records, skip trends: "Not enough data for trend analysis (need 10+ enriched records, have {K})."

---

## Step 5: Generate Recommendations

Based on the aggregates, generate 1-3 actionable recommendations. Apply rules in priority order, stop after 3:

| Priority | Condition | Recommendation |
|----------|-----------|----------------|
| 1 | First-time quality rate < 50% | "Less than half your tasks ship without rework. Biggest contributors: {identify which of simplify/review/CI is the primary driver}. Focus improvement efforts on {primary driver}." |
| 2 | `simplify.dry` > 1.5 avg/task | "Simplify is catching {N} DRY violations per task on average. Consider adding a DRY checklist to implementation prompts or extracting shared utilities earlier in the task." |
| 3 | `simplify.dead_code` > 1.0 avg/task | "Dead code removal is frequent ({N} avg/task). Implementation is leaving unused imports and variables. Consider adding cleanup verification to the implementation step." |
| 4 | `simplify.naming` > 1.0 avg/task | "Naming issues are common ({N} avg/task). Consider adding naming conventions to your project's CLAUDE.md or the task Context field." |
| 5 | Review SHIP IT rate < 60% | "Only {N}% of tasks ship clean on review. Consider strengthening implementation prompts for the most common finding categories." |
| 6 | CI first-pass rate < 70% | "CI fails on first try for {N}% of tasks. Most common failure: {pattern from ci.failures if available}. Consider running the full validation command before pushing." |
| 7 | `simplify.complexity` > 1.0 avg/task | "Complexity reductions are frequent ({N} avg/task). Implementation is over-engineering solutions. Consider adding 'keep it simple' guidance to task briefs." |
| 8 | `coverage.delta` < 0 avg | "Coverage is declining (avg delta: {N}%). Tasks are adding code without proportional test coverage." |
| 9 | Estimation error > 30% | "Tasks are taking {N}% longer than estimated. Complexity tier {tier} is the biggest driver. Consider padding estimates for that tier." |
| 10 | Estimation error < -30% | "Tasks are completing {N}% faster than estimated. Consider tightening estimates to improve planning accuracy." |
| 11 | `research.web_search` true > 50% of tasks | "Web search is triggered on more than half of tasks. Your local docs have gaps — run `/research-docs` to generate missing documentation." |

If no conditions are met: "All metrics are within healthy ranges. Keep it up."

---

## Step 6: Present Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PIPELINE METRICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Data: {N} tasks from {M} projects ({date range or "all time"})
Enriched: {K}/{N} records have fix cascade data

FIX CASCADE
───────────
First-time quality:  {ftq_rate}% ({ftq_count}/{review_enriched_count} tasks)
  ↳ Zero simplify fixes AND SHIP IT verdict AND CI pass on first try

Simplify:
  Avg fixes/task:  {mean_total}
  By category:     DRY {dry_avg} | Dead code {dc_avg} | Naming {name_avg} | Complexity {cx_avg} | Consistency {con_avg}
  {If trends available: Trend: {first_half_avg} → {second_half_avg} ({improving/declining/stable})}

Review:
  SHIP IT:       {ship_pct}% ({ship_count})
  NEEDS FIXES:   {fixes_pct}% ({fixes_count})
  NEEDS WORK:    {work_pct}% ({work_count})
  Avg findings:  {mean_findings}/task
  Avg fixes:     {mean_fixes}/task

CI Gate:
  First-pass rate:  {ci_pct}%
  Avg fix attempts: {ci_avg} (when failed)
  {If ci.failures data: Common failures: {top 2-3 failure patterns}}

{If coverage data exists:}
Coverage:
  Avg delta:  {delta}%
  Avg after:  {after}%

ESTIMATION
──────────
Accuracy:      {error}% avg error
By complexity: 1-2: {err_12}% | 3: {err_3}% | 4-5: {err_45}%

{If trends available:}
TRENDS (first half → second half)
─────────────────────────────────
| Metric               | Before  | After   | Direction |
|----------------------|---------|---------|-----------|
| First-time quality   | {v1}%   | {v2}%   | {arrow}   |
| Simplify fixes/task  | {v1}    | {v2}    | {arrow}   |
| Review SHIP IT rate  | {v1}%   | {v2}%   | {arrow}   |
| CI first-pass rate   | {v1}%   | {v2}%   | {arrow}   |

{If --compare mode:}
COMPARISON: {projectA} vs {projectB}
────────────────────────────────────
| Metric                 | {projectA} | {projectB} |
|------------------------|------------|------------|
| Tasks                  | {count}    | {count}    |
| First-time quality     | {rate}%    | {rate}%    |
| Simplify avg fixes     | {avg}      | {avg}      |
| Review SHIP IT rate    | {rate}%    | {rate}%    |
| CI first-pass rate     | {rate}%    | {rate}%    |
| Estimation error       | {err}%     | {err}%     |

RECOMMENDATIONS
───────────────
{1-3 actionable recommendations from Step 5}
{If none: "All metrics are within healthy ranges. Keep it up."}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 7: PostHog Export (optional)

Only run if `--export posthog` was passed.

This delegates to `${CLAUDE_PLUGIN_ROOT}/scripts/posthog-export.sh` — the single source of truth for event emission. The script handles the `POSTHOG_PROJECT_API_KEY` check, builds events per the mapping table below, and POSTs via the PostHog Capture API's `/batch/` endpoint. Dev-task.md auto-export (Steps 12b-standalone and 12e.3) calls the same script, so a successful `/shipwright:verify-posthog` run guarantees both paths work.

### 7a. Preflight

1. If `POSTHOG_PROJECT_API_KEY` is not set in the environment, the script will skip silently with a stderr notice. Either `export POSTHOG_PROJECT_API_KEY="phc_..."` or configure it in `~/.claude/settings.json` under `"env"` so Claude Code can see it, then retry.
2. `POSTHOG_HOST` defaults to `https://us.i.posthog.com`. Override for EU Cloud or self-hosted: `export POSTHOG_HOST="https://eu.i.posthog.com"`.
3. Verify `${CLAUDE_PLUGIN_ROOT}/scripts/posthog-export.sh` exists and is executable (`ls -l`). If not, `chmod +x` it.

### 7b. Export Every Record

For each target JSONL file (filtered by project/--from/--to arguments from Step 1), loop over every line and call the exporter:

```bash
for f in {target_jsonl_files}; do
  total=$(wc -l < "$f")
  for n in $(seq 1 "$total"); do
    "${CLAUDE_PLUGIN_ROOT}/scripts/posthog-export.sh" "$f" "$n" || \
      echo "⚠ line $n of $f failed — see stderr"
  done
done
```

Event-firing rules and property mappings live inside the script. For reference, the mapping is:

| Event Name | Fired For | Properties |
|------------|-----------|------------|
| `shipwright_task_completed` | Every record | `task_id`, `project`, `title`, `estimated_h`, `actual_h`, `complexity`, `retries`, `files_changed`, `model`, `ts` |
| `shipwright_simplify_pass` | Records with `simplify` data | `task_id`, `project`, `total_fixes`, `dry`, `dead_code`, `naming`, `complexity_fixes` (renamed to avoid PostHog reserved word), `consistency` |
| `shipwright_review_pass` | Records with `review` data | `task_id`, `project`, `verdict`, `findings`, `fixes_applied`, `agents` (comma-joined string) |
| `shipwright_ci_gate` | Records with `ci` data or `ci_fix_attempts > 0` | `task_id`, `project`, `fix_attempts`, `passed_first_try` (boolean), `failure_descriptions` (comma-joined string) |
| `shipwright_coverage` | Records with `coverage` data | `task_id`, `project`, `before`, `after`, `delta` |

All events use `distinct_id = shipwright/{project}/{task_id}` and include `$insert_id = {event_name}/{project}/{task_id}` so PostHog dedupes on re-export — running this command multiple times is safe.

### 7c. Report

```
PostHog export complete:
  Host:       {POSTHOG_HOST}
  Records exported: {n}
  Failures:   {m}
```

If `m > 0`, print the failing lines and remind the user to re-run after fixing the underlying issue. The metrics.jsonl files are unchanged by this step, so retries are always safe.

**Note:** This is a batch export of historical data. The dev-task command already auto-exports each record when it completes. Run `/metrics --export posthog` when you want to replay accumulated data to a fresh PostHog project.

---

## Suggested PostHog Dashboards

After exporting, these PostHog dashboards provide useful views:

1. **First-time quality rate over time** — trend line of `shipwright_task_completed` filtered by simplify.total=0, review.verdict="SHIP IT", ci_fix_attempts=0
2. **Simplify fix breakdown** — stacked bar chart of `shipwright_simplify_pass` by category
3. **Review verdict distribution** — pie chart from `shipwright_review_pass.verdict`
4. **CI pass rate over time** — trend from `shipwright_ci_gate.passed_first_try`
5. **Coverage delta trend** — line chart from `shipwright_coverage.delta`
6. **Estimation accuracy by complexity** — grouped bar from `shipwright_task_completed` grouping by complexity
