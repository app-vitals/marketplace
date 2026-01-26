#!/bin/bash

# State Manager for Phase-Isolated Feature Development
# Provides read operations on feature state files.
# macOS-compatible (bash 3.2, BSD grep, no associative arrays).

set -euo pipefail

FEATURES_DIR=".claude/features"

# Find the active feature directory (first IN_PROGRESS feature).
# Prints the feature directory path, or empty string if none found.
find_active_feature() {
  if [ ! -d "$FEATURES_DIR" ]; then
    echo ""
    return
  fi

  local state_file
  for state_file in "$FEATURES_DIR"/*/state.md; do
    [ -f "$state_file" ] || continue
    if grep -q '\*\*Status:\*\* IN_PROGRESS' "$state_file" 2>/dev/null; then
      dirname "$state_file"
      return
    fi
  done
  echo ""
}

# Get current phase from a state file.
# Usage: get_current_phase <state_file>
get_current_phase() {
  local state_file="$1"
  grep '\*\*Current Phase:\*\*' "$state_file" 2>/dev/null | sed 's/.*\*\*Current Phase:\*\* *//'
}

# Get current iteration for the active phase.
# Usage: get_iteration <state_file> <phase_name>
get_iteration() {
  local state_file="$1"
  local phase="$2"
  local line
  line=$(grep -E "\- \[ \] ${phase}" "$state_file" 2>/dev/null || echo "")
  if [ -z "$line" ]; then
    echo "0"
    return
  fi
  echo "$line" | grep -oE 'iteration: [0-9]+' | grep -oE '[0-9]+' || echo "0"
}

# Get max iterations for a given phase.
# Uses case statement instead of associative array for macOS bash 3.2 compat.
# Usage: get_max_iterations <phase_name>
get_max_iterations() {
  local phase="$1"
  case "$phase" in
    PHASE_1_REQUIREMENTS)  echo "10" ;;
    PHASE_2_EXPLORATION)   echo "10" ;;
    PHASE_3_ARCHITECTURE)  echo "15" ;;
    PHASE_4_IMPLEMENTATION) echo "25" ;;
    PHASE_5_REVIEW)        echo "10" ;;
    PHASE_6_TESTING)       echo "15" ;;
    PHASE_7_DOCUMENTATION) echo "5" ;;
    *)                     echo "10" ;;
  esac
}

# Update iteration count for the active phase.
# Uses temp file + mv for atomic write (macOS sed compat).
# Usage: update_iteration <state_file> <phase_name> <new_iteration>
update_iteration() {
  local state_file="$1"
  local phase="$2"
  local new_iter="$3"
  local max_iter
  max_iter=$(get_max_iterations "$phase")

  local temp_file="${state_file}.tmp.$$"
  sed "s/\(- \[ \] ${phase}.*iteration: \)[0-9]*/\1${new_iter}/" "$state_file" > "$temp_file"
  mv "$temp_file" "$state_file"

  # Update Last Updated timestamp
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  temp_file="${state_file}.tmp.$$"
  sed "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* ${now}/" "$state_file" > "$temp_file"
  mv "$temp_file" "$state_file"
}

# Update phase status in state file.
# Usage: update_phase_status <state_file> <phase_name> <status>
# status: "started" | "completed"
update_phase_status() {
  local state_file="$1"
  local phase="$2"
  local status="$3"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local temp_file="${state_file}.tmp.$$"

  case "$status" in
    completed)
      # Change [ ] to [x] and add completion timestamp
      local current_iter
      current_iter=$(get_iteration "$state_file" "$phase")
      sed "s/- \[ \] ${phase}.*/- [x] ${phase} (completed: ${now}, iterations: ${current_iter})/" "$state_file" > "$temp_file"
      mv "$temp_file" "$state_file"
      ;;
    started)
      local max_iter
      max_iter=$(get_max_iterations "$phase")
      sed "s/- \[ \] ${phase}.*/- [ ] ${phase} (started: ${now}, iteration: 1\/${max_iter})/" "$state_file" > "$temp_file"
      mv "$temp_file" "$state_file"
      ;;
  esac

  # Update Last Updated
  temp_file="${state_file}.tmp.$$"
  sed "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* ${now}/" "$state_file" > "$temp_file"
  mv "$temp_file" "$state_file"
}

# Get the next phase name after the given phase.
# Usage: get_next_phase <current_phase>
get_next_phase() {
  local current="$1"
  case "$current" in
    PHASE_1_REQUIREMENTS)  echo "PHASE_2_EXPLORATION" ;;
    PHASE_2_EXPLORATION)   echo "PHASE_3_ARCHITECTURE" ;;
    PHASE_3_ARCHITECTURE)  echo "PHASE_4_IMPLEMENTATION" ;;
    PHASE_4_IMPLEMENTATION) echo "PHASE_5_REVIEW" ;;
    PHASE_5_REVIEW)        echo "PHASE_6_TESTING" ;;
    PHASE_6_TESTING)       echo "PHASE_7_DOCUMENTATION" ;;
    PHASE_7_DOCUMENTATION) echo "" ;;
    *)                     echo "" ;;
  esac
}

# Get the feature slug from a feature directory path.
# Usage: get_slug <feature_dir>
get_slug() {
  basename "$1"
}

# List all features with their status.
# Prints: slug status current_phase
list_features() {
  if [ ! -d "$FEATURES_DIR" ]; then
    return
  fi

  local state_file
  for state_file in "$FEATURES_DIR"/*/state.md; do
    [ -f "$state_file" ] || continue
    local dir
    dir=$(dirname "$state_file")
    local slug
    slug=$(basename "$dir")
    local status
    status=$(grep '\*\*Status:\*\*' "$state_file" 2>/dev/null | sed 's/.*\*\*Status:\*\* *//')
    local phase
    phase=$(get_current_phase "$state_file")
    echo "${slug} ${status} ${phase}"
  done
}

# If called directly with a function name, execute it.
# Usage: bash state-manager.sh <function_name> [args...]
if [ $# -gt 0 ]; then
  func="$1"
  shift
  "$func" "$@"
fi
