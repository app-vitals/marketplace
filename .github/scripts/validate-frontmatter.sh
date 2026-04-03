#!/usr/bin/env bash
# Validates YAML frontmatter in agent, skill, and command .md files.
# Checks that required fields are present based on file type.
#
# Usage:
#   bash validate-frontmatter.sh <file.md>              # validate one file
#   bash validate-frontmatter.sh plugins/*/commands/*.md # validate many files
set -euo pipefail

errors=0
files_checked=0

validate_file() {
  local file="$1"
  local file_errors=0

  # Check file exists
  if [ ! -f "$file" ]; then
    echo "WARN: $file does not exist (may have been deleted)"
    return
  fi

  # Extract frontmatter (content between first two --- lines)
  if ! head -1 "$file" | grep -q '^---'; then
    echo "ERROR: $file: no frontmatter found (must start with ---)"
    errors=$((errors + 1))
    return
  fi

  # Get frontmatter content (between first and second ---)
  local frontmatter
  frontmatter=$(awk 'NR==1{next} /^---/{exit} {print}' "$file")

  if [ -z "$frontmatter" ]; then
    echo "ERROR: $file: empty frontmatter"
    errors=$((errors + 1))
    return
  fi

  # Determine file type from path (handles both relative and absolute paths)
  local file_type=""
  if echo "$file" | grep -qE '(^|/)agents/'; then
    # Skip agents nested inside skill content directories
    if echo "$file" | grep -qE '(^|/)skills/[^/]+/'; then
      return
    fi
    file_type="agent"
  elif echo "$file" | grep -qE '(^|/)skills/' && [ "$(basename "$file")" = "SKILL.md" ]; then
    file_type="skill"
  elif echo "$file" | grep -qE '(^|/)commands/'; then
    # Skip commands nested inside skill content directories
    if echo "$file" | grep -qE '(^|/)skills/[^/]+/'; then
      return
    fi
    file_type="command"
  else
    return
  fi

  files_checked=$((files_checked + 1))

  # Validate based on type
  case "$file_type" in
    agent)
      if ! echo "$frontmatter" | grep -q '^name:'; then
        echo "ERROR: $file (agent): missing required \"name\" field"
        file_errors=$((file_errors + 1))
      fi
      if ! echo "$frontmatter" | grep -q '^description:'; then
        echo "ERROR: $file (agent): missing required \"description\" field"
        file_errors=$((file_errors + 1))
      fi
      ;;
    skill)
      if ! echo "$frontmatter" | grep -q '^name:'; then
        echo "ERROR: $file (skill): missing required \"name\" field"
        file_errors=$((file_errors + 1))
      fi
      if ! echo "$frontmatter" | grep -qE '^(description:|when_to_use:)'; then
        echo "ERROR: $file (skill): missing required \"description\" field"
        file_errors=$((file_errors + 1))
      fi
      ;;
    command)
      if ! echo "$frontmatter" | grep -q '^description:'; then
        echo "ERROR: $file (command): missing required \"description\" field"
        file_errors=$((file_errors + 1))
      fi
      ;;
  esac

  if [ "$file_errors" -eq 0 ]; then
    echo "OK: $file ($file_type)"
  fi

  errors=$((errors + file_errors))
}

# Validate all files passed as arguments
for file in "$@"; do
  validate_file "$file"
done

echo "---"
echo "Validated $files_checked files: $errors error(s)"

if [ "$errors" -gt 0 ]; then
  exit 1
fi
