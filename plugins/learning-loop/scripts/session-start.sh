#!/bin/bash

# Learning Loop Session Start Hook
# Shows staged learnings count if any exist

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STAGED_FILE="${PROJECT_DIR}/CLAUDE.local.md"

# Exit silently if no staging file
if [[ ! -f "$STAGED_FILE" ]]; then
  exit 0
fi

# Count bullet points (whole file is staging)
staged_count=$(grep -c '^- ' "$STAGED_FILE" 2>/dev/null || echo 0)

# Show message if there are staged learnings
if [[ "$staged_count" -gt 0 ]]; then
  MESSAGE="📝 Learning Loop: ${staged_count} staged learning(s) - run /learn-promote to route them."

  # Write to /dev/tty for user visibility (workaround for SessionStart not showing stdout)
  # See: https://github.com/anthropics/claude-code/issues/11120
  if [[ -w /dev/tty ]]; then
    printf "%s\n" "$MESSAGE" > /dev/tty 2>/dev/null || true
  fi

  # Also echo for Claude's context
  echo "$MESSAGE"
fi

exit 0
