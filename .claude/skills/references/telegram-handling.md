# Telegram Message Handling

All workflow skills must handle Telegram messages correctly when invoked in Pichu session.

## Message Format

Every Telegram message starts with: `[TG:chat_id:bot_id:msg_id:reply_to]`

**Extract these values:**
- `TG_CHAT_ID` - Telegram chat ID
- `TG_BOT_ID` - Bot identifier (pichu, etc.)
- `TG_MSG_ID` - Message ID for threading
- `TG_REPLY_TO` - ID of message being replied to
- `TG_FILE` - Optional file attachment
- Message content (after the prefix)

**Regex:**
```bash
^\[TG:(\d+):([a-zA-Z]+):(\d+):(\d+)\](?:\[FILE:([^\]]+)\])?\s*(.*)$
```

## First Step: Always ACK

**When a skill receives a Telegram message:**

1. **Parse TG_* values** from the message prefix
2. **ACK immediately** via `scripts/reply.sh` - user waits for confirmation
3. **Then proceed** with the skill's actual work

**Why ACK first?** User cannot see terminal output from Telegram. Without ACK, they don't know if Pichu received the message.

## Reply Method

Use `scripts/reply.sh` for ALL Telegram responses:

```bash
# Basic reply
~/dev-workspace-v2/scripts/reply.sh BOT_ID CHAT_ID "message"

# Threaded reply (to specific message)
~/dev-workspace-v2/scripts/reply.sh BOT_ID CHAT_ID "message" "MSG_ID"

# Send file
~/dev-workspace-v2/scripts/send-file.sh BOT_ID CHAT_ID /path/to/file "caption" "MSG_ID"
```

**Do NOT use terminal output** - user cannot see it.

## Context Awareness

When working in Telegram:
- Use lettered options (a, b, c) instead of AskUserQuestion
- Keep responses concise (mobile screens are small)
- Use `scripts/send-file.sh` for design docs, plans, etc.
- Thread replies using TG_MSG_ID for context

## Non-Telegram Messages

If no `[TG:` prefix, respond normally in terminal (skips ACK step).
