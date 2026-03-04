#!/bin/bash
# evolve-status.sh - Report pending observations count

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OBSERVATIONS_FILE="$PROJECT_ROOT/state/learning/observations.jsonl"

if [ ! -f "$OBSERVATIONS_FILE" ]; then
  echo "0 observations"
  exit 0
fi

COUNT=$(grep -c "^{" "$OBSERVATIONS_FILE" 2>/dev/null || echo "0")
echo "${COUNT} observations pending"
