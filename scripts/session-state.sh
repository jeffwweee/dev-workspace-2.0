#!/bin/bash
# session-state.sh - Central session state management
# Usage: ./scripts/session-state.sh <command> [args...]

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_DIR="$PROJECT_ROOT/state/sessions"

# Get timestamp
timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Start new session
cmd_start() {
  local chat_id="$1"
  local state_file="$STATE_DIR/${chat_id}-active.json"
  local log_file="$STATE_DIR/${chat_id}-log.jsonl"

  mkdir -p "$STATE_DIR"

  # Create state file
  cat > "$state_file" << EOF
{
  "chat_id": "$chat_id",
  "started": "$(timestamp)",
  "last_message": "$(timestamp)",
  "message_count": 0,
  "events": []
}
EOF

  # Create log file with session_start entry
  echo "{\"timestamp\":\"$(timestamp)\",\"type\":\"session_start\"}" > "$log_file"

  echo "Session started: $chat_id"
}

# Log event
cmd_log() {
  local chat_id="$1"
  local event_type="$2"
  shift 2
  local data="$*"

  local state_file="$STATE_DIR/${chat_id}-active.json"
  local log_file="$STATE_DIR/${chat_id}-log.jsonl"

  if [ ! -f "$state_file" ]; then
    # Auto-start if not exists
    cmd_start "$chat_id"
  fi

  # Update state file (increment message_count, update last_message)
  if command -v jq &> /dev/null; then
    local tmp_file=$(mktemp)
    jq ".last_message = \"$(timestamp)\" | .message_count += 1" "$state_file" > "$tmp_file"
    mv "$tmp_file" "$state_file"
  fi

  # Append to log file
  echo "{\"timestamp\":\"$(timestamp)\",\"type\":\"$event_type\",\"data\":$data}" >> "$log_file"
}

# Get session info
cmd_get() {
  local chat_id="$1"
  local field="$2"
  local state_file="$STATE_DIR/${chat_id}-active.json"

  if [ ! -f "$state_file" ]; then
    echo ""
    return
  fi

  if [ -z "$field" ]; then
    cat "$state_file"
  else
    jq -r ".$field" "$state_file" 2>/dev/null || echo ""
  fi
}

# End session
cmd_end() {
  local chat_id="$1"
  local state_file="$STATE_DIR/${chat_id}-active.json"

  if [ -f "$state_file" ]; then
    rm "$state_file"
    echo "Session ended: $chat_id"
  else
    echo "No active session: $chat_id"
  fi
}

# Command dispatcher
case "$1" in
  start) cmd_start "$2" ;;
  log) shift; cmd_log "$@" ;;
  get) cmd_get "$2" "$3" ;;
  end) cmd_end "$2" ;;
  *)
    echo "Usage: $0 <command> [args...]"
    echo "Commands:"
    echo "  start <chat_id>          - Start new session"
    echo "  log <chat_id> <type> <json_data> - Log event"
    echo "  get <chat_id> [field]    - Get session info"
    echo "  end <chat_id>            - End session"
    exit 1
    ;;
esac
