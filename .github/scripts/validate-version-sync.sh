#!/usr/bin/env bash
# Validates that plugin versions are in sync across all required locations:
#   1. plugins/<name>/.claude-plugin/plugin.json  (version field)
#   2. README.md (root)                           (plugin table)
#   3. plugins/<name>/README.md                   (heading, if present)
#
# Also checks:
#   - Every plugin in marketplace.json has a corresponding directory
#   - Every plugin directory is listed in marketplace.json
#   - Every plugin in marketplace.json appears in the root README table
#   - Every plugin in marketplace.json appears in the CLAUDE.md plugins list
set -euo pipefail

MARKETPLACE=".claude-plugin/marketplace.json"
ROOT_README="README.md"
CLAUDE_MD="CLAUDE.md"

errors=0
warnings=0

# Get list of plugins from marketplace.json
plugin_names=$(jq -r '.plugins[].name' "$MARKETPLACE")

for name in $plugin_names; do
  plugin_json="plugins/$name/.claude-plugin/plugin.json"

  # --- Check plugin directory exists ---
  if [ ! -d "plugins/$name" ]; then
    echo "ERROR: $name: directory plugins/$name/ does not exist"
    errors=$((errors + 1))
    continue
  fi

  # --- Check plugin.json exists and has version ---
  if [ ! -f "$plugin_json" ]; then
    echo "ERROR: $name: missing $plugin_json"
    errors=$((errors + 1))
    continue
  fi

  version=$(jq -r '.version // empty' "$plugin_json")
  if [ -z "$version" ]; then
    echo "ERROR: $name: no \"version\" field in $plugin_json"
    errors=$((errors + 1))
    continue
  fi

  # --- Check root README table ---
  # Match table rows like: | [name](plugins/name/README.md) | 1.0.0 | description |
  readme_line=$(grep "\[$name\]" "$ROOT_README" || true)
  readme_version=""
  if [ -n "$readme_line" ]; then
    # Table format: | [link](url) | version | description |
    # Field $3 is the version column when splitting on |
    readme_version=$(echo "$readme_line" | awk -F'|' '{gsub(/[ \t]/, "", $3); print $3}')
  fi

  if [ -z "$readme_version" ]; then
    echo "ERROR: $name: not found in $ROOT_README plugin table"
    errors=$((errors + 1))
  elif [ "$readme_version" != "$version" ]; then
    echo "ERROR: $name: version mismatch — plugin.json=$version, README table=$readme_version"
    errors=$((errors + 1))
  fi

  # --- Check plugin README heading (if version present) ---
  plugin_readme="plugins/$name/README.md"
  if [ -f "$plugin_readme" ]; then
    heading_version=$(grep -E '^# .* v[0-9]+\.[0-9]+\.[0-9]+' "$plugin_readme" | sed 's/.*v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/' || true)
    if [ -n "$heading_version" ] && [ "$heading_version" != "$version" ]; then
      echo "ERROR: $name: version mismatch — plugin.json=$version, README heading=v$heading_version"
      errors=$((errors + 1))
    fi
  fi

  # --- Check CLAUDE.md plugins list ---
  if ! grep -q "\*\*$name\*\*" "$CLAUDE_MD" 2>/dev/null; then
    echo "WARN: $name: not listed in $CLAUDE_MD plugins list"
    warnings=$((warnings + 1))
  fi
done

# --- Check for orphaned plugin directories ---
for dir in plugins/*/; do
  dir_name=$(basename "$dir")
  if ! echo "$plugin_names" | grep -qx "$dir_name"; then
    echo "WARN: $dir_name: exists in plugins/ but not listed in $MARKETPLACE"
    warnings=$((warnings + 1))
  fi
done

# --- Summary ---
count=$(echo "$plugin_names" | wc -w | tr -d ' ')
echo "---"
echo "Checked $count plugins: $errors error(s), $warnings warning(s)"

if [ "$errors" -gt 0 ]; then
  exit 1
fi
