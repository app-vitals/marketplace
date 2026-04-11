---
description: Verify shipwright metrics reach PostHog — publishes a synthetic event via the real export script and confirms arrival via the PostHog MCP
allowed-tools: Bash(mktemp:*), Bash(date:*), Bash(mkdir:*), Bash(cat:*), Bash(jq:*), Bash(sleep:*), Bash(test:*), Bash(ls:*), Bash(rm:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/posthog-export.sh:*), mcp__plugin_posthog_posthog__query-run
---

# Verify PostHog Metrics Pipeline

**Purpose:** Prove, before you push any shipwright change, that metrics actually reach PostHog. Runs the real `scripts/posthog-export.sh` against a synthetic record, then reads the events back via the PostHog MCP. Also runs a 30-day historical diagnostic so you can tell whether past real `dev-task` runs ever emitted anything.

Run this whenever you edit:
- `commands/dev-task.md` (Steps 12a/b/e)
- `commands/metrics.md` (Step 7)
- `commands/review.md` (Step 10b)
- `references/metrics-schema.md`
- `scripts/posthog-export.sh`

The acceptance bar is **5/5 events arriving** at PostHog within 15 seconds. Anything less blocks the PR.

---

## Step 1: Preflight

Bail out early with a clear message if any prerequisite is missing.

1. **API key check.** If `POSTHOG_PROJECT_API_KEY` is not set in the current shell environment, abort with:
   ```
   ✗ POSTHOG_PROJECT_API_KEY is not set in Claude Code's shell environment.

   The most common cause of "I never see metrics" is that the key is in ~/.zshrc
   (which only loads for interactive shells) but not in an environment Claude Code
   can read. Fix one of these:

     Option A — claude-code-specific env (recommended):
       Edit ~/.claude/settings.json and add under "env":
         { "env": { "POSTHOG_PROJECT_API_KEY": "phc_..." } }

     Option B — login-shell env file:
       Add to ~/.zshenv (not ~/.zshrc):
         export POSTHOG_PROJECT_API_KEY="phc_..."
       Then restart Claude Code.

   Re-run /shipwright:verify-posthog after fixing.
   ```
   Stop.

2. **Script check.** Confirm `${CLAUDE_PLUGIN_ROOT}/scripts/posthog-export.sh` exists and is executable. If missing, abort with an install hint: `run chmod +x ${CLAUDE_PLUGIN_ROOT}/scripts/posthog-export.sh`.

3. **MCP check.** Confirm the `mcp__plugin_posthog_posthog__query-run` tool is available. If the PostHog MCP plugin is not installed, abort with: `Install the posthog MCP plugin first — /plugin install plugin-posthog`.

---

## Step 2: Build Synthetic Record

Generate a unique task ID and write a fully-enriched metrics.jsonl record that exercises all five event types.

```bash
TASK_ID="verify-$(date +%s)-$$"
PROJECT="shipwright-selftest"
WORK_DIR="$(mktemp -d)"
mkdir -p "$WORK_DIR/planning/$PROJECT"
METRICS_FILE="$WORK_DIR/planning/$PROJECT/metrics.jsonl"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > "$METRICS_FILE" <<EOF
{"task":"$TASK_ID","title":"verify-posthog self-test","estimated_h":1,"actual_h":0.8,"complexity":2,"retries":0,"ci_fix_attempts":1,"pr":0,"hotfixes":0,"files_changed":3,"ts":"$TS","simplify":{"total":1,"dry":0,"dead_code":1,"naming":0,"complexity":0,"consistency":0},"requirements":{"met":3,"partial":0,"not_met":0,"unverifiable":0,"total":3},"review":{"verdict":"SHIP IT","findings":0,"fixes_applied":0,"agents":["verify-agent"]},"ci":{"fix_attempts":1,"failures":["synthetic: test failure for verify-posthog"]},"model":"sonnet","coverage":{"before":80.0,"after":82.5,"delta":2.5}}
EOF
```

Remember `TASK_ID`, `PROJECT`, and `WORK_DIR` — you'll need them for the verify query and cleanup.

---

## Step 3: Publish via Production Script

Invoke the **same** script that dev-task.md uses. This is what gives the test its meaning — a green verify proves the production path works.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/posthog-export.sh "$METRICS_FILE" 1
```

If exit code is non-zero, print the stderr and abort. Do not proceed to the query step — the POST failed, so there's nothing to verify.

---

## Step 4: Wait for Ingestion

```bash
sleep 8
```

PostHog typically ingests within 1–3 seconds, but give it headroom so a transient lag doesn't false-fail the gate.

---

## Step 5: Verify Arrival via PostHog MCP

Call `mcp__plugin_posthog_posthog__query-run` with this HogQL query (substitute `{TASK_ID}`):

```sql
SELECT event, properties.$insert_id AS insert_id, timestamp
FROM events
WHERE distinct_id = 'shipwright/shipwright-selftest/{TASK_ID}'
  AND timestamp > now() - INTERVAL 15 MINUTE
ORDER BY timestamp DESC
```

**Expected result:** 5 rows, one per event:
- `shipwright_task_completed`
- `shipwright_simplify_pass`
- `shipwright_review_pass`
- `shipwright_ci_gate`
- `shipwright_coverage`

Report each one individually:

```
PostHog Verification — task_id: {TASK_ID}
  ✓ shipwright_task_completed
  ✓ shipwright_simplify_pass
  ✓ shipwright_review_pass
  ✓ shipwright_ci_gate
  ✓ shipwright_coverage

✓ VERIFIED — 5/5 events reached PostHog
```

If any event is missing, mark it `✗ MISSING` and print:

```
✗ FAILED — {n}/5 events reached PostHog

Possible causes:
  - posthog-export.sh jq pipeline dropped the event (check event firing condition)
  - PostHog project mismatch (POSTHOG_PROJECT_API_KEY points to a different project than the MCP token)
  - Ingestion lag >8s (rare; retry once with longer sleep before flagging as broken)
```

Stop on failure — do not proceed to the historical diagnostic.

---

## Step 6: Historical Diagnostic (always runs on success)

After a successful verify, run a second MCP query to see whether **real** (non-synthetic) shipwright events have ever arrived from past dev-task runs:

```sql
SELECT event, count() AS cnt, max(timestamp) AS last_seen
FROM events
WHERE event LIKE 'shipwright_%'
  AND distinct_id NOT LIKE 'shipwright/shipwright-selftest/%'
  AND timestamp > now() - INTERVAL 30 DAY
GROUP BY event
ORDER BY last_seen DESC
```

Print the result as a table:

```
Historical shipwright events (last 30 days, excluding self-tests):
  event                          count   last_seen
  shipwright_task_completed      14      2026-04-09 22:11:03
  shipwright_simplify_pass       11      2026-04-09 22:11:03
  ...
```

If the result is **empty** (0 rows), print this diagnostic:

```
⚠ No real dev-task events in the last 30 days.

The synthetic test above proved the export pipeline works end-to-end, so
past dev-task runs must have skipped the PostHog export step. Likely causes:

  1. POSTHOG_PROJECT_API_KEY is set in your interactive shell (~/.zshrc) but
     not in Claude Code's shell environment. Fix by moving it to
     ~/.claude/settings.json under "env", or to ~/.zshenv.

  2. The previous version of dev-task.md described the export in prose and
     Claude's interpretation silently failed. v1.8.0+ calls a deterministic
     script — re-run dev-task after updating and events should flow.
```

---

## Step 7: Cleanup & Report

1. Print the `distinct_id` of the synthetic events so the user can remove them from PostHog manually if desired:
   ```
   Synthetic distinct_id (delete via PostHog UI if desired):
     shipwright/shipwright-selftest/{TASK_ID}
   ```
2. Remove the temp work dir: `rm -rf "$WORK_DIR"`.
3. Final status line:
   - Pass: `✓ SAFE TO SHIP — paste the output above into your PR description.`
   - Fail: `✗ DO NOT SHIP — fix the pipeline before merging.`
