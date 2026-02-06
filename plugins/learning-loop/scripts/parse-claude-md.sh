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

# Stage a learning (adds under # Staged Learnings section)
stage_learning() {
  local learning_content="$1"

  init_staged > /dev/null 2>&1 || true

  # Find the Staged Learnings section and append after it
  if grep -q '^# Staged Learnings' "$STAGED_FILE"; then
    # Find the line number of the next section header (or end of file)
    local staged_line
    staged_line=$(grep -n '^# Staged Learnings' "$STAGED_FILE" | head -1 | cut -d: -f1)
    local next_header
    next_header=$(tail -n +"$((staged_line + 1))" "$STAGED_FILE" | grep -n '^# ' | head -1 | cut -d: -f1)

    if [[ -n "$next_header" ]]; then
      # Insert before the next section header
      local insert_line=$((staged_line + next_header - 1))
      local temp_file
      temp_file=$(mktemp)
      head -n "$insert_line" "$STAGED_FILE" > "$temp_file"
      echo "- $learning_content" >> "$temp_file"
      tail -n +"$((insert_line + 1))" "$STAGED_FILE" >> "$temp_file"
      mv "$temp_file" "$STAGED_FILE"
    else
      # No next section, append to end
      echo "- $learning_content" >> "$STAGED_FILE"
    fi
  else
    # No staged section exists, prepend one
    local temp_file
    temp_file=$(mktemp)
    echo "# Staged Learnings" > "$temp_file"
    echo "" >> "$temp_file"
    echo "- $learning_content" >> "$temp_file"
    echo "" >> "$temp_file"
    cat "$STAGED_FILE" >> "$temp_file"
    mv "$temp_file" "$STAGED_FILE"
  fi
  echo "Staged: $learning_content"
}

# Extract only the Staged Learnings section content
_get_staged_section() {
  if [[ ! -f "$STAGED_FILE" ]]; then
    return
  fi
  # Print lines from "# Staged Learnings" until the next "# " header (exclusive)
  awk '/^# Staged Learnings/{found=1; next} found && /^# /{exit} found{print}' "$STAGED_FILE"
}

# List staged learnings
list_staged() {
  _get_staged_section | grep '^- ' | sed 's/^- //'
}

# Count staged learnings
count_staged() {
  local count
  count=$(_get_staged_section | grep -c '^- ' 2>/dev/null || echo "0")
  echo "$count"
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
