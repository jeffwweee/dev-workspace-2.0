#!/bin/bash
# candidates-list.sh - List pending candidates for review

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANDIDATES_DIR="$PROJECT_ROOT/state/learning/candidates"

if [ ! -d "$CANDIDATES_DIR" ]; then
  echo "No candidates directory"
  exit 0
fi

CANDIDATES=$(ls -1 "$CANDIDATES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')

if [ "$CANDIDATES" -eq 0 ]; then
  echo "No candidates pending review"
  exit 0
fi

echo "Found ${CANDIDATES} candidate file(s):"
echo ""
ls -1 "$CANDIDATES_DIR"/*.md 2>/dev/null | while read file; do
  basename "$file"
done
