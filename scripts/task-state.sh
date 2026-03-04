#!/bin/bash
# task-state.sh - Manage background task state files
# Usage: ./scripts/task-state.sh <command> [args...]

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASKS_DIR="$PROJECT_ROOT/state/tasks"

# Generate a simple task ID
generate_task_id() {
  echo "task_$(date +%s)"
}

# Get current ISO timestamp
get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# get_status <chat_id> - Returns: running|completed|failed|none
get_status() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    echo "none"
    return
  fi

  grep -m1 "^- Status:" "$summary_file" | sed 's/- Status: //' || echo "none"
}

# set_running <chat_id> <plan_file> <description>
set_running() {
  local chat_id="$1"
  local plan_file="$2"
  local description="$3"
  local task_id=$(generate_task_id)
  local timestamp=$(get_timestamp)

  local summary_file="$TASKS_DIR/${chat_id}.md"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  # Create summary file
  cat > "$summary_file" << EOF
# Task Summary for Chat ${chat_id}

## Last Message Time
- Timestamp: ${timestamp}
- Msg ID: 0

## Current/Last Task
- Task ID: ${task_id}
- Description: ${description}
- Status: running
- Started: ${timestamp}

## Pending Notification
- Has completed task: false
- Result summary:
EOF

  # Create detail file
  cat > "$detail_file" << EOF
# Task: ${task_id}

## Meta
- Chat ID: ${chat_id}
- Plan File: ${plan_file}
- Started: ${timestamp}
- Status: running

## Progress
- Current Step: Starting
- Completed Steps: None

## Review History
(Added as tasks complete)

## Final Summary
(Added on completion)
EOF

  echo "$task_id"
}

# set_completed <chat_id> <task_id> <summary>
set_completed() {
  local chat_id="$1"
  local task_id="$2"
  local summary="$3"
  local timestamp=$(get_timestamp)

  local summary_file="$TASKS_DIR/${chat_id}.md"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  # Update summary file
  sed -i "s/- Status: running/- Status: completed/" "$summary_file"
  sed -i "s/- Has completed task: false/- Has completed task: true/" "$summary_file"
  sed -i "s/- Result summary:/- Result summary: ${summary}/" "$summary_file"

  # Update detail file
  if [ -f "$detail_file" ]; then
    sed -i "s/- Status: running/- Status: completed/" "$detail_file"
    echo "" >> "$detail_file"
    echo "## Final Summary" >> "$detail_file"
    echo "- Completed: ${timestamp}" >> "$detail_file"
    echo "- Summary: ${summary}" >> "$detail_file"
  fi
}

# set_failed <chat_id> <task_id> <error>
set_failed() {
  local chat_id="$1"
  local task_id="$2"
  local error="$3"
  local timestamp=$(get_timestamp)

  local summary_file="$TASKS_DIR/${chat_id}.md"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  # Update summary file
  sed -i "s/- Status: running/- Status: failed/" "$summary_file"
  sed -i "s/- Has completed task: false/- Has completed task: true/" "$summary_file"
  sed -i "s/- Result summary:/- Result summary: ERROR: ${error}/" "$summary_file"

  # Update detail file
  if [ -f "$detail_file" ]; then
    sed -i "s/- Status: running/- Status: failed/" "$detail_file"
    echo "" >> "$detail_file"
    echo "## Final Summary" >> "$detail_file"
    echo "- Failed: ${timestamp}" >> "$detail_file"
    echo "- Error: ${error}" >> "$detail_file"
  fi
}

# get_task_id <chat_id> - Returns current task ID or empty
get_task_id() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    return
  fi

  grep -m1 "^- Task ID:" "$summary_file" | sed 's/- Task ID: //'
}

# update_last_message <chat_id> <msg_id>
update_last_message() {
  local chat_id="$1"
  local msg_id="$2"
  local timestamp=$(get_timestamp)
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ -f "$summary_file" ]; then
    sed -i "s/- Timestamp: .*/- Timestamp: ${timestamp}/" "$summary_file"
    sed -i "s/- Msg ID: .*/- Msg ID: ${msg_id}/" "$summary_file"
  fi
}

# check_idle <chat_id> [threshold_seconds] - Returns true if idle > threshold
check_idle() {
  local chat_id="$1"
  local threshold="${2:-60}"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    echo "true"
    return
  fi

  local last_ts=$(grep -m1 "^- Timestamp:" "$summary_file" | sed 's/- Timestamp: //')
  if [ -z "$last_ts" ]; then
    echo "true"
    return
  fi

  local last_epoch=$(date -d "$last_ts" +%s 2>/dev/null || echo "0")
  local now_epoch=$(date +%s)
  local diff=$((now_epoch - last_epoch))

  if [ "$diff" -gt "$threshold" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# has_pending_notification <chat_id> - Returns true|false
has_pending_notification() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    echo "false"
    return
  fi

  local has_completed=$(grep "^- Has completed task:" "$summary_file" | sed 's/- Has completed task: //')
  if [ "$has_completed" = "true" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# clear_notification <chat_id>
clear_notification() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ -f "$summary_file" ]; then
    sed -i "s/- Has completed task: true/- Has completed task: false/" "$summary_file"
  fi
}

# get_notification_summary <chat_id>
get_notification_summary() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ -f "$summary_file" ]; then
    grep "^- Result summary:" "$summary_file" | sed 's/- Result summary: //'
  fi
}

# increment_retry <chat_id> <task_id> [issue_description]
increment_retry() {
  local chat_id="$1"
  local task_id="$2"
  local issue="${3:-unknown}"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  if [ ! -f "$detail_file" ]; then
    echo "0"
    return
  fi

  # Get current retry count
  local current_count=$(grep "^- Retry Count:" "$detail_file" | sed 's/- Retry Count: //' || echo "0")
  local new_count=$((current_count + 1))

  # Update retry count
  if grep -q "^- Retry Count:" "$detail_file"; then
    sed -i "s/- Retry Count: .*/- Retry Count: ${new_count}/" "$detail_file"
  else
    # Add Retry Count section after Meta section
    sed -i "/^## Meta$/a\\
- Retry Count: ${new_count}\\
- Last Issue: ${issue}
" "$detail_file"
  fi

  # Update last issue
  sed -i "s/- Last Issue: .*/- Last Issue: ${issue}/" "$detail_file"

  echo "$new_count"
}

# get_retry_count <chat_id> <task_id>
get_retry_count() {
  local chat_id="$1"
  local task_id="$2"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  if [ ! -f "$detail_file" ]; then
    echo "0"
    return
  fi

  grep "^- Retry Count:" "$detail_file" | sed 's/- Retry Count: //' || echo "0"
}

# reset_retry <chat_id> <task_id>
reset_retry() {
  local chat_id="$1"
  local task_id="$2"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  if [ -f "$detail_file" ]; then
    sed -i "s/- Retry Count: .*/- Retry Count: 0/" "$detail_file"
  fi
}

# Command dispatcher
case "$1" in
  get_status) get_status "$2" ;;
  set_running) set_running "$2" "$3" "$4" ;;
  set_completed) set_completed "$2" "$3" "$4" ;;
  set_failed) set_failed "$2" "$3" "$4" ;;
  get_task_id) get_task_id "$2" ;;
  update_last_message) update_last_message "$2" "$3" ;;
  check_idle) check_idle "$2" "${3:-60}" ;;
  has_pending_notification) has_pending_notification "$2" ;;
  clear_notification) clear_notification "$2" ;;
  get_notification_summary) get_notification_summary "$2" ;;
  increment_retry) increment_retry "$2" "$3" "$4" ;;
  get_retry_count) get_retry_count "$2" "$3" ;;
  reset_retry) reset_retry "$2" "$3" ;;
  *)
    echo "Usage: $0 <command> [args...]"
    echo "Commands:"
    echo "  get_status <chat_id>"
    echo "  set_running <chat_id> <plan_file> <description>"
    echo "  set_completed <chat_id> <task_id> <summary>"
    echo "  set_failed <chat_id> <task_id> <error>"
    echo "  get_task_id <chat_id>"
    echo "  update_last_message <chat_id> <msg_id>"
    echo "  check_idle <chat_id> [threshold_seconds]"
    echo "  has_pending_notification <chat_id>"
    echo "  clear_notification <chat_id>"
    echo "  get_notification_summary <chat_id>"
    echo "  increment_retry <chat_id> <task_id> [issue_description]"
    echo "  get_retry_count <chat_id> <task_id>"
    echo "  reset_retry <chat_id> <task_id>"
    exit 1
    ;;
esac
