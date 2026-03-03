# Pichu User Guide

Comprehensive documentation for the Pichu Telegram Agent System.

## Table of Contents

1. [Architecture Deep Dive](#architecture-deep-dive)
2. [Configuration](#configuration)
3. [Memory System](#memory-system)
4. [Available Commands](#available-commands)
5. [File Upload and Analysis](#file-upload-and-analysis)
6. [Reply Threading](#reply-threading)
7. [Sending Files](#sending-files)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Deep Dive

### System Overview

Pichu implements a multi-agent architecture with clear separation of concerns:

```
┌──────────────────────────────────────────────────────────────────┐
│                         Telegram API                             │
└─────────────────────────────┬────────────────────────────────────┘
                              │ Webhook POST
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Gateway (Express)                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  /webhook   │  │   /reply    │  │ /send-file  │              │
│  │  :3100      │  │             │  │             │              │
│  └──────┬──────┘  └──────▲──────┘  └──────▲──────┘              │
│         │                │                │                      │
│         │ tmux           │ HTTP           │ HTTP                 │
│         │ send-keys      │ POST           │ POST                 │
│         ▼                │                │                      │
└─────────┼────────────────┼────────────────┼──────────────────────┘
          │                │                │
          ▼                │                │
┌─────────────────────────┼────────────────┼──────────────────────┐
│  tmux session (cc-pichu)│                │                      │
│  ┌──────────────────────┼────────────────┼────────────────────┐ │
│  │       Pichu (Claude Code)             │                    │ │
│  │         Commander Skill               │                    │ │
│  │  ┌────────────────────────────────────┼──────────────────┐ │ │
│  │  │ 1. Parse [TG:chat:bot:msg:reply]   │                  │ │ │
│  │  │ 2. ACK via ./scripts/reply.sh ─────┘                  │ │ │
│  │  │ 3. Process (discuss or delegate)                      │ │ │
│  │  │ 4. Respond via ./scripts/reply.sh ────────────────────┘ │ │
│  │  └────────────────────────────────────────────────────────┘ │ │
│  │                          │                                  │ │
│  │                          │ Task tool                        │ │
│  │                          ▼                                  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              Subagent (fresh process)                │  │ │
│  │  │  - Isolated context                                  │  │ │
│  │  │  - Dies when complete                                │  │ │
│  │  │  - Returns results to Pichu                          │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Message Flow

1. **User sends message** in Telegram
2. **Telegram POSTs** to `/webhook/:botId` on the gateway
3. **Gateway**:
   - Downloads any attached files
   - Stores session data in Redis
   - Formats message with prefix: `[TG:chat_id:bot_id:msg_id:reply_to][FILE:/path] message`
   - Injects to tmux session via `send-keys`
4. **Pichu** receives the message in Claude Code:
   - Parses the `[TG:...]` prefix to extract metadata
   - Sends ACK via `./scripts/reply.sh`
   - Processes the request (discussion or delegation)
   - Sends final response via `./scripts/reply.sh`
5. **Reply script** POSTs to gateway `/reply` endpoint
6. **Gateway** calls Telegram API to send the message

### Why This Architecture?

- **Persistent Context**: Pichu maintains full conversation context
- **Fresh Subagents**: Implementation tasks get clean environments
- **Simple Integration**: HTTP-based, no hooks or complex setups
- **Debuggable**: All message flow is visible in tmux

---

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TELEGRAM_BOT_TOKEN_PICHU` | Yes | - | Bot token from @BotFather |
| `REDIS_URL` | No | `redis://localhost:6379` | Redis connection string |
| `PORT` | No | `3100` | Gateway server port |
| `TMUX_SESSION` | No | `cc-pichu:0.0` | Target tmux session:window.pane |
| `TMUX_DELAY_MS` | No | `500` | Delay before sending Enter key |
| `WEBHOOK_URL` | No | - | Public URL for Telegram webhook |
| `HOST` | No | `http://localhost:3100` | Fallback for webhook URL |

### Multiple Bots

You can configure multiple bots by adding additional token variables:

```bash
TELEGRAM_BOT_TOKEN_PICHU=token_for_pichu_bot
TELEGRAM_BOT_TOKEN_ASSISTANT=token_for_assistant_bot
```

Register each bot:
```bash
curl -X POST http://localhost:3100/register/pichu
curl -X POST http://localhost:3100/register/assistant
```

### Redis Configuration

Redis stores session metadata:

```
tg:session:CHAT_ID = {
  bot_id: "pichu",
  chat_id: 123456789,
  username: "user",
  last_message: "Hello",
  last_activity: 1709500000000
}
```

---

## Memory System

Pichu uses markdown files for persistent memory, stored in `state/memory/`.

### Memory Files

#### project-status.md

Tracks the current project state:

```markdown
# Project Status

## Current Phase
Development

## Active Work
- Feature X implementation

## Recent Decisions
- 2024-01-15: Chose PostgreSQL over MongoDB

## Blockers
- Waiting on API access

## Next Up
- Complete authentication
```

#### preferences.md

User communication and work preferences:

```markdown
# Preferences

## Communication
- Be concise
- Use bullet points
- Ask before making assumptions

## Work Style
- Prefer iterative development
- Run tests after changes
- Commit frequently
```

#### coding-standards.md

Coding conventions and patterns:

```markdown
# Coding Standards

## TypeScript
- Strict mode enabled
- Prefer interfaces over types
- Use const assertions

## Testing
- Jest for unit tests
- 80% coverage minimum

## Git
- Conventional commits
- PR before merge
```

#### knowledge/patterns.md

Reusable patterns discovered during work:

```markdown
# Patterns

## API Error Handling
Always wrap API calls in try-catch with user-friendly error messages.

## Telegram Message Formatting
Use MarkdownV2 via telegram-markdown-v2 converter.
```

#### knowledge/gotchas.md

Things to avoid:

```markdown
# Gotchas

## Telegram Rate Limits
Don't send more than 30 messages/second to the same chat.

## tmux Session Names
Must match TMUX_SESSION env var exactly.
```

### When Memory is Updated

- **Session Start**: Pichu loads all memory files
- **Task Complete**: Update project-status.md
- **New Learning**: Add to knowledge files
- **Preference Change**: Update preferences.md

---

## Available Commands

Pichu supports several slash commands:

### /status

Shows current project status from `project-status.md`:

```
/status
```

Response includes:
- Current phase
- Active work
- Recent decisions
- Blockers

### /stop

Stops any running background task:

```
/stop
```

Use when Pichu is working on a long task that needs cancellation.

### /clear

Clears the session state file:

```
/clear
```

Resets conversation context for the current chat.

### /compact

Triggers a strategic context compact:

```
/compact
```

Use when context is getting long. Pichu summarizes and keeps essential info.

---

## File Upload and Analysis

Users can send files to Pichu for analysis.

### Supported File Types

- **Images**: JPG, PNG, GIF, WebP
- **Documents**: PDF, TXT, JSON, CSV, code files

### How It Works

1. User sends photo or document in Telegram
2. Gateway downloads file to `state/files/`
3. Message includes `[FILE:/path/to/file]` prefix
4. Pichu can read and analyze the file

### Example Flow

User sends:
```
[photo of error screenshot]
What's wrong with this?
```

Pichu:
1. Receives: `[TG:123:pichu:42:0][FILE:/state/files/123_42_photo.jpg] What's wrong with this?`
2. Reads the file
3. Analyzes the error
4. Sends explanation

---

## Reply Threading

Messages can be sent as replies to create threads.

### How Threading Works

When Pichu receives a message that is a reply to another message:

```
[TG:123:pichu:42:15] Continue the thought
```

The `15` indicates this message is a reply to message ID 15.

### Responding to Threads

Pichu can respond to specific messages:

```bash
./scripts/reply.sh pichu 123456789 "Your response" "42"
```

The last parameter is the message ID to reply to.

### Use Cases

- Keep related messages together
- Answer specific questions in context
- Organize long conversations

---

## Sending Files

Pichu can send files back to Telegram.

### Using send-file.sh

```bash
./scripts/send-file.sh <bot_id> <chat_id> <file_path> "[caption]" "[reply_to_message_id]"
```

### Examples

Send a file:
```bash
./scripts/send-file.sh pichu 123456789 ./output/report.md
```

Send with caption:
```bash
./scripts/send-file.sh pichu 123456789 ./output/report.md "Here's the report"
```

Send as reply:
```bash
./scripts/send-file.sh pichu 123456789 ./output/report.md "Requested report" "42"
```

### When to Use

- Share generated code files
- Send analysis reports
- Provide exported data

---

## Troubleshooting

### Gateway Issues

#### Port Already in Use

```bash
# Find what's using the port
lsof -i :3100

# Kill the process
kill -9 <PID>
```

#### Webhook Not Working

1. Check webhook status:
```bash
curl https://api.telegram.org/botYOUR_TOKEN/getWebhookInfo
```

2. Re-register:
```bash
curl -X POST http://localhost:3100/register/pichu
```

3. For local development, use ngrok:
```bash
ngrok http 3100
# Use the ngrok URL as WEBHOOK_URL
```

### Redis Issues

#### Connection Refused

```bash
# Start Redis
redis-server

# Or with specific config
redis-server /path/to/redis.conf
```

#### Redis Not Responding

```bash
# Check Redis status
redis-cli ping

# Check Redis info
redis-cli info
```

### tmux Issues

#### Session Not Found

```bash
# List sessions
tmux ls

# Create session
./scripts/start-pichu.sh

# Or manually
tmux new -s cc-pichu
```

#### Wrong Target Pane

```bash
# Check TMUX_SESSION env var
echo $TMUX_SESSION

# List all panes
tmux list-panes -a

# Update in .env
TMUX_SESSION=cc-pichu:0.0
```

### Pichu Issues

#### Messages Not Being Parsed

- Ensure message starts with `[TG:`
- Check the tmux session is receiving input
- Verify the commander skill is loaded

#### Responses Not Sending

1. Check gateway is running
2. Verify bot token is correct
3. Test reply endpoint:
```bash
curl -X POST http://localhost:3100/reply \
  -H "Content-Type: application/json" \
  -d '{"bot_id":"pichu","chat_id":YOUR_CHAT_ID,"text":"Test"}'
```

### Debug Mode

Enable verbose logging:

```bash
DEBUG=* npm run gateway
```

### Getting Help

1. Check this guide
2. Review the [Quick Start](quickstart.md)
3. Open an issue on GitHub with:
   - Error messages
   - Steps to reproduce
   - Your environment (OS, Node version, etc.)
