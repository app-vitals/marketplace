#!/bin/bash

# Phase-Isolated Feature Dev - Stop Hook
# Implements ralph-loop iteration pattern with phase awareness.
# On ANY error → exit 0 (allow stop). Never block when state is corrupt.
# macOS-compatible: no declare -A, no grep -oP, no sed -i, temp+mv for writes.

set -euo pipefail

FEATURES_DIR=".claude/features"
SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}/scripts"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# --- Find active feature state ---

if [ ! -d "$FEATURES_DIR" ]; then
  # No features directory — allow exit
  exit 0
fi

# Find first IN_PROGRESS feature
FEATURE_DIR=""
for state_candidate in "$FEATURES_DIR"/*/state.md; do
  [ -f "$state_candidate" ] || continue
  if grep -q '\*\*Status:\*\* IN_PROGRESS' "$state_candidate" 2>/dev/null; then
    FEATURE_DIR=$(dirname "$state_candidate")
    break
  fi
done

if [ -z "$FEATURE_DIR" ]; then
  # No active feature — allow exit
  exit 0
fi

STATE_FILE="$FEATURE_DIR/state.md"

# --- Parse phase + iteration from state.md ---

CURRENT_PHASE=$(grep '\*\*Current Phase:\*\*' "$STATE_FILE" 2>/dev/null | sed 's/.*\*\*Current Phase:\*\* *//' || echo "")

if [ -z "$CURRENT_PHASE" ] || [ "$CURRENT_PHASE" = "COMPLETE" ]; then
  # No current phase or feature complete — allow exit
  exit 0
fi

# Extract iteration count from the phase line
PHASE_LINE=$(grep -E "\- \[ \] ${CURRENT_PHASE}" "$STATE_FILE" 2>/dev/null || echo "")
CURRENT_ITERATION=$(echo "$PHASE_LINE" | grep -oE 'iteration: [0-9]+' | grep -oE '[0-9]+' || echo "")

if [ -z "$CURRENT_ITERATION" ] || ! echo "$CURRENT_ITERATION" | grep -qE '^[0-9]+$'; then
  # Can't parse iteration — state may be corrupt, allow exit
  echo "⚠️  Phase feature dev: Could not parse iteration from state file" >&2
  exit 0
fi

# Get max iterations for this phase (case statement, no associative array)
case "$CURRENT_PHASE" in
  PHASE_1_REQUIREMENTS)   MAX_FOR_PHASE=10 ;;
  PHASE_2_EXPLORATION)    MAX_FOR_PHASE=10 ;;
  PHASE_3_ARCHITECTURE)   MAX_FOR_PHASE=15 ;;
  PHASE_4_IMPLEMENTATION) MAX_FOR_PHASE=25 ;;
  PHASE_5_REVIEW)         MAX_FOR_PHASE=10 ;;
  PHASE_6_TESTING)        MAX_FOR_PHASE=15 ;;
  PHASE_7_DOCUMENTATION)  MAX_FOR_PHASE=5 ;;
  *)                      MAX_FOR_PHASE=10 ;;
esac

# --- Extract last assistant message from transcript ---

TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' 2>/dev/null || echo "")

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  # No transcript — allow exit
  echo "⚠️  Phase feature dev: Transcript not found, allowing exit" >&2
  exit 0
fi

# Check for assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null; then
  # No assistant output yet — allow exit
  exit 0
fi

# Extract last assistant message text
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [ -z "$LAST_LINE" ]; then
  exit 0
fi

LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>/dev/null || echo "")

if [ -z "$LAST_OUTPUT" ]; then
  # Could not parse assistant output — allow exit
  exit 0
fi

# --- Check for phase completion markers ---

if echo "$LAST_OUTPUT" | grep -q '<phase-complete>'; then
  # Phase completed — allow exit for session boundary
  echo "✅ Phase complete. Start a new session and run /feature-continue to proceed."
  exit 0
fi

if echo "$LAST_OUTPUT" | grep -q '<phase-blocked>'; then
  # Phase blocked — allow exit for human intervention
  echo "⚠️  Phase blocked. Review the blocker and restart when ready."
  exit 0
fi

# --- Check iteration limit ---

if [ "$CURRENT_ITERATION" -ge "$MAX_FOR_PHASE" ]; then
  echo "🛑 Phase iteration limit reached ($MAX_FOR_PHASE). Review progress and run /feature-continue."
  exit 0
fi

# --- Continue the loop ---

NEXT_ITERATION=$((CURRENT_ITERATION + 1))

# Update iteration count in state file (atomic write via temp+mv)
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/\(- \[ \] ${CURRENT_PHASE}.*iteration: \)[0-9]*/\1${NEXT_ITERATION}/" "$STATE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$STATE_FILE"

# Update Last Updated timestamp
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* ${NOW}/" "$STATE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$STATE_FILE"

# Build human-readable phase name
case "$CURRENT_PHASE" in
  PHASE_1_REQUIREMENTS)   PHASE_DISPLAY="Requirements" ;;
  PHASE_2_EXPLORATION)    PHASE_DISPLAY="Exploration" ;;
  PHASE_3_ARCHITECTURE)   PHASE_DISPLAY="Architecture" ;;
  PHASE_4_IMPLEMENTATION) PHASE_DISPLAY="Implementation" ;;
  PHASE_5_REVIEW)         PHASE_DISPLAY="Review" ;;
  PHASE_6_TESTING)        PHASE_DISPLAY="Testing" ;;
  PHASE_7_DOCUMENTATION)  PHASE_DISPLAY="Documentation" ;;
  *)                      PHASE_DISPLAY="$CURRENT_PHASE" ;;
esac

# Build continuation prompt
PROMPT="Continue working on the ${PHASE_DISPLAY} phase.

Review your progress and continue. When the phase is complete, output:
<phase-complete>${CURRENT_PHASE}</phase-complete>

If blocked, output:
<phase-blocked>
Blocker: <description>
Needs: <what is needed>
</phase-blocked>"

SYSTEM_MSG="🔄 Phase iteration ${NEXT_ITERATION}/${MAX_FOR_PHASE} (${PHASE_DISPLAY})"

# Output JSON to block stop and feed prompt back
jq -n \
  --arg reason "$PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $reason,
    "systemMessage": $msg
  }'

exit 0
