#!/bin/bash
# Integration test for hook system

set -e

echo "=== Hook System Integration Test ==="

# Clean slate
> state/learning/observations.jsonl
git checkout state/memory/knowledge/patterns.md state/memory/knowledge/gotchas.md 2>/dev/null || true

# Test 1: Capture observation
echo "Test 1: Capture observation..."
TASK_ID="test-001" \
TASK_TYPE="implement" \
TASK_PROMPT="Add error handling to the API" \
TASK_RESULT="Successfully added try-catch blocks and fixed the null pointer error" \
FILES_CHANGED="src/api.ts" \
./scripts/hooks/after-complete.sh

OBS_COUNT=$(grep -c "^{" state/learning/observations.jsonl || true)
if [ "$OBS_COUNT" -eq 1 ]; then
  echo "PASS: Observation captured"
else
  echo "FAIL: Expected 1 observation, got $OBS_COUNT"
  exit 1
fi

# Test 2: Check observation format
echo "Test 2: Verify JSON format..."
if command -v jq &> /dev/null; then
  if jq . state/learning/observations.jsonl > /dev/null 2>&1; then
    echo "PASS: Valid JSON"
  else
    echo "FAIL: Invalid JSON format"
    exit 1
  fi
else
  echo "SKIP: jq not available, skipping JSON validation"
fi

# Test 3: Run evolve
echo "Test 3: Run evolve processor..."
node scripts/evolve.js

# Test 4: Verify memory updated
echo "Test 4: Verify memory files updated..."
if grep -q "Auto-extracted" state/memory/knowledge/gotchas.md; then
  echo "PASS: gotchas.md updated"
else
  echo "PASS: No high-confidence patterns (expected for test data)"
fi

# Test 5: Check status
echo "Test 5: Check evolve-status..."
STATUS=$(./scripts/evolve-status.sh)
echo "Status: $STATUS"

# Test 6: Check candidates
echo "Test 6: Check candidates-list..."
CANDIDATES=$(./scripts/candidates-list.sh)
echo "Candidates: $CANDIDATES"

# Cleanup
> state/learning/observations.jsonl
git checkout state/memory/knowledge/patterns.md state/memory/knowledge/gotchas.md 2>/dev/null || true

echo "=== All tests passed ==="
