# Quick Start Guide

Get Pichu running in about 5 minutes.

## Prerequisites

Before starting, ensure you have the following installed:

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| Node.js | 18+ | `node --version` |
| Redis | Any | `redis-cli ping` |
| tmux | Any | `tmux -V` |
| jq | Any | `jq --version` |
| Claude Code CLI | Latest | `claude --version` |

## Step 1: Clone and Install

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/pichu-telegram-agent.git
cd pichu-telegram-agent

# Install dependencies
npm install
```

## Step 2: Create Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the prompts
3. Save the bot token (looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

## Step 3: Configure Environment

Create a `.env` file in the project root:

```bash
# Required
TELEGRAM_BOT_TOKEN_PICHU=your_bot_token_here

# Optional (defaults shown)
REDIS_URL=redis://localhost:6379
PORT=3100
TMUX_SESSION=cc-pichu:0.0
WEBHOOK_URL=https://your-domain.com
```

**Note:** `WEBHOOK_URL` is only needed if running on a public server. For local testing, you can use a tunneling service like [ngrok](https://ngrok.com/).

## Step 4: Start Redis

```bash
# If Redis is not running
redis-server &

# Verify Redis is running
redis-cli ping
# Should return: PONG
```

## Step 5: Start the Gateway

```bash
npm run gateway
```

You should see:
```
Gateway listening on 3100
```

## Step 6: Register the Bot (Public Server Only)

If running on a public server with `WEBHOOK_URL` set:

```bash
curl -X POST http://localhost:3100/register/pichu
```

This registers the webhook and slash commands with Telegram.

For local testing with ngrok:
```bash
# In another terminal
ngrok http 3100

# Use the ngrok URL
WEBHOOK_URL=https://abc123.ngrok.io npm run gateway

# Register
curl -X POST http://localhost:3100/register/pichu
```

## Step 7: Start Pichu Session

Open a new terminal and run:

```bash
./scripts/start-pichu.sh
tmux attach -t cc-pichu
```

In the tmux session:
1. Run `claude` to start Claude Code
2. Type `/commander` to load the Pichu skill

## Step 8: Test the Bot

1. Open Telegram and find your bot
2. Send a message like "Hello, Pichu!"
3. You should see:
   - The message appear in the tmux session
   - A response from Pichu in Telegram

## Troubleshooting

### Gateway won't start

Check if port 3100 is already in use:
```bash
lsof -i :3100
```

### Redis connection failed

Ensure Redis is running:
```bash
redis-cli ping
```

### Messages not reaching Pichu

1. Check the gateway logs for errors
2. Verify webhook registration: `curl https://api.telegram.org/botYOUR_TOKEN/getWebhookInfo`
3. Ensure tmux session is running: `tmux ls`

### Pichu not responding

1. Check the tmux session is attached: `tmux attach -t cc-pichu`
2. Verify the commander skill is loaded
3. Check for errors in the Claude Code session

## Next Steps

- Read the [User Guide](userguide.md) for detailed documentation
- Customize memory files in `state/memory/`
- Configure preferences for your workflow
