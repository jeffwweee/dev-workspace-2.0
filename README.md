# Pichu - Telegram Agent System

A multi-agent Telegram orchestration system powered by Claude Code. Features a persistent orchestrator (Pichu) for conversation and coordination, with fresh subagents for implementation tasks.

## Architecture

```
┌─────────────┐
│   Telegram  │
└──────┬──────┘
       │ webhook
       ▼
┌─────────────┐
│   Gateway   │ :3100
│  /webhook   │──► tmux injection
│   /reply    │◄── HTTP POST
│ /send-file  │◄── HTTP POST
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Pichu    │ (persistent tmux session)
│  commander  │
└──────┬──────┘
       │ Task tool
       ▼
┌─────────────┐
│  Subagent   │ (fresh, dies when done)
└─────────────┘
```

## Quick Start

```bash
# Install dependencies
npm install

# Start Redis (if not running)
redis-server &

# Start gateway
npm run gateway

# In another terminal, start Pichu session
./scripts/start-pichu.sh
tmux attach -t cc-pichu
# Then: claude
# Then: /commander
```

For detailed setup instructions, see the [Quick Start Guide](docs/quickstart.md).

## Features

- **Persistent Orchestration**: Pichu maintains conversation context and memory across sessions
- **Fresh Subagents**: Implementation tasks run in isolated subagent processes
- **File-Based Memory**: Project status, preferences, and knowledge persist in markdown files
- **File Upload/Analysis**: Send images and documents for AI analysis
- **File Attachments**: Send files back to Telegram
- **Reply Threading**: Messages can be threaded as replies to specific messages
- **Slash Commands**: `/status`, `/stop`, `/clear`, `/compact`

## Components

### Gateway Server

Express server (~270 lines) handling Telegram integration:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/webhook/:botId` | POST | Receives Telegram webhooks, injects to tmux |
| `/reply` | POST | Sends messages to Telegram |
| `/send-file` | POST | Sends file attachments to Telegram |
| `/register/:botId` | POST | Registers webhook and commands with Telegram |
| `/health` | GET | Health check |

### Pichu (Commander Skill)

The persistent orchestrator that:
- Receives messages from Telegram via tmux injection
- Parses message metadata (chat_id, bot_id, msg_id, reply_to)
- Sends acknowledgments and responses via the reply script
- Delegates implementation tasks to fresh subagents
- Maintains and updates memory files

### Memory System

File-based persistence in `state/memory/`:

| File | Purpose |
|------|---------|
| `project-status.md` | Current phase, active work, blockers |
| `preferences.md` | User communication and work preferences |
| `coding-standards.md` | TypeScript, testing, git conventions |
| `knowledge/patterns.md` | Reusable patterns |
| `knowledge/gotchas.md` | Things to avoid |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_URL` | `redis://localhost:6379` | Redis connection |
| `PORT` | `3100` | Gateway port |
| `TMUX_SESSION` | `cc-pichu:0.0` | tmux target |
| `TMUX_DELAY_MS` | `500` | Delay before Enter key |
| `TELEGRAM_BOT_TOKEN_PICHU` | - | Bot token for Pichu |
| `WEBHOOK_URL` | - | Public URL for Telegram webhook |

## Documentation

- [Quick Start Guide](docs/quickstart.md) - Get running in ~5 minutes
- [User Guide](docs/userguide.md) - Comprehensive documentation

## Requirements

- Node.js 18+
- Redis
- tmux
- [Claude Code CLI](https://claude.ai/code)
- Telegram Bot Token

## License

MIT
