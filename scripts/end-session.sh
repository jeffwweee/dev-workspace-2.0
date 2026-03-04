#!/bin/bash
# end-session.sh - Generate session summary and archive

set -e

CHAT_ID="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION_LOG="$PROJECT_ROOT/state/sessions/${CHAT_ID}-log.jsonl"
OBSERVATIONS_FILE="$PROJECT_ROOT/state/learning/observations.jsonl"
ARCHIVE_DIR="$PROJECT_ROOT/state/sessions/archive"
DATE=$(date +%Y-%m-%d)

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Get session start time from log
SESSION_START=""
if [ -f "$SESSION_LOG" ]; then
  SESSION_START=$(grep "session_start" "$SESSION_LOG" | head -1 | jq -r '.timestamp' 2>/dev/null || echo "")
fi

# Get commits since session start (or today if no start found)
if [ -n "$SESSION_START" ]; then
  SINCE=$(echo "$SESSION_START" | cut -dT -f1)
  COMMITS=$(git log --since="$SINCE 00:00:00" --oneline 2>/dev/null || echo "")
else
  COMMITS=$(git log -10 --oneline 2>/dev/null || echo "")
fi

# Get completed tasks from log
TASKS=""
if [ -f "$SESSION_LOG" ]; then
  TASKS=$(grep "task_completed" "$SESSION_LOG" | jq -r '.summary' 2>/dev/null || echo "")
fi

# Get design/plan files saved
DESIGNS=""
PLANS=""
if [ -f "$SESSION_LOG" ]; then
  DESIGNS=$(grep "design_saved" "$SESSION_LOG" | jq -r '.file' 2>/dev/null || echo "")
  PLANS=$(grep "plan_saved" "$SESSION_LOG" | jq -r '.file' 2>/dev/null || echo "")
fi

# Count observations
OBS_COUNT=0
if [ -f "$OBSERVATIONS_FILE" ]; then
  OBS_COUNT=$(grep -c . "$OBSERVATIONS_FILE" 2>/dev/null || echo "0")
fi

# Build summary
SUMMARY="# Session Summary - $DATE

## What Was Done
"

if [ -n "$TASKS" ]; then
  while IFS= read -r task; do
    [ -n "$task" ] && SUMMARY+="- $task\n"
  done <<< "$TASKS"
else
  SUMMARY+="- No tasks recorded\n"
fi

SUMMARY+="\n## Designs Created\n"
if [ -n "$DESIGNS" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] && SUMMARY+="- $file\n"
  done <<< "$DESIGNS"
else
  SUMMARY+="- None\n"
fi

SUMMARY+="\n## Plans Created\n"
if [ -n "$PLANS" ]; then
  while IFS= read -r file; do
    [ -n "$file" ] && SUMMARY+="- $file\n"
  done <<< "$PLANS"
else
  SUMMARY+="- None\n"
fi

SUMMARY+="\n## Commits\n"
if [ -n "$COMMITS" ]; then
  COMMIT_COUNT=0
  while IFS= read -r line; do
    [ -n "$line" ] && SUMMARY+="- $line\n"
    COMMIT_COUNT=$((COMMIT_COUNT + 1))
  done <<< "$COMMITS"
  SUMMARY+="\nTotal: $COMMIT_COUNT commits\n"
else
  SUMMARY+="- No commits this session\n"
fi

SUMMARY+="\n## Observations\n"
SUMMARY+="$OBS_COUNT observations captured\n"

SUMMARY+="\n---\n"
SUMMARY+="Archive: state/sessions/archive/${CHAT_ID}-${DATE}.md\n"

# Save archive file
ARCHIVE_FILE="$ARCHIVE_DIR/${CHAT_ID}-${DATE}.md"
echo -e "$SUMMARY" > "$ARCHIVE_FILE"

# Output summary for Telegram
echo -e "$SUMMARY"

# Output marker with observation count for conditional evolve
echo "---OBS_COUNT:$OBS_COUNT---"
