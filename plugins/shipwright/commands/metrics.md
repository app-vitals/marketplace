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
   No metrics data found. Run /dev-task --merge or /dev-loop to generate metrics.
   ```
   Stop.

3. Read each file line by line, parse each line as JSON
4. Filter by date range if `--from` and/or `--to` specified (compare against `ts` field)
5. Categorize records:
   - **Enriched**: has at least one of `simplify`, `review`, `ci` (nested object), or `coverage` fields
   - **Legacy**: core fields only (v1.2.0 format)

6. Print:
   ```
   Loaded {N} records from {M} projects ({K} enriched, {N-K} legacy)
   ```

---

## Step 3: Compute Fix Cascade Aggregates

These are the core quality metrics. Only enriched records contribute to fix cascade calculations.

### 3a. First-Time Quality Rate (north star metric)

A task has "first-time quality" if ALL of these are true:
- `simplify.total == 0` (no fixes needed during simplify)
- `review.verdict == "SHIP IT"` (review passed clean)
- `ci_fix_attempts == 0` (CI passed on first try)

```
ftq_rate = (count of first-time-quality tasks / count of enriched tasks) * 100
```

### 3b. Simplify Phase

For enriched records with `simplify` data:
- Mean `simplify.total` per task
- Mean per category: `dry`, `dead_code`, `naming`, `complexity`, `consistency`
- Top category: the category with the highest average

### 3c. Review Phase

For enriched records with `review` data:
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

### 3f. Estimation Accuracy

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
First-time quality:  {ftq_rate}% ({ftq_count}/{enriched_count} tasks)
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

This uses the PostHog **Capture API** (HTTP POST) to send events — not the PostHog MCP server (which is read-only for querying insights/flags). The only requirement is a PostHog project API key.

### 7a. Check API Key

Look for the PostHog project API key in this order:

1. Environment variable: `POSTHOG_PROJECT_API_KEY`
2. If not set, ask the user:
   ```
   PostHog export requires a project API key.
   
   To set it permanently:
     export POSTHOG_PROJECT_API_KEY="phc_your_key_here"
   
   Or provide it now to continue:
   ```

If the user cannot or does not want to provide a key, skip the export gracefully:
```
PostHog export skipped — no API key available.
The metrics report above is still valid. Set POSTHOG_PROJECT_API_KEY to enable export.
```
Stop the export (the analysis report from Step 6 still displays).

### 7b. Detect PostHog Host

Default: `https://us.i.posthog.com` (PostHog US Cloud).

If the environment variable `POSTHOG_HOST` is set, use that instead (for EU Cloud or self-hosted instances).

### 7c. Export Events

Build a batch of events from the metrics.jsonl records and send them via the PostHog Capture API.

**Event mapping:**

| Event Name | Fired For | Properties |
|------------|-----------|------------|
| `shipwright_task_completed` | Every record | `task_id`, `project`, `title`, `estimated_h`, `actual_h`, `complexity`, `retries`, `files_changed`, `model`, `ts` |
| `shipwright_simplify_pass` | Records with `simplify` data | `task_id`, `project`, `total_fixes`, `dry`, `dead_code`, `naming`, `complexity_fixes` (renamed to avoid PostHog reserved word), `consistency` |
| `shipwright_review_pass` | Records with `review` data | `task_id`, `project`, `verdict`, `findings`, `fixes_applied`, `agents` (comma-joined string) |
| `shipwright_ci_gate` | Records with `ci` data or `ci_fix_attempts > 0` | `task_id`, `project`, `fix_attempts`, `passed_first_try` (boolean), `failure_descriptions` (comma-joined string) |
| `shipwright_coverage` | Records with `coverage` data | `task_id`, `project`, `before`, `after`, `delta` |

Use `shipwright/{project}/{task_id}` as the `distinct_id` for each event. Set `timestamp` to the record's `ts` field so PostHog orders events correctly.

**Send via batch API:**

For each batch of events (up to 100 per request), POST to the capture endpoint:

```bash
curl -s -X POST "{POSTHOG_HOST}/batch/" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "{POSTHOG_PROJECT_API_KEY}",
    "batch": [
      {
        "event": "shipwright_task_completed",
        "distinct_id": "shipwright/{project}/{task_id}",
        "timestamp": "{ts}",
        "properties": { ... }
      }
    ]
  }'
```

Check the HTTP response. If the API returns a non-200 status:
```
PostHog export failed: {status code} — {error message}
Check your API key and PostHog host configuration.
```

### 7d. Report

```
PostHog export complete:
  Host:       {POSTHOG_HOST}
  Events sent:
    {task_events} shipwright_task_completed
    {simplify_events} shipwright_simplify_pass
    {review_events} shipwright_review_pass
    {ci_events} shipwright_ci_gate
    {coverage_events} shipwright_coverage
```

**Note:** This is a batch export, not a real-time hook. Run `/metrics --export posthog` after a dev-loop completes to push all accumulated data. PostHog deduplicates on `distinct_id` + `timestamp`, so re-running the export is safe.

---

## Suggested PostHog Dashboards

After exporting, these PostHog dashboards provide useful views:

1. **First-time quality rate over time** — trend line of `shipwright_task_completed` filtered by simplify.total=0, review.verdict="SHIP IT", ci_fix_attempts=0
2. **Simplify fix breakdown** — stacked bar chart of `shipwright_simplify_pass` by category
3. **Review verdict distribution** — pie chart from `shipwright_review_pass.verdict`
4. **CI pass rate over time** — trend from `shipwright_ci_gate.passed_first_try`
5. **Coverage delta trend** — line chart from `shipwright_coverage.delta`
6. **Estimation accuracy by complexity** — grouped bar from `shipwright_task_completed` grouping by complexity
