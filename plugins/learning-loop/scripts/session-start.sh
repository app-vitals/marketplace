#!/bin/bash

# Learning Loop Session Start Hook
# Shows staged learnings count if any exist

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CLAUDE_MD="${PROJECT_DIR}/.claude/CLAUDE.md"

# Exit silently if no CLAUDE.md
if [[ ! -f "$CLAUDE_MD" ]]; then
  exit 0
fi

# Count bullet points under "## Staged Learnings" section
staged_count=$(awk '
  /^## Staged Learnings/ { in_section=1; next }
  /^## / && in_section { in_section=0 }
  /^#[^#]/ && in_section { in_section=0 }
  in_section && /^- / { count++ }
  END { print count+0 }
' "$CLAUDE_MD" | tr -d '\n')

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
