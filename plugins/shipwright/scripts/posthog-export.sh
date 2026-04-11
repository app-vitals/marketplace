#!/usr/bin/env bash
# posthog-export.sh — deterministic PostHog Capture API exporter for shipwright metrics.
#
# Single source of truth for event emission. Called by dev-task.md Steps 12b-standalone
# and 12e.3 (auto-export after each task), metrics.md Step 7 (batch export), and
# verify-posthog.md (self-test).
#
# Event mapping is authoritative — see plugins/shipwright/references/metrics-schema.md
# and plugins/shipwright/commands/metrics.md Step 7c for the spec.
#
# Usage:
#   posthog-export.sh <metrics.jsonl path> [line number, default: last]
#
# Env:
#   POSTHOG_PROJECT_API_KEY  required (silent exit 0 if unset — matches spec contract)
#   POSTHOG_HOST             optional, default: https://us.i.posthog.com
#
# Exit codes:
#   0  success, or skipped because POSTHOG_PROJECT_API_KEY is unset
#   1  failure (bad args, missing file, malformed JSON, non-2xx HTTP response)

set -euo pipefail

err() { printf '%s\n' "$*" >&2; }

FILE="${1:-}"
LINE_NUM="${2:-}"

if [[ -z "$FILE" ]]; then
  err "usage: posthog-export.sh <metrics.jsonl> [line number]"
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  err "posthog-export: file not found: $FILE"
  exit 1
fi

if [[ -z "${POSTHOG_PROJECT_API_KEY:-}" ]]; then
  err "posthog-export: skipped (POSTHOG_PROJECT_API_KEY not set)"
  exit 0
fi

command -v jq >/dev/null 2>&1 || { err "posthog-export: jq not installed"; exit 1; }
command -v curl >/dev/null 2>&1 || { err "posthog-export: curl not installed"; exit 1; }

POSTHOG_HOST="${POSTHOG_HOST:-https://us.i.posthog.com}"

if [[ -z "$LINE_NUM" ]]; then
  LINE_NUM=$(awk 'END{print NR}' "$FILE")
fi

if ! [[ "$LINE_NUM" =~ ^[0-9]+$ ]] || [[ "$LINE_NUM" -lt 1 ]]; then
  err "posthog-export: invalid line number: $LINE_NUM"
  exit 1
fi

RECORD=$(sed -n "${LINE_NUM}p" "$FILE")
if [[ -z "$RECORD" ]]; then
  err "posthog-export: line $LINE_NUM is empty or past end of file"
  exit 1
fi

if ! printf '%s' "$RECORD" | jq empty >/dev/null 2>&1; then
  err "posthog-export: line $LINE_NUM is not valid JSON"
  exit 1
fi

# Derive project from the parent folder: planning/<project>/metrics.jsonl
PROJECT=$(basename "$(dirname "$FILE")")

# Build the batch payload. All event-firing rules and property mappings live inside
# this single jq expression — matches metrics.md Step 7c exactly.
BATCH_JSON=$(
  printf '%s' "$RECORD" | jq -c \
    --arg api_key "$POSTHOG_PROJECT_API_KEY" \
    --arg project "$PROJECT" \
    '
    . as $r
    | ($r.task // "unknown") as $task
    | "shipwright/\($project)/\($task)" as $did
    | ($r.ts // (now | todate)) as $ts
    | [
        {
          event: "shipwright_task_completed",
          distinct_id: $did,
          timestamp: $ts,
          properties: {
            "$insert_id": "shipwright_task_completed/\($project)/\($task)",
            task_id: $task,
            project: $project,
            title: ($r.title // null),
            estimated_h: ($r.estimated_h // null),
            actual_h: ($r.actual_h // null),
            complexity: ($r.complexity // null),
            retries: ($r.retries // 0),
            files_changed: ($r.files_changed // null),
            model: ($r.model // null),
            ts: $ts
          }
        },

        (if $r.simplify then
          {
            event: "shipwright_simplify_pass",
            distinct_id: $did,
            timestamp: $ts,
            properties: {
              "$insert_id": "shipwright_simplify_pass/\($project)/\($task)",
              task_id: $task,
              project: $project,
              total_fixes: ($r.simplify.total // 0),
              dry: ($r.simplify.dry // 0),
              dead_code: ($r.simplify.dead_code // 0),
              naming: ($r.simplify.naming // 0),
              complexity_fixes: ($r.simplify.complexity // 0),
              consistency: ($r.simplify.consistency // 0)
            }
          }
        else empty end),

        (if $r.review then
          {
            event: "shipwright_review_pass",
            distinct_id: $did,
            timestamp: $ts,
            properties: {
              "$insert_id": "shipwright_review_pass/\($project)/\($task)",
              task_id: $task,
              project: $project,
              verdict: ($r.review.verdict // null),
              findings: ($r.review.findings // 0),
              fixes_applied: ($r.review.fixes_applied // 0),
              agents: (($r.review.agents // []) | join(","))
            }
          }
        else empty end),

        (if ($r.ci or (($r.ci_fix_attempts // 0) > 0)) then
          (($r.ci.fix_attempts // $r.ci_fix_attempts // 0) as $fa
           | {
              event: "shipwright_ci_gate",
              distinct_id: $did,
              timestamp: $ts,
              properties: {
                "$insert_id": "shipwright_ci_gate/\($project)/\($task)",
                task_id: $task,
                project: $project,
                fix_attempts: $fa,
                passed_first_try: ($fa == 0),
                failure_descriptions: (($r.ci.failures // []) | join(","))
              }
            })
        else empty end),

        (if $r.coverage then
          {
            event: "shipwright_coverage",
            distinct_id: $did,
            timestamp: $ts,
            properties: {
              "$insert_id": "shipwright_coverage/\($project)/\($task)",
              task_id: $task,
              project: $project,
              before: ($r.coverage.before // null),
              after: ($r.coverage.after // null),
              delta: ($r.coverage.delta // null)
            }
          }
        else empty end)
      ]
    | { api_key: $api_key, batch: . }
    '
)

TMP_BODY=$(mktemp -t ph-body.XXXXXX)
trap 'rm -f "$TMP_BODY"' EXIT

HTTP_CODE=$(curl -sS -o "$TMP_BODY" -w '%{http_code}' \
  -X POST "${POSTHOG_HOST}/batch/" \
  -H 'Content-Type: application/json' \
  --data-binary "$BATCH_JSON" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" != 2* ]]; then
  BODY_SNIP=$(head -c 300 "$TMP_BODY" 2>/dev/null || true)
  err "⚠ PostHog export failed: HTTP $HTTP_CODE — ${BODY_SNIP:-<no body>}"
  exit 1
fi

exit 0
