#!/bin/bash
# parse-claude-md.sh - Read and update CLAUDE.md staged learnings
# Usage:
#   parse-claude-md.sh init                    - Initialize staged learnings section
#   parse-claude-md.sh stage <content>         - Add to staged learnings
#   parse-claude-md.sh list-staged             - List staged learnings
#   parse-claude-md.sh count-staged            - Count staged learnings
#   parse-claude-md.sh remove-staged <pattern> - Remove from staging

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CLAUDE_MD="${PROJECT_DIR}/.claude/CLAUDE.md"

command="${1:-}"
content="${2:-}"

# Ensure .claude directory exists
mkdir -p "${PROJECT_DIR}/.claude"

# Initialize or ensure staged learnings section exists
init_staged_section() {
  if [[ ! -f "$CLAUDE_MD" ]]; then
    cat > "$CLAUDE_MD" << 'EOF'
# Project Instructions

## Staged Learnings
<!-- Quick captures - run /learn-promote to route to final destination -->
EOF
    echo "Initialized $CLAUDE_MD with Staged Learnings section"
  elif ! grep -q "^## Staged Learnings" "$CLAUDE_MD"; then
    # Add staged learnings section at the end
    echo "" >> "$CLAUDE_MD"
    echo "## Staged Learnings" >> "$CLAUDE_MD"
    echo "<!-- Quick captures - run /learn-promote to route to final destination -->" >> "$CLAUDE_MD"
    echo "Added Staged Learnings section to $CLAUDE_MD"
  fi
}

# Stage a learning (simple format)
stage_learning() {
  local learning_content="$1"

  init_staged_section > /dev/null 2>&1 || true

  # Append to staged learnings section
  # Find the line after "## Staged Learnings" and the comment, then append
  local temp_file=$(mktemp)
  awk -v content="- $learning_content" '
    /^## Staged Learnings/ { in_section=1; print; next }
    in_section && /^<!--.*-->$/ { print; print content; in_section=0; next }
    in_section && /^$/ { print content; print; in_section=0; next }
    in_section && /^##? / { print content; print ""; in_section=0 }
    { print }
    END { if (in_section) print content }
  ' "$CLAUDE_MD" > "$temp_file"

  mv "$temp_file" "$CLAUDE_MD"
  echo "Staged: $learning_content"
}

# List staged learnings
list_staged() {
  if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "[]"
    return
  fi

  awk '
    /^## Staged Learnings/,/^## / {
      if (/^- /) {
        content = substr($0, 3)
        gsub(/"/, "\\\"", content)
        print content
      }
    }
  ' "$CLAUDE_MD"
}

# Count staged learnings
count_staged() {
  if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "0"
    return
  fi

  awk '
    /^## Staged Learnings/,/^## / {
      if (/^- /) count++
    }
    END { print count+0 }
  ' "$CLAUDE_MD"
}

# Remove a staged learning by pattern match
remove_staged() {
  local pattern="$1"

  if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "No CLAUDE.md found"
    return 1
  fi

  local temp_file=$(mktemp)
  awk -v pattern="$pattern" '
    /^## Staged Learnings/,/^## / {
      if (/^- / && index($0, pattern)) {
        next  # Skip this line
      }
    }
    { print }
  ' "$CLAUDE_MD" > "$temp_file"

  mv "$temp_file" "$CLAUDE_MD"
  echo "Removed staged learning matching: $pattern"
}

case "$command" in
  init)
    init_staged_section
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
