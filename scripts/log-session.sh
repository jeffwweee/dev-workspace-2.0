#!/bin/bash
# log-session.sh - Append entry to session log
# Usage: ./scripts/log-session.sh <chat_id> <event_type> [args...]

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/state/sessions/${1}-log.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Ensure log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Build JSON entry based on type
case "$2" in
  session_start)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"session_start\"}" >> "$LOG_FILE"
    ;;
  task_started)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"task_started\",\"task_id\":\"$3\",\"description\":\"$4\"}" >> "$LOG_FILE"
    ;;
  task_completed)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"task_completed\",\"task_id\":\"$3\",\"summary\":\"$4\"}" >> "$LOG_FILE"
    ;;
  commit)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"commit\",\"hash\":\"$3\",\"message\":\"$4\"}" >> "$LOG_FILE"
    ;;
  design_saved)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"design_saved\",\"file\":\"$3\"}" >> "$LOG_FILE"
    ;;
  plan_saved)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"plan_saved\",\"file\":\"$3\"}" >> "$LOG_FILE"
    ;;
  message)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"message\",\"msg_id\":\"$3\"}" >> "$LOG_FILE"
    ;;
  *)
    echo "Unknown event type: $2" >&2
    exit 1
    ;;
esac
