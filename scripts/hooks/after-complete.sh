#!/bin/bash
# after-complete.sh - Capture subagent completion context
# Usage: Source this with environment variables set

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OBSERVATIONS_FILE="$PROJECT_ROOT/state/learning/observations.jsonl"

# Ensure observations file exists
mkdir -p "$(dirname "$OBSERVATIONS_FILE")"
touch "$OBSERVATIONS_FILE"

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build JSON object using jq for proper escaping
# Fall back to simple JSON if jq not available
if command -v jq &> /dev/null; then
  jq -n -c \
    --arg ts "$TIMESTAMP" \
    --arg task_id "$TASK_ID" \
    --arg task_type "$TASK_TYPE" \
    --arg prompt "$TASK_PROMPT" \
    --arg result "$TASK_RESULT" \
    --arg files "$FILES_CHANGED" \
    --argjson patterns "${PATTERNS_DETECTED:-[]}" \
    --argjson decisions "${DECISIONS:-[]}" \
    --argjson errors "${ERRORS_RESOLVED:-[]}" \
    '{
      timestamp: $ts,
      task_id: $task_id,
      task_type: $task_type,
      prompt: $prompt,
      result_summary: $result,
      files_changed: ($files | split(" ")),
      patterns_detected: $patterns,
      decisions: $decisions,
      errors_resolved: $errors
    }' >> "$OBSERVATIONS_FILE"
else
  # Simple fallback without jq
  cat >> "$OBSERVATIONS_FILE" << EOF
{"timestamp":"$TIMESTAMP","task_id":"$TASK_ID","task_type":"$TASK_TYPE","prompt":"$TASK_PROMPT","result_summary":"$TASK_RESULT","files_changed":["$FILES_CHANGED"],"patterns_detected":[],"decisions":[],"errors_resolved":[]}
EOF
fi

echo "Observation logged: $TASK_ID"
