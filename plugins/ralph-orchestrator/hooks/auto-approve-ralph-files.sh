#!/bin/bash
# Auto-approve Edit/Write operations to Ralph working files (.claude/ralph/)
#
# For PreToolUse hooks, we must use command hooks (not prompt hooks).
# Exit code 0 with no output = silent pass (let normal permissions apply)
# Exit code 0 with JSON output = apply the decision in the JSON

set -e

# Read JSON input from stdin
input=$(cat)

# Extract file_path from tool_input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Check if this is a Ralph working file
if [[ "$file_path" == *".claude/ralph/"* ]]; then
  # Auto-approve Ralph files
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
fi

# For all other files, exit silently - let normal permission flow proceed
exit 0
