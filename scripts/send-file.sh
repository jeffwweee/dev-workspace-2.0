#!/bin/bash
# send-file.sh - Send a file attachment to Telegram via gateway
# Usage: ./scripts/send-file.sh <bot_id> <chat_id> <file_path> "[caption]" "[reply_to_message_id]"

BOT_ID="${1:-pichu}"
CHAT_ID="$2"
FILE_PATH="$3"
CAPTION="$4"
REPLY_TO_MESSAGE_ID="$5"

if [ -z "$CHAT_ID" ] || [ -z "$FILE_PATH" ]; then
  echo "Usage: $0 <bot_id> <chat_id> <file_path> \"[caption]\" \"[reply_to_message_id]\""
  exit 1
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "Error: File not found: $FILE_PATH"
  exit 1
fi

# Get absolute path for the file
FILE_PATH="$(cd "$(dirname "$FILE_PATH")" && pwd)/$(basename "$FILE_PATH")"

# Build JSON payload with jq
# Only include optional fields if they are provided
if [ -n "$CAPTION" ] && [ -n "$REPLY_TO_MESSAGE_ID" ]; then
  PAYLOAD=$(jq -n \
    --arg bot_id "$BOT_ID" \
    --argjson chat_id "$CHAT_ID" \
    --arg file_path "$FILE_PATH" \
    --arg caption "$CAPTION" \
    --argjson reply_to_message_id "$REPLY_TO_MESSAGE_ID" \
    '{bot_id: $bot_id, chat_id: $chat_id, file_path: $file_path, caption: $caption, reply_to_message_id: $reply_to_message_id}')
elif [ -n "$CAPTION" ]; then
  PAYLOAD=$(jq -n \
    --arg bot_id "$BOT_ID" \
    --argjson chat_id "$CHAT_ID" \
    --arg file_path "$FILE_PATH" \
    --arg caption "$CAPTION" \
    '{bot_id: $bot_id, chat_id: $chat_id, file_path: $file_path, caption: $caption}')
elif [ -n "$REPLY_TO_MESSAGE_ID" ]; then
  PAYLOAD=$(jq -n \
    --arg bot_id "$BOT_ID" \
    --argjson chat_id "$CHAT_ID" \
    --arg file_path "$FILE_PATH" \
    --argjson reply_to_message_id "$REPLY_TO_MESSAGE_ID" \
    '{bot_id: $bot_id, chat_id: $chat_id, file_path: $file_path, reply_to_message_id: $reply_to_message_id}')
else
  PAYLOAD=$(jq -n \
    --arg bot_id "$BOT_ID" \
    --argjson chat_id "$CHAT_ID" \
    --arg file_path "$FILE_PATH" \
    '{bot_id: $bot_id, chat_id: $chat_id, file_path: $file_path}')
fi

curl -s -X POST http://localhost:3100/send-file \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
