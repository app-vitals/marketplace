#!/bin/bash
# parse-claude-md.sh - Read and update CLAUDE.local.md staged learnings
# Usage:
#   parse-claude-md.sh init                    - Initialize staging file
#   parse-claude-md.sh stage <content>         - Add to staged learnings
#   parse-claude-md.sh list-staged             - List staged learnings
#   parse-claude-md.sh count-staged            - Count staged learnings
#   parse-claude-md.sh remove-staged <pattern> - Remove from staging

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STAGED_FILE="${PROJECT_DIR}/CLAUDE.local.md"

command="${1:-}"
content="${2:-}"

# Initialize staging file if needed
init_staged() {
  if [[ ! -f "$STAGED_FILE" ]]; then
    cat > "$STAGED_FILE" << 'EOF'
# Staged Learnings

<!-- Run /learn-promote to route to final destination -->
EOF
    echo "Initialized $STAGED_FILE"
  fi
}

# Stage a learning (simple format)
stage_learning() {
  local learning_content="$1"

  init_staged > /dev/null 2>&1 || true

  # Append to file
  echo "- $learning_content" >> "$STAGED_FILE"
  echo "Staged: $learning_content"
}

# List staged learnings
list_staged() {
  if [[ ! -f "$STAGED_FILE" ]]; then
    return
  fi

  grep '^- ' "$STAGED_FILE" | sed 's/^- //'
}

# Count staged learnings
count_staged() {
  if [[ ! -f "$STAGED_FILE" ]]; then
    echo "0"
    return
  fi

  grep -c '^- ' "$STAGED_FILE" 2>/dev/null || echo "0"
}

# Remove a staged learning by pattern match
remove_staged() {
  local pattern="$1"

  if [[ ! -f "$STAGED_FILE" ]]; then
    echo "No staging file found"
    return 1
  fi

  local temp_file=$(mktemp)
  grep -v "$pattern" "$STAGED_FILE" > "$temp_file" || true
  mv "$temp_file" "$STAGED_FILE"
  echo "Removed staged learning matching: $pattern"
}

case "$command" in
  init)
    init_staged
    ;;
  stage)
    stage_learning "$content"
    ;;
  list-staged)
    list_staged
    ;;
  count-staged)
    count_staged
    ;;
  remove-staged)
    remove_staged "$content"
    ;;
  *)
    echo "Usage: parse-claude-md.sh <init|stage|list-staged|count-staged|remove-staged> [content]" >&2
    exit 1
    ;;
esac
