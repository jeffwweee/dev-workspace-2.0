#!/bin/bash

# Start Pichu tmux session
# Usage: ./scripts/start-pichu.sh

SESSION_NAME="cc-pichu"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Check if session exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
  echo "Session $SESSION_NAME already exists"
  echo "Attach with: tmux attach -t $SESSION_NAME"
  exit 0
fi

# Create new session
tmux new-session -d -s $SESSION_NAME -c "$PROJECT_DIR"

# Send initial commands
tmux send-keys -t $SESSION_NAME "cd $PROJECT_DIR" Enter
tmux send-keys -t $SESSION_NAME "# Pichu session ready. Start claude and load commander skill." Enter

echo "Created session: $SESSION_NAME"
echo "Attach with: tmux attach -t $SESSION_NAME"
echo ""
echo "In the session, run:"
echo "  claude"
echo "  /commander"
