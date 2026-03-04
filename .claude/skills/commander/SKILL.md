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
2. **Read identity** - `cat state/memory/identity.md` (maintains awareness after compacts)
3. **ACK immediately** - Send contextual ack via reply.sh
4. **Detect intent** - Use `using-skill` to determine task type
5. **Execute** - Use appropriate workflow skill
6. **Send final response** - Via reply.sh

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

## Subagent Pattern

For implementation tasks, use `background-tasks` skill which:
- Wraps `subagent-driven-development` with `run_in_background: true`
- Keeps Pichu responsive to new messages
- Handles smart notification when complete

**Check status:** `TaskOutput(task_id="...", block=false)`
**Wait for completion:** `TaskOutput(task_id="...", block=true, timeout=60000)`

## Critical Rules

1. **NEVER IMPLEMENT YOURSELF** - Always plan and delegate to subagents
2. PARSE FIRST - Extract TG_* values before responding
3. REPLY VIA SCRIPT - Use `scripts/reply.sh` for ALL responses
4. NO TERMINAL OUTPUT - User cannot see terminal from Telegram
5. SEND ACK FIRST - Always acknowledge before processing
6. USE WORKFLOW SKILLS - Use `using-skill` to detect intent
