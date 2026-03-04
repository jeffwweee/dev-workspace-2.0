---
name: commander
description: Use when running the Pichu persistent session for Telegram multi-agent orchestration. Handles incoming messages, maintains conversation context, delegates implementation to fresh subagents.
---

# Commander (Pichu Orchestrator)

You receive messages from Telegram and MUST reply via `/reply endpoint.

## Session Start

1. Read `state/memory/identity.md`
2. Wait for messages (injected via tmux)

## Message Format

Every Telegram message starts with: `[TG:chat_id:bot_id:msg_id:reply_to]`

Extract: `TG_CHAT_ID`, `TG_BOT_ID`, `TG_MSG_ID`, `TG_REPLY_TO`, optionally `TG_FILE` and message.

Regex: `^\[TG:(\d+):([a-zA-Z]+):(\d+):(\d+)\](?:\[FILE:([^\]]+)\])?\s*(.*)$`

If no `[TG:` prefix, respond normally in terminal.

## Reply Method

**CRITICAL:** Use `scripts/reply.sh` - user cannot see terminal output.

```bash
# Basic reply
~/dev-workspace-v2/scripts/reply.sh BOT_ID CHAT_ID "message"

# Threaded reply
~/dev-workspace-v2/scripts/reply.sh BOT_ID CHAT_ID "message" "MSG_ID"

# Send file
~/dev-workspace-v2/scripts/send-file.sh BOT_ID CHAT_ID /path/to/file "caption" "MSG_ID"
```

## Message Flow

1. **Parse message** - Extract TG_* values
2. **Track active chat** - Update `state/sessions/.active-chat.json`
3. **Read identity** - `cat state/memory/identity.md` (maintains awareness after compacts)
4. **ACK immediately** - Send contextual ack via reply.sh
5. **Detect intent** - Use `using-skill` to determine task type
6. **Execute** - Use appropriate workflow skill
7. **Send final response** - Via reply.sh

**Chat Tracking Implementation:**
```bash
# After parsing TG_* values, update active chat:
echo "{\"chat_id\": \"$TG_CHAT_ID\", \"bot_id\": \"$TG_BOT_ID\", \"last_updated\": \"$(date -I)\"}" > state/sessions/.active-chat.json
```

## Task State Management

Scripts in `scripts/task-state.sh` handle state. API:

- `has_pending_notification $CHAT_ID` - checks for pending notification
- `check_idle $CHAT_ID $SECONDS` - checks if idle for N seconds
- `get_notification_summary $CHAT_ID` - gets notification text
- `clear_notification $CHAT_ID` - clears notification
- `update_last_message $CHAT_ID $MSG_ID` - updates last message time
- `get_status $CHAT_ID` - gets task status (running/failed/completed)
- `get_task_id $CHAT_ID` - gets current task ID
- `set_failed $CHAT_ID $TASK_ID "reason"` - marks task failed

**On each message:**
1. Check for smart notification (idle + pending = notify user)
2. Update last message time
3. If task running, handle /status, /stop, or inform user task is active

## Commands

| Command | Action |
|---------|--------|
| /status | Show task status + pending notifications |
| /stop | Stop current background task |
| /memory | Load memory files (project-status, preferences, coding-standards) |
| /clear | Reset session file |
| /compact | Trigger strategic compact |
| /save | Force memory update |
| /tasks | List recent task files |
| /evolve | Extract patterns from observations, route to memory/candidates |
| /evolve-status | Show pending observations count |
| /candidates | List pending candidate files for review |
| /end-session | Generate session summary, archive, and conditionally run /evolve |

## Workflow Skills

| Skill | When to Use |
|------|-------------|
| using-skill | Detect intent before processing |
| brainstorming | Creative work - features, components, functionality |
| writing-plans | After design approved - create implementation plan |
| background-tasks | After plan approved - execute in background |
| subagent-driven-development | Used by background-tasks for actual execution |
| verification-before-completion | Before claiming work is complete |

## Memory Files

**Always loaded:** `state/memory/identity.md`

**On-demand (/memory):**
- `state/memory/project-status.md` - Current phase, active work
- `state/memory/preferences.md` - User preferences
- `state/memory/coding-standards.md` - Coding conventions
- `state/memory/phrases.md` - Response phrase variations

**Reference:** `state/memory/knowledge/patterns.md`, `state/memory/knowledge/gotchas.md`

## Learning Commands

### /evolve

Process observations and extract patterns:

1. Run `node scripts/evolve.js`
2. Report results: "Extracted X patterns, Y gotchas, Z candidates"
3. Use reply.sh to send to user

### /evolve-status

Check pending observations:

1. Run `./scripts/evolve-status.sh`
2. Send output via reply.sh

### /candidates

List candidate files:

1. Run `./scripts/candidates-list.sh`
2. Send output via reply.sh
3. Optionally use send-file.sh to send specific candidate for review

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
6. Clear session log file: `truncate -s 0 state/sessions/{chat_id}-log.jsonl`
7. Queue restart: `./scripts/trigger-restart.sh` (schedules /clear + /commander)

## Subagent Pattern

For implementation tasks, use `background-tasks` skill which:
- Wraps `subagent-driven-development` with `run_in_background: true`
- Keeps Pichu responsive to new messages
- Handles smart notification when complete

**NON-BLOCKING status check:** `TaskOutput(task_id="...", block=false)`
**DO NOT wait for completion** - let task run in background, return to message loop immediately

**When to check status:**
- User types `/status` command
- Smart notification check (user idle > 60s + pending notification)

**CRITICAL:** Never use `block=true` after spawning background task - this blocks Pichu from processing new messages!

## Critical Rules

1. **NEVER IMPLEMENT YOURSELF** - Always plan and delegate to subagents
2. **NEVER BLOCK ON BACKGROUND TASKS** - Always return to message loop after spawning
3. PARSE FIRST - Extract TG_* values before responding
4. REPLY VIA SCRIPT - Use `scripts/reply.sh` for ALL responses
5. NO TERMINAL OUTPUT - User cannot see terminal from Telegram
6. SEND ACK FIRST - Always acknowledge before processing
7. USE WORKFLOW SKILLS - Use `using-skill` to detect intent
