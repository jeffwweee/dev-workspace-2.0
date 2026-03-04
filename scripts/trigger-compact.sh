#!/bin/bash
# trigger-compact.sh - Trigger delayed compact with warning
# Usage: ./scripts/trigger-compact.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
TMUX_SESSION="cc-pichu:0.0"
COMPACT_DELAY=30  # seconds
RECOVERY_DELAY=10  # seconds after compact
SEND_KEY_DELAY=5  # seconds after send key

# Get active chat ID from session state
CHAT_ID_FILE="$PROJECT_ROOT/state/sessions/.active-chat.json"

if [ -f "$CHAT_ID_FILE" ]; then
  CHAT_ID=$(jq -r '.chat_id' "$CHAT_ID_FILE")
else
  CHAT_ID="195061634"  # Default fallback
fi

BOT_ID="pichu"

# Send warning message to Telegram
"$SCRIPT_DIR/reply.sh" "$BOT_ID" "$CHAT_ID" "📦 Compacting in ${COMPACT_DELAY}s. I'll be back shortly..."

# Schedule delayed tmux injection (runs in background)
(
  sleep $COMPACT_DELAY

  # Inject /compact command
  tmux send-keys -t "$TMUX_SESSION" "/compact"

  sleep $SEND_KEY_DELAY 
  tmux send-keys -t "$TMUX_SESSION" Enter

  # Wait for compact to complete
  sleep $RECOVERY_DELAY

  # Inject /back message to trigger recovery response
  # Format: [TG:chat_id:bot_id:msg_id:reply_to]
  tmux send-keys -t "$TMUX_SESSION" "[TG:${CHAT_ID}:${BOT_ID}:0:0] /back"
  tmux send-keys -t "$TMUX_SESSION" Enter
) &

echo "Compact scheduled in ${COMPACT_DELAY}s"
