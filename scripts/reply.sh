#!/bin/bash
# reply.sh - Send reply to Telegram via gateway
# Usage: ./scripts/reply.sh <bot_id> <chat_id> "<message>" "[reply_to_message_id]"

BOT_ID="${1:-pichu}"
CHAT_ID="$2"
MESSAGE="$3"
REPLY_TO_MESSAGE_ID="$4"

if [ -z "$CHAT_ID" ] || [ -z "$MESSAGE" ]; then
  echo "Usage: $0 <bot_id> <chat_id> \"<message>\" \"[reply_to_message_id]\""
  exit 1
fi

# Build JSON payload with jq
# Only include reply_to_message_id if provided
if [ -n "$REPLY_TO_MESSAGE_ID" ]; then
  PAYLOAD=$(jq -n \
    --arg bot_id "$BOT_ID" \
    --argjson chat_id "$CHAT_ID" \
    --arg text "$MESSAGE" \
    --argjson reply_to_message_id "$REPLY_TO_MESSAGE_ID" \
    '{bot_id: $bot_id, chat_id: $chat_id, text: $text, reply_to_message_id: $reply_to_message_id}')
else
  PAYLOAD=$(jq -n \
    --arg bot_id "$BOT_ID" \
    --argjson chat_id "$CHAT_ID" \
    --arg text "$MESSAGE" \
    '{bot_id: $bot_id, chat_id: $chat_id, text: $text}')
fi

curl -s -X POST http://localhost:3100/reply \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
