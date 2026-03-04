#!/bin/bash
# Test /end-session functionality

echo "=== End-Session Integration Test ==="

# Setup
CHAT_ID="test-123"
./scripts/session-state.sh start "$CHAT_ID"

# Test 1: Log events
echo "Test 1: Logging events..."
./scripts/log-session.sh "$CHAT_ID" task_started "task-001" "Test task"
./scripts/log-session.sh "$CHAT_ID" design_saved "docs/plans/test-design.md"
./scripts/log-session.sh "$CHAT_ID" plan_saved "docs/plans/test-plan.md"
./scripts/log-session.sh "$CHAT_ID" task_completed "task-001" "Test completed"

if [ -f "state/sessions/${CHAT_ID}-log.jsonl" ]; then
  LINES=$(wc -l < "state/sessions/${CHAT_ID}-log.jsonl" | tr -d ' ')
  echo "PASS: Log file has $LINES entries"
else
  echo "FAIL: Log file not created"
  exit 1
fi

# Test 2: End session summary
echo "Test 2: Generating summary..."
OUTPUT=$(./scripts/end-session.sh "$CHAT_ID")

if echo "$OUTPUT" | grep -q "Session Summary"; then
  echo "PASS: Summary generated"
else
  echo "FAIL: Summary not generated"
  exit 1
fi

# Test 3: Archive created
echo "Test 3: Checking archive..."
DATE=$(date +%Y-%m-%d)
if [ -f "state/sessions/archive/${CHAT_ID}-${DATE}.md" ]; then
  echo "PASS: Archive file created"
else
  echo "FAIL: Archive file not created"
  exit 1
fi

# Test 4: Observation count
echo "Test 4: Checking observation count..."
if echo "$OUTPUT" | grep -q "OBS_COUNT"; then
  echo "PASS: Observation count included"
else
  echo "FAIL: Observation count missing"
  exit 1
fi

# Cleanup
./scripts/session-state.sh end "$CHAT_ID"
rm -f "state/sessions/${CHAT_ID}-log.jsonl"
rm -f "state/sessions/archive/${CHAT_ID}-${DATE}.md"

echo "=== All tests passed ==="
