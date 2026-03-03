# Dev Workspace v2 - Multi-Agent Telegram System

## Project Overview

A minimal multi-agent Telegram system with:
- 1 persistent session (Pichu) for conversation, coordination, memory
- Fresh subagents via Task tool for implementation
- Direct HTTP for replies (no hooks)
- File-based memory for persistence

## Quick Start

```bash
# Start gateway
npm run gateway

# Start Pichu session (in tmux)
tmux new -s cc-pichu
# In tmux: claude
```

## Architecture

```
Telegram → Gateway (port 3100) → tmux injection → Pichu → Subagents
                ↑                                        |
                └──────────── /reply endpoint ──────────┘
```

## Key Files

- `gateway/src/index.ts` - Express server (~75 lines)
- `.claude/skills/commander/SKILL.md` - Main Pichu skill
- `state/memory/` - Memory files (project-status, preferences, etc.)
- `state/sessions/` - Per-chat session state

## Environment Variables

- `REDIS_URL` - Redis connection (default: redis://localhost:6379)
- `PORT` - Gateway port (default: 3100)
- `TMUX_SESSION` - tmux target (default: cc-pichu:0.0)
- `TELEGRAM_BOT_TOKEN_PICHU` - Bot token for Pichu

## Memory System

Memory files in `state/memory/`:
- `project-status.md` - Current phase, active work, blockers
- `preferences.md` - User communication and work preferences
- `coding-standards.md` - TypeScript, testing, git conventions
- `knowledge/patterns.md` - Reusable patterns
- `knowledge/gotchas.md` - Things to avoid
