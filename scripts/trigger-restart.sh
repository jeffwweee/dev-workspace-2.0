#!/bin/bash
# trigger-restart.sh - Trigger delayed restart with /clear + /commander
# Usage: ./scripts/trigger-restart.sh
#
# Flow:
# 1. Send warning to Telegram
# 2. Delay
# 3. /clear -> delay -> Enter
# 4. Delay
# 5. /commander -> delay -> Enter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
TMUX_SESSION="cc-pichu:0.0"
CLEAR_DELAY=3      # seconds before /clear
COMMANDER_DELAY=5  # seconds after /clear before /commander
SEND_KEY_DELAY=2   # seconds between command and Enter
COMPLETE_DELAY=12  # seconds before completion message

# Get active chat ID from session state
CHAT_ID_FILE="$PROJECT_ROOT/state/sessions/.active-chat.json"

if [ -f "$CHAT_ID_FILE" ]; then
  CHAT_ID=$(jq -r '.chat_id' "$CHAT_ID_FILE")
else
  CHAT_ID="195061634"  # Default fallback
fi

BOT_ID="pichu"

# Send warning message to Telegram
"$SCRIPT_DIR/reply.sh" "$BOT_ID" "$CHAT_ID" "Restarting session in ${CLEAR_DELAY}s..."

# Schedule delayed tmux injection (runs in background)
(
  sleep $CLEAR_DELAY

  # Step 1: Inject /clear command
  tmux send-keys -t "$TMUX_SESSION" "/clear"
  sleep $SEND_KEY_DELAY
  tmux send-keys -t "$TMUX_SESSION" Enter

  # Wait for clear to process
  sleep $COMMANDER_DELAY

  # Step 2: Inject /commander command
  tmux send-keys -t "$TMUX_SESSION" "/commander"
  sleep $SEND_KEY_DELAY
  tmux send-keys -t "$TMUX_SESSION" Enter

  # Wait for commander to process, then send completion message
  sleep $COMPLETE_DELAY

  # Step 3: Send completion message
  "$SCRIPT_DIR/reply.sh" "$BOT_ID" "$CHAT_ID" "✅ Restart completed. Starting a new session."

) &

echo "Restart scheduled in ${CLEAR_DELAY}s"
