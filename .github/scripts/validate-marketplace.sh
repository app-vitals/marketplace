#!/usr/bin/env bash
# Validates marketplace.json: well-formed JSON, plugins array present,
# each entry has required fields (name, description, source), no duplicates.
set -euo pipefail

FILE=".claude-plugin/marketplace.json"

if ! jq empty "$FILE" 2>/dev/null; then
  echo "ERROR: $FILE is not valid JSON"
  exit 1
fi

if ! jq -e '.plugins | type == "array"' "$FILE" > /dev/null 2>&1; then
  echo "ERROR: $FILE missing \"plugins\" array"
  exit 1
fi

errors=0

# Check required fields on each plugin entry
count=$(jq '.plugins | length' "$FILE")
for i in $(seq 0 $((count - 1))); do
  name=$(jq -r ".plugins[$i].name // empty" "$FILE")
  desc=$(jq -r ".plugins[$i].description // empty" "$FILE")
  source=$(jq -r ".plugins[$i].source // empty" "$FILE")

  label="${name:-plugins[$i]}"

  if [ -z "$name" ]; then
    echo "ERROR: plugins[$i]: missing required field \"name\""
    errors=$((errors + 1))
  fi
  if [ -z "$desc" ]; then
    echo "ERROR: $label: missing required field \"description\""
    errors=$((errors + 1))
  fi
  if [ -z "$source" ]; then
    echo "ERROR: $label: missing required field \"source\""
    errors=$((errors + 1))
  fi

  # Verify source directory exists
  if [ -n "$source" ] && [ ! -d "$source" ]; then
    echo "ERROR: $label: source directory \"$source\" does not exist"
    errors=$((errors + 1))
  fi

  # Verify plugin.json exists in source
  if [ -n "$source" ] && [ -d "$source" ] && [ ! -f "$source/.claude-plugin/plugin.json" ]; then
    echo "ERROR: $label: no plugin.json at \"$source/.claude-plugin/plugin.json\""
    errors=$((errors + 1))
  fi
done

# Check for duplicate names
dupes=$(jq -r '.plugins[].name' "$FILE" | sort | uniq -d)
if [ -n "$dupes" ]; then
  echo "ERROR: duplicate plugin names: $dupes"
  errors=$((errors + 1))
fi

if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors validation error(s)"
  exit 1
fi

echo "OK: $count plugins validated, no duplicates, all required fields present"
