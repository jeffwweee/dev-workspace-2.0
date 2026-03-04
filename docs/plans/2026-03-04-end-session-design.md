# /end-session Command Design

## Overview

Implement an `/end-session` command that provides a comprehensive session summary, archives the session, and conditionally triggers `/evolve` to process learnings.

## Design Decisions

| Aspect | Decision |
|--------|----------|
| Activity tracking | Session log file (append during session) |
| Lessons/takeaways | Extract from observations.jsonl |
| Output format | Telegram message + archive file |
| /evolve trigger | Conditional (only if observations > 5) |

## User Experience

```
User: /end-session

Pichu:
📊 Session Summary - 2026-03-04

**What was done:**
• Implemented Hook System for learning capture
• Fixed compact trigger with doc-size check
• Added /evolve, /evolve-status, /candidates commands

**Commits (3):**
• 553ebbc - feat(compact): add doc-size-based compact recommendation
• 5377cf0 - feat(hooks): add after_complete hook system
• [more...]

**Lessons learned:**
• State tracking infrastructure needed before auto-compact
• Doc-size is reliable proxy for context consumption

**Key takeaways:**
• Hook system enables learning capture from subagents
• Simple file-size checks work better than complex state tracking

**Archive saved:** state/sessions/archive/195061634-2026-03-04.md

---

5 observations captured. Running /evolve...
[evolve output]
```

## Architecture

```
/end-session command
       ↓
1. Generate session summary
   - Read session log file
   - Extract git commits since session start
   - Parse observations for lessons/takeaways
       ↓
2. Create archive file
   - state/sessions/archive/{chat_id}-{date}.md
       ↓
3. Send summary to Telegram
   - Formatted message via reply.sh
   - Send archive file via send-file.sh
       ↓
4. Conditional /evolve
   - Count observations
   - If > 5: run evolve.js
   - If <= 5: skip with message
```

## Components

### 0. State Tracking Infrastructure (Foundation)

**Problem:** Current state tracking doesn't work:
- Session file not updated during conversation
- `update_last_message` not called on each message
- No event logging infrastructure

**Solution:** Build event-driven state tracking as foundation.

**File:** `scripts/session-state.sh`

**Purpose:** Central session state management

**API:**
```bash
# Start new session
./scripts/session-state.sh start {chat_id}

# Log event
./scripts/session-state.sh log {chat_id} {event_type} {json_data}

# Get session info
./scripts/session-state.sh get {chat_id} {field}

# End session
./scripts/session-state.sh end {chat_id}
```

**Integration points:**
- Commander: Call `session-state.sh log` on every message
- background-tasks: Log task start/complete
- brainstorming: Log design saved
- writing-plans: Log plan saved
- Subagents: Log commits

**State file:** `state/sessions/{chat_id}-active.json`
```json
{
  "chat_id": "195061634",
  "started": "2026-03-04T12:00:00Z",
  "last_message": "2026-03-04T13:00:00Z",
  "message_count": 42,
  "events": [
    {"timestamp": "...", "type": "task_started", "data": {...}},
    {"timestamp": "...", "type": "task_completed", "data": {...}}
  ]
}
```

### 1. Session Log File

**File:** `state/sessions/{chat_id}-log.jsonl`

**Purpose:** Track session activity as it happens

**Format:** Append-only JSON lines
```json
{"timestamp": "2026-03-04T12:00:00Z", "type": "task_started", "task_id": "xxx", "description": "Hook System"}
{"timestamp": "2026-03-04T12:30:00Z", "type": "task_completed", "task_id": "xxx", "summary": "Implemented hooks"}
{"timestamp": "2026-03-04T13:00:00Z", "type": "commit", "hash": "553ebbc", "message": "feat: ..."}
```

**Entry types:**
- `session_start` - When session begins
- `task_started` - When background task starts
- `task_completed` - When task finishes
- `commit` - Git commit made
- `design_saved` - Design doc created
- `plan_saved` - Implementation plan created

### 2. Session Summary Generator

**File:** `scripts/end-session.sh`

**Purpose:** Generate comprehensive session summary

**Process:**
1. Read session log file
2. Get git commits since session start
3. Parse observations.jsonl for patterns
4. Format summary
5. Create archive file
6. Send to Telegram
7. Conditionally run /evolve

**Code:**
```bash
#!/bin/bash
# end-session.sh - Generate session summary and archive

CHAT_ID="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION_LOG="$PROJECT_ROOT/state/sessions/${CHAT_ID}-log.jsonl"
OBSERVATIONS_FILE="$PROJECT_ROOT/state/learning/observations.jsonl"
ARCHIVE_DIR="$PROJECT_ROOT/state/sessions/archive"
DATE=$(date +%Y-%m-%d)

# Get session start time
SESSION_START=$(jq -r 'select(.type == "session_start") | .timestamp' "$SESSION_LOG" 2>/dev/null | head -1)

# Get commits since session start
if [ -n "$SESSION_START" ]; then
  SINCE_DATE=$(date -d "$SESSION_START" +%Y-%m-%d 2>/dev/null || echo "today")
  COMMITS=$(git log --since="$SINCE_DATE" --oneline 2>/dev/null || echo "None")
else
  COMMITS=$(git log -10 --oneline 2>/dev/null || echo "None")
fi

# Count observations
OBS_COUNT=0
if [ -f "$OBSERVATIONS_FILE" ]; then
  OBS_COUNT=$(wc -l < "$OBSERVATIONS_FILE" | tr -d ' ')
fi

# Generate summary
SUMMARY="# Session Summary - $DATE

## What Was Done
$(jq -r 'select(.type == "task_completed") | "- " + .summary' "$SESSION_LOG" 2>/dev/null || echo "- No tasks recorded")

## Commits
$(echo "$COMMITS" | head -10 | while read line; do echo "- $line"; done)

## Observations Captured
$OBS_COUNT observations logged

## Archive
Session archived to: state/sessions/archive/${CHAT_ID}-${DATE}.md
"

# Create archive directory
mkdir -p "$ARCHIVE_DIR"

# Save archive file
ARCHIVE_FILE="$ARCHIVE_DIR/${CHAT_ID}-${DATE}.md"
echo "$SUMMARY" > "$ARCHIVE_FILE"

# Output summary for Pichu to send
echo "$SUMMARY"

# Return observation count for conditional evolve
echo "---OBS_COUNT:$OBS_COUNT"
```

### 3. Commander Integration

**Update:** `.claude/skills/commander/SKILL.md`

Add to Commands table:
```markdown
| /end-session | Generate session summary, archive, and conditionally run /evolve |
```

Add handler section:
```markdown
## Session End Command

### /end-session

Complete the session with summary and archive:

1. Run `./scripts/end-session.sh {chat_id}`
2. Parse output - summary + observation count
3. Send summary via reply.sh
4. Send archive file via send-file.sh
5. Check observation count:
   - If > 5: Run `node scripts/evolve.js` and report results
   - If <= 5: Skip with "Observations < 5, skipping /evolve"
6. Clear session log file for next session
```

### 4. Session Log Appender

**File:** `scripts/log-session.sh`

**Purpose:** Append entries to session log during session

**Code:**
```bash
#!/bin/bash
# log-session.sh - Append entry to session log

CHAT_ID="$1"
ENTRY_TYPE="$2"
shift 2
REST="$@"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION_LOG="$PROJECT_ROOT/state/sessions/${CHAT_ID}-log.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build JSON entry based on type
case "$ENTRY_TYPE" in
  session_start)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"session_start\"}" >> "$SESSION_LOG"
    ;;
  task_started)
    TASK_ID="$1"; DESCRIPTION="$2"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"task_started\",\"task_id\":\"$TASK_ID\",\"description\":\"$DESCRIPTION\"}" >> "$SESSION_LOG"
    ;;
  task_completed)
    TASK_ID="$1"; SUMMARY="$2"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"task_completed\",\"task_id\":\"$TASK_ID\",\"summary\":\"$SUMMARY\"}" >> "$SESSION_LOG"
    ;;
  commit)
    HASH="$1"; MESSAGE="$2"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"commit\",\"hash\":\"$HASH\",\"message\":\"$MESSAGE\"}" >> "$SESSION_LOG"
    ;;
  design_saved)
    FILE="$1"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"design_saved\",\"file\":\"$FILE\"}" >> "$SESSION_LOG"
    ;;
  plan_saved)
    FILE="$1"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"plan_saved\",\"file\":\"$FILE\"}" >> "$SESSION_LOG"
    ;;
esac
```

### 5. Integration Points

**On task start** (background-tasks skill):
```bash
./scripts/log-session.sh {chat_id} task_started {task_id} "{description}"
```

**On task complete** (background-tasks skill):
```bash
./scripts/log-session.sh {chat_id} task_completed {task_id} "{summary}"
```

**On commit** (subagent-driven-development):
```bash
./scripts/log-session.sh {chat_id} commit {hash} "{message}"
```

**On design saved** (brainstorming skill):
```bash
./scripts/log-session.sh {chat_id} design_saved {file_path}
```

**On plan saved** (writing-plans skill):
```bash
./scripts/log-session.sh {chat_id} plan_saved {file_path}
```

## Files Changed

### New Files
- `scripts/session-state.sh` - Central session state management
- `scripts/end-session.sh` - Session summary generator
- `state/sessions/archive/` - Archive directory

### Modified Files
- `.claude/skills/commander/SKILL.md` - Add /end-session command, call session-state on messages
- `.claude/skills/background-tasks/SKILL.md` - Log task events
- `.claude/skills/brainstorming/SKILL.md` - Log design saves
- `.claude/skills/writing-plans/SKILL.md` - Log plan saves

## Session Lifecycle

```
1. Session Start (first message or /start-session)
   → Create session log file
   → Append session_start entry

2. During Session
   → Log task_started when background task begins
   → Log task_completed when task finishes
   → Log commit when git commit made
   → Log design_saved when design doc created
   → Log plan_saved when plan doc created

3. Session End (/end-session)
   → Generate summary from log + git + observations
   → Create archive file
   → Send to Telegram
   → Run /evolve if observations > 5
   → Clear session log for next session
```

## Observation Count Threshold

| Observations | Action |
|--------------|--------|
| 0-5 | Skip /evolve, message "Not enough data" |
| 6-10 | Run /evolve, report results |
| 11+ | Run /evolve, may find more patterns |

## Implementation Phases

### Phase 1: State Tracking Infrastructure
- [ ] Create `scripts/session-state.sh` with full API
- [ ] Update Commander to call session-state on every message
- [ ] Create `state/sessions/{chat_id}-active.json` on session start
- [ ] Test message counting and event logging

### Phase 2: Event Logging Integration
- [ ] Update background-tasks to log task events
- [ ] Update brainstorming to log design saves
- [ ] Update writing-plans to log plan saves
- [ ] Update subagents to log commits

### Phase 3: End-Session Scripts
- [ ] Create `scripts/end-session.sh`
- [ ] Create `state/sessions/archive/` directory
- [ ] Implement summary generation from state + git + observations

### Phase 4: Commander Integration
- [ ] Add /end-session to Commands table
- [ ] Add /end-session handler section
- [ ] Add /start-session command (optional, or auto-start)

### Phase 5: Testing
- [ ] Test session state creation and updates
- [ ] Test event logging from all sources
- [ ] Test summary generation
- [ ] Test archive creation
- [ ] Test conditional /evolve

## Success Criteria

- [ ] `/end-session` generates summary with:
  - Tasks completed
  - Commits made
  - Lessons extracted
  - Key takeaways
- [ ] Summary sent to Telegram
- [ ] Archive file created in state/sessions/archive/
- [ ] Archive file sent via send-file.sh
- [ ] /evolve runs conditionally based on observation count
- [ ] Session log cleared for next session
