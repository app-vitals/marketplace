#!/bin/bash

# Checkpoint Manager for Phase-Isolated Feature Development
# Provides write operations: initialize features, save/archive artifacts,
# complete/reset phases.
# macOS-compatible (bash 3.2, BSD grep, no associative arrays).

set -euo pipefail

FEATURES_DIR=".claude/features"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="${CLAUDE_PLUGIN_ROOT:-$SCRIPT_DIR/..}/skills/phase-workflow/assets/templates"

# Initialize a new feature.
# Creates the feature directory and state file from template.
# Usage: init_feature <slug> <description>
init_feature() {
  local slug="$1"
  local description="$2"
  local feature_dir="${FEATURES_DIR}/${slug}"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ -d "$feature_dir" ]; then
    echo "Error: Feature '${slug}' already exists at ${feature_dir}" >&2
    return 1
  fi

  mkdir -p "$feature_dir"

  # Generate feature name from slug (replace hyphens with spaces, title case first word)
  local feature_name
  feature_name=$(echo "$slug" | tr '-' ' ')

  # Copy and fill state template
  if [ -f "${TEMPLATES_DIR}/feature-state.md" ]; then
    sed \
      -e "s/{{FEATURE_NAME}}/${feature_name}/g" \
      -e "s/{{FEATURE_SLUG}}/${slug}/g" \
      -e "s|{{FEATURE_DESCRIPTION}}|${description}|g" \
      -e "s/{{CREATED_TIMESTAMP}}/${now}/g" \
      "${TEMPLATES_DIR}/feature-state.md" > "${feature_dir}/state.md"
  else
    echo "Error: State template not found at ${TEMPLATES_DIR}/feature-state.md" >&2
    return 1
  fi

  echo "$feature_dir"
}

# Save an artifact for a phase.
# Copies from template if artifact doesn't exist, or updates in place.
# Usage: save_artifact <feature_dir> <phase_name> <artifact_filename>
save_artifact() {
  local feature_dir="$1"
  local phase="$2"
  local artifact="$3"
  local state_file="${feature_dir}/state.md"
  local artifact_path="${feature_dir}/${artifact}"

  # If artifact doesn't exist and we have a template, copy it
  local template_name
  template_name=$(echo "$artifact" | tr '[:upper:]' '[:lower:]')
  if [ ! -f "$artifact_path" ] && [ -f "${TEMPLATES_DIR}/${template_name}" ]; then
    local feature_name
    feature_name=$(basename "$feature_dir" | tr '-' ' ')
    sed "s/{{FEATURE_NAME}}/${feature_name}/g" "${TEMPLATES_DIR}/${template_name}" > "$artifact_path"
  fi

  # Update artifact status in state.md
  local temp_file="${state_file}.tmp.$$"
  sed "s/| ${phase} |.*| Pending |/| ${phase} | .\/${artifact} | In Progress |/" "$state_file" > "$temp_file"
  mv "$temp_file" "$state_file"
}

# Archive an artifact (move to archive directory).
# Usage: archive_artifact <feature_dir> <artifact_filename>
archive_artifact() {
  local feature_dir="$1"
  local artifact="$2"
  local artifact_path="${feature_dir}/${artifact}"
  local archive_dir="${feature_dir}/archive"
  local now
  now=$(date -u +"%Y%m%dT%H%M%S")

  if [ ! -f "$artifact_path" ]; then
    return 0
  fi

  mkdir -p "$archive_dir"
  local base="${artifact%.*}"
  local ext="${artifact##*.}"
  mv "$artifact_path" "${archive_dir}/${base}-${now}.${ext}"
}

# Complete a phase: mark as done, advance to next phase.
# Usage: complete_phase <feature_dir> <phase_name>
complete_phase() {
  local feature_dir="$1"
  local phase="$2"
  local state_file="${feature_dir}/state.md"

  # Mark phase as completed
  source "${SCRIPT_DIR}/state-manager.sh"
  update_phase_status "$state_file" "$phase" "completed"

  # Get next phase
  local next_phase
  next_phase=$(get_next_phase "$phase")

  if [ -z "$next_phase" ]; then
    # All phases complete
    local temp_file="${state_file}.tmp.$$"
    sed "s/\*\*Status:\*\* IN_PROGRESS/\*\*Status:\*\* COMPLETE/" "$state_file" > "$temp_file"
    mv "$temp_file" "$state_file"

    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    temp_file="${state_file}.tmp.$$"
    sed "s/\*\*Current Phase:\*\*.*/\*\*Current Phase:\*\* COMPLETE/" "$state_file" > "$temp_file"
    mv "$temp_file" "$state_file"
  else
    # Advance to next phase
    local temp_file="${state_file}.tmp.$$"
    sed "s/\*\*Current Phase:\*\*.*/\*\*Current Phase:\*\* ${next_phase}/" "$state_file" > "$temp_file"
    mv "$temp_file" "$state_file"

    # Mark next phase as started
    update_phase_status "$state_file" "$next_phase" "started"
  fi
}

# Reset a phase: archive artifact, reset status in state.
# Usage: reset_phase <feature_dir> <phase_name>
reset_phase() {
  local feature_dir="$1"
  local phase="$2"
  local state_file="${feature_dir}/state.md"

  # Map phase to artifact filename
  local artifact=""
  case "$phase" in
    PHASE_1_REQUIREMENTS)  artifact="REQUIREMENTS.md" ;;
    PHASE_2_EXPLORATION)   artifact="EXPLORATION.md" ;;
    PHASE_3_ARCHITECTURE)  artifact="ARCHITECTURE.md" ;;
    PHASE_5_REVIEW)        artifact="REVIEW.md" ;;
    PHASE_6_TESTING)       artifact="TESTING.md" ;;
    PHASE_7_DOCUMENTATION) artifact="DOCS.md" ;;
    PHASE_4_IMPLEMENTATION) artifact="" ;;  # No single artifact to archive
  esac

  # Archive the artifact if it exists
  if [ -n "$artifact" ]; then
    archive_artifact "$feature_dir" "$artifact"
  fi

  # Reset phase status in state.md
  source "${SCRIPT_DIR}/state-manager.sh"
  local max_iter
  max_iter=$(get_max_iterations "$phase")
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local temp_file="${state_file}.tmp.$$"
  # Replace completed or in-progress phase line with fresh started line
  sed "s/- \[.\] ${phase}.*/- [ ] ${phase} (started: ${now}, iteration: 1\/${max_iter})/" "$state_file" > "$temp_file"
  mv "$temp_file" "$state_file"

  # Set current phase to the reset phase
  temp_file="${state_file}.tmp.$$"
  sed "s/\*\*Current Phase:\*\*.*/\*\*Current Phase:\*\* ${phase}/" "$state_file" > "$temp_file"
  mv "$temp_file" "$state_file"

  # Ensure status is IN_PROGRESS
  temp_file="${state_file}.tmp.$$"
  sed "s/\*\*Status:\*\* COMPLETE/\*\*Status:\*\* IN_PROGRESS/" "$state_file" > "$temp_file"
  mv "$temp_file" "$state_file"

  # Update artifact status to In Progress
  if [ -n "$artifact" ]; then
    local phase_display
    case "$phase" in
      PHASE_1_REQUIREMENTS)  phase_display="Requirements" ;;
      PHASE_2_EXPLORATION)   phase_display="Exploration" ;;
      PHASE_3_ARCHITECTURE)  phase_display="Architecture" ;;
      PHASE_5_REVIEW)        phase_display="Review" ;;
      PHASE_6_TESTING)       phase_display="Testing" ;;
      PHASE_7_DOCUMENTATION) phase_display="Documentation" ;;
    esac
    temp_file="${state_file}.tmp.$$"
    sed "s/| ${phase_display} |.*|/| ${phase_display} | .\/${artifact} | In Progress |/" "$state_file" > "$temp_file"
    mv "$temp_file" "$state_file"
  fi
}

# If called directly with a function name, execute it.
# Usage: bash checkpoint.sh <function_name> [args...]
if [ $# -gt 0 ]; then
  func="$1"
  shift
  "$func" "$@"
fi
