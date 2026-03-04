# /end-session Command Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to implement this plan task-by-task.

**Goal:** Implement `/end-session` command with state tracking infrastructure, event logging, summary generation, and conditional /evolve trigger.

**Architecture:** Event-driven state tracking with JSONL logs, summary generation from git + session log + observations, archive to file, conditional evolve.

**Tech Stack:** Bash, jq, Node.js (evolve.js)

**Context:**
- Design doc: `docs/plans/2026-03-04-end-session-design.md`
- Existing evolve script: `scripts/evolve.js`
- Existing reply script: `scripts/reply.sh`
- Commander skill: `.claude/skills/commander/SKILL.md`

---

## Task 1: Create Session State Script

**Files:**
- Create: `scripts/session-state.sh`

**Changes:**
- [ ] Create central session state management script
- [ ] Implement start, log, get, end commands
- [ ] Handle JSON state file with jq
- [ ] Make executable

**Code:**

```bash
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
```

**Commands:**
```bash
cat > scripts/session-state.sh << 'SCRIPT_EOF'
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
    cmd_start "$chat_id"
  fi

  # Update state file
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

case "$1" in
  start) cmd_start "$2" ;;
  log) shift; cmd_log "$@" ;;
  get) cmd_get "$2" "$3" ;;
  end) cmd_end "$2" ;;
  *)
    echo "Usage: $0 <command> [args...]"
    echo "Commands: start, log, get, end"
    exit 1
    ;;
esac
SCRIPT_EOF

chmod +x scripts/session-state.sh
```

**Verification:**
```bash
# Test start
./scripts/session-state.sh start 195061634
cat state/sessions/195061634-active.json

# Test log
./scripts/session-state.sh log 195061634 message '{"text":"test"}'
cat state/sessions/195061634-log.jsonl

# Test get
./scripts/session-state.sh get 195061634 message_count

# Cleanup test
./scripts/session-state.sh end 195061634
```

---

## Task 2: Create Session Log Helper Script

**Files:**
- Create: `scripts/log-session.sh`

**Changes:**
- [ ] Create simpler wrapper for logging session events
- [ ] Handle different event types with proper JSON formatting
- [ ] Make executable

**Code:**

```bash
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
```

**Commands:**
```bash
cat > scripts/log-session.sh << 'SCRIPT_EOF'
#!/bin/bash
# log-session.sh - Append entry to session log

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/state/sessions/${1}-log.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

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
esac
SCRIPT_EOF

chmod +x scripts/log-session.sh
```

**Verification:**
```bash
./scripts/log-session.sh 195061634 task_started task-123 "Test task"
cat state/sessions/195061634-log.jsonl
```

---

## Task 3: Create End-Session Script

**Files:**
- Create: `scripts/end-session.sh`
- Create: `state/sessions/archive/.gitkeep`

**Changes:**
- [ ] Create session summary generator
- [ ] Parse session log, git commits, observations
- [ ] Generate formatted summary
- [ ] Create archive file
- [ ] Return observation count for conditional evolve

**Code:**

```bash
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
```

**Commands:**
```bash
cat > scripts/end-session.sh << 'SCRIPT_EOF'
#!/bin/bash
# end-session.sh - Generate session summary and archive

set -e

CHAT_ID="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION_LOG="$PROJECT_ROOT/state/sessions/${CHAT_ID}-log.jsonl"
OBSERVATIONS_FILE="$PROJECT_ROOT/state/learning/observations.jsonl"
ARCHIVE_DIR="$PROJECT_ROOT/state/sessions/archive"
DATE=$(date +%Y-%m-%d)

mkdir -p "$ARCHIVE_DIR"

# Get session start
SESSION_START=""
if [ -f "$SESSION_LOG" ]; then
  SESSION_START=$(grep "session_start" "$SESSION_LOG" | head -1 | jq -r '.timestamp' 2>/dev/null || echo "")
fi

# Get commits
if [ -n "$SESSION_START" ]; then
  SINCE=$(echo "$SESSION_START" | cut -dT -f1)
  COMMITS=$(git log --since="$SINCE 00:00:00" --oneline 2>/dev/null || echo "")
else
  COMMITS=$(git log -10 --oneline 2>/dev/null || echo "")
fi

# Get tasks
TASKS=$(grep "task_completed" "$SESSION_LOG" 2>/dev/null | jq -r '.summary' || echo "")

# Get files
DESIGNS=$(grep "design_saved" "$SESSION_LOG" 2>/dev/null | jq -r '.file' || echo "")
PLANS=$(grep "plan_saved" "$SESSION_LOG" 2>/dev/null | jq -r '.file' || echo "")

# Count observations
OBS_COUNT=0
[ -f "$OBSERVATIONS_FILE" ] && OBS_COUNT=$(wc -l < "$OBSERVATIONS_FILE" | tr -d ' ')

# Build summary
SUMMARY="# Session Summary - $DATE\n\n## What Was Done\n"
[ -n "$TASKS" ] && SUMMARY+=$(echo "$TASKS" | while read t; do [ -n "$t" ] && echo "- $t"; done)
[ -z "$TASKS" ] && SUMMARY+="- No tasks recorded"

SUMMARY+="\n\n## Commits\n"
[ -n "$COMMITS" ] && SUMMARY+=$(echo "$COMMITS" | while read c; do [ -n "$c" ] && echo "- $c"; done)
[ -z "$COMMITS" ] && SUMMARY+="- No commits"

SUMMARY+="\n\n## Observations: $OBS_COUNT\n"
SUMMARY+="\nArchive: state/sessions/archive/${CHAT_ID}-${DATE}.md\n"

# Save archive
echo -e "$SUMMARY" > "$ARCHIVE_DIR/${CHAT_ID}-${DATE}.md"

# Output
echo -e "$SUMMARY"
echo "---OBS_COUNT:$OBS_COUNT---"
SCRIPT_EOF

chmod +x scripts/end-session.sh
mkdir -p state/sessions/archive
touch state/sessions/archive/.gitkeep
```

**Verification:**
```bash
# Create test log
echo '{"timestamp":"2026-03-04T12:00:00Z","type":"session_start"}' > state/sessions/195061634-log.jsonl
echo '{"timestamp":"2026-03-04T12:30:00Z","type":"task_completed","task_id":"xxx","summary":"Test task"}' >> state/sessions/195061634-log.jsonl

# Run end-session
./scripts/end-session.sh 195061634

# Check archive
cat state/sessions/archive/195061634-2026-03-04.md
```

---

## Task 4: Update Commander Skill

**Files:**
- Modify: `.claude/skills/commander/SKILL.md`

**Changes:**
- [ ] Add /end-session to Commands table
- [ ] Add /end-session handler section
- [ ] Add session state logging on messages (optional enhancement)

**Code:**

In the Commands table (around line 87), add:
```markdown
| /end-session | Generate session summary, archive, and conditionally run /evolve |
```

Add new section after Learning Commands section (around line 136):
```markdown
## Session End Command

### /end-session

Complete the session with summary and archive:

1. Run `./scripts/end-session.sh {chat_id}`
2. Parse output - extract summary and OBS_COUNT
3. Send summary via reply.sh
4. Send archive file via send-file.sh
5. Check observation count:
   - If > 5: Run `node scripts/evolve.js` and report results
   - If <= 5: Send "Observations < 5, skipping /evolve"
6. Clear session log file: `> state/sessions/{chat_id}-log.jsonl`
```

**Verification:**
```bash
grep -A 15 "/end-session" .claude/skills/commander/SKILL.md
```

---

## Task 5: Update Background-Tasks Skill

**Files:**
- Modify: `.claude/skills/background-tasks/SKILL.md`

**Changes:**
- [ ] Add logging for task_started
- [ ] Add logging for task_completed

**Code:**

In the Process section (around line 18), add logging calls:
```markdown
## Process

1. Load plan → Generate task ID → Reply "Started background execution..."
   - Log: `./scripts/log-session.sh {chat_id} task_started {task_id} "{description}"`
2. Spawn subagent with `Task(tool)` - see `references/task-template.md`
3. Return to message loop (task runs in background)
4. Handle completion with smart notification
   - Log: `./scripts/log-session.sh {chat_id} task_completed {task_id} "{summary}"`
```

**Verification:**
```bash
grep "log-session" .claude/skills/background-tasks/SKILL.md
```

---

## Task 6: Update Brainstorming Skill

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md`

**Changes:**
- [ ] Add logging for design_saved event

**Code:**

In the "After Design Approved" section (around line 36), add:
```markdown
## After Design Approved

1. Save design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
   - Log: `./scripts/log-session.sh {chat_id} design_saved docs/plans/YYYY-MM-DD-<topic>-design.md`
2. Send via `scripts/send-file.sh` for review
...
```

**Verification:**
```bash
grep "log-session" .claude/skills/brainstorming/SKILL.md
```

---

## Task 7: Update Writing-Plans Skill

**Files:**
- Modify: `.claude/skills/writing-plans/SKILL.md`

**Changes:**
- [ ] Add logging for plan_saved event

**Code:**

In the Guidelines section or add new section:
```markdown
## After Plan Saved

1. Save plan to `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`
   - Log: `./scripts/log-session.sh {chat_id} plan_saved docs/plans/YYYY-MM-DD-<feature>-plan.md`
2. Check doc size with `./scripts/check-doc-size.sh`
3. Send for review
```

**Verification:**
```bash
grep "log-session" .claude/skills/writing-plans/SKILL.md
```

---

## Task 8: Integration Test

**Files:**
- None (testing only)

**Changes:**
- [ ] Test full session lifecycle
- [ ] Verify logging works
- [ ] Verify summary generation
- [ ] Verify conditional evolve

**Test Script:**

```bash
#!/bin/bash
# Test /end-session functionality

echo "=== End-Session Integration Test ==="

# Setup
CHAT_ID="test-123"
./scripts/session-state.sh start "$CHAT_ID"

# Test 1: Log events
echo "Test 1: Logging events..."
./scripts/log-session.sh "$CHAT_ID" task_started "task-001" "Test task"
./scripts/log-session.sh "$CHAT_ID" design_saved "docs/plans/test-design.md"
./scripts/log-session.sh "$CHAT_ID" plan_saved "docs/plans/test-plan.md"
./scripts/log-session.sh "$CHAT_ID" task_completed "task-001" "Test completed"

if [ -f "state/sessions/${CHAT_ID}-log.jsonl" ]; then
  LINES=$(wc -l < "state/sessions/${CHAT_ID}-log.jsonl" | tr -d ' ')
  echo "PASS: Log file has $LINES entries"
else
  echo "FAIL: Log file not created"
  exit 1
fi

# Test 2: End session summary
echo "Test 2: Generating summary..."
OUTPUT=$(./scripts/end-session.sh "$CHAT_ID")

if echo "$OUTPUT" | grep -q "Session Summary"; then
  echo "PASS: Summary generated"
else
  echo "FAIL: Summary not generated"
  exit 1
fi

# Test 3: Archive created
echo "Test 3: Checking archive..."
DATE=$(date +%Y-%m-%d)
if [ -f "state/sessions/archive/${CHAT_ID}-${DATE}.md" ]; then
  echo "PASS: Archive file created"
else
  echo "FAIL: Archive file not created"
  exit 1
fi

# Test 4: Observation count
echo "Test 4: Checking observation count..."
if echo "$OUTPUT" | grep -q "OBS_COUNT"; then
  echo "PASS: Observation count included"
else
  echo "FAIL: Observation count missing"
  exit 1
fi

# Cleanup
./scripts/session-state.sh end "$CHAT_ID"
rm -f "state/sessions/${CHAT_ID}-log.jsonl"

echo "=== All tests passed ==="
```

**Verification:**
```bash
chmod +x scripts/test-end-session.sh
./scripts/test-end-session.sh
```

---

## Task 9: Commit Changes

**Files:**
- None (git operations)

**Changes:**
- [ ] Stage all new and modified files
- [ ] Commit with descriptive message

**Commands:**
```bash
git add scripts/session-state.sh
git add scripts/log-session.sh
git add scripts/end-session.sh
git add state/sessions/archive/.gitkeep
git add .claude/skills/commander/SKILL.md
git add .claude/skills/background-tasks/SKILL.md
git add .claude/skills/brainstorming/SKILL.md
git add .claude/skills/writing-plans/SKILL.md

git commit -m "feat(session): add /end-session command with state tracking

- Add scripts/session-state.sh for central session state management
- Add scripts/log-session.sh for event logging
- Add scripts/end-session.sh for session summary generation
- Create state/sessions/archive/ for session archives
- Update Commander with /end-session command handler
- Update background-tasks to log task events
- Update brainstorming to log design saves
- Update writing-plans to log plan saves

Session summary includes:
- Tasks completed
- Commits made
- Observations captured
- Conditional /evolve (only if observations > 5)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Success Criteria

After all tasks complete:

- [ ] `scripts/session-state.sh` exists and manages session state
- [ ] `scripts/log-session.sh` exists and logs events
- [ ] `scripts/end-session.sh` exists and generates summaries
- [ ] `state/sessions/archive/` directory exists
- [ ] Commander skill has /end-session command
- [ ] background-tasks logs task events
- [ ] brainstorming logs design saves
- [ ] writing-plans logs plan saves
- [ ] Integration tests pass
- [ ] Git commit created
