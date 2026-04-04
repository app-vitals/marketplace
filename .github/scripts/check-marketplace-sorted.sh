#!/usr/bin/env bash
# Checks that marketplace.json plugins are alphabetically sorted by name.
# Usage:
#   bash check-marketplace-sorted.sh          # check, exit 1 if unsorted
#   bash check-marketplace-sorted.sh --fix    # sort in place
set -euo pipefail

FILE=".claude-plugin/marketplace.json"

if [ "${1:-}" = "--fix" ]; then
  jq '.plugins |= sort_by(.name | ascii_downcase)' "$FILE" > "${FILE}.tmp"
  mv "${FILE}.tmp" "$FILE"
  count=$(jq '.plugins | length' "$FILE")
  echo "Sorted $count plugins"
  exit 0
fi

# Check sort order
names=$(jq -r '.plugins[].name' "$FILE")
sorted=$(echo "$names" | sort -f)

if [ "$names" != "$sorted" ]; then
  echo "ERROR: marketplace.json plugins are not sorted alphabetically"
  echo ""
  echo "Current order vs expected:"
  diff <(echo "$names") <(echo "$sorted") || true
  echo ""
  echo "Run: bash .github/scripts/check-marketplace-sorted.sh --fix"
  exit 1
fi

count=$(jq '.plugins | length' "$FILE")
echo "OK: $count plugins sorted alphabetically"
