# Dev Workspace 2.0

A personal development workspace that you can control from anywhere via Telegram. Powered by Claude Code with persistent memory and intelligent task orchestration.

## What is Dev Workspace?

Dev Workspace is your always-on development assistant that lives in a tmux session and responds to Telegram messages. It remembers your project context, preferences, and coding standards - so you can continue development conversations across sessions and devices.

**Use cases:**
- Continue coding discussions while away from your desk
- Review and analyze documents/images on the go
- Track project status and blockers
- Delegate implementation tasks to AI subagents
- Maintain persistent context across development sessions

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Dev Workspace 2.0                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────┐      ┌─────────────┐      ┌──────────────┐   │
│   │ Telegram │─────►│   Gateway   │─────►│     Pichu    │   │
│   │   (any   │◄─────│   :3100     │◄─────│  (persistent │   │
│   │  device) │      │  /webhook   │      │    session)  │   │
│   └──────────┘      │   /reply    │      └──────┬───────┘   │
│                     │ /send-file  │             │           │
│                     └─────────────┘             │ Task      │
│                                                 │ tool      │
│                     ┌─────────────┐             ▼           │
│                     │    State    │      ┌──────────────┐   │
│                     │   /memory   │      │  Subagents   │   │
│                     │   /files    │      │  (fresh,     │   │
│                     │  /sessions  │      │  isolated)   │   │
│                     └─────────────┘      └──────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Clone the repository
git clone https://github.com/jeffwweee/dev-workspace-2.0.git
cd dev-workspace-2.0

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your Telegram bot token

# Start Redis (if not running)
redis-server &

# Start the gateway
npm run gateway

# Start the orchestrator session
tmux new -s cc-pichu
claude
# Then type: /commander
```

For detailed setup instructions, see the [Quick Start Guide](docs/quickstart.md).

## Features

| Feature | Description |
|---------|-------------|
| **Persistent Memory** | Project status, preferences, and knowledge persist across sessions |
| **Remote Access** | Control your dev workspace from any device via Telegram |
| **File Analysis** | Send images and documents for AI-powered analysis |
| **File Delivery** | Receive generated files as Telegram attachments |
| **Threaded Replies** | Messages can be threaded for context |
| **Fresh Subagents** | Implementation tasks run in isolated processes |
| **Slash Commands** | `/status`, `/stop`, `/clear`, `/compact` |

## Components

### Gateway (`gateway/`)
Express server handling Telegram integration:
- `/webhook/:botId` - Receives messages, injects to tmux
- `/reply` - Sends messages to Telegram
- `/send-file` - Sends file attachments
- `/register/:botId` - Registers webhook and commands

### Orchestrator (`.claude/skills/commander/`)
The Pichu orchestrator skill that:
- Receives messages via tmux injection
- Parses message metadata and file attachments
- Delegates implementation to fresh subagents
- Maintains memory files

### State (`state/`)
File-based persistence:
- `memory/` - Project status, preferences, coding standards, knowledge
- `files/` - Downloaded files from Telegram
- `sessions/` - Per-chat session state

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_URL` | `redis://localhost:6379` | Redis connection |
| `PORT` | `3100` | Gateway port |
| `TMUX_SESSION` | `cc-pichu:0.0` | tmux target |
| `TELEGRAM_BOT_TOKEN_PICHU` | - | Your Telegram bot token |
| `WEBHOOK_URL` | - | Public URL for webhook (e.g., Cloudflare tunnel) |

## Documentation

- [Quick Start Guide](docs/quickstart.md) - Get running in ~5 minutes
- [User Guide](docs/userguide.md) - Full documentation

## Requirements

- Node.js 18+
- Redis
- tmux
- [Claude Code CLI](https://claude.ai/code)
- Telegram Bot Token

## License

MIT
