# Compact Trigger Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to implement this plan task-by-task.

**Goal:** Add doc-size-based compact recommendation to brainstorming and writing-plans skills.

**Architecture:** Simple bash script checks doc file size, skills call it after saving docs and recommend /compact if large.

**Tech Stack:** Bash

**Context:**
- Design doc: `docs/plans/2026-03-04-compact-trigger-fix-design.md`
- Brainstorming skill: `.claude/skills/brainstorming/SKILL.md`
- Writing-plans skill: `.claude/skills/writing-plans/SKILL.md`
- Telegram reply: `scripts/reply.sh`

---

## Task 1: Create Doc Size Checker Script

**Files:**
- Create: `scripts/check-doc-size.sh`

**Changes:**
- [ ] Create bash script that checks file size
- [ ] Return "recommend" if > 5KB, "ok" otherwise
- [ ] Make executable

**Code:**

```bash
#!/bin/bash
# check-doc-size.sh - Check if doc is large, recommend compact
# Usage: ./scripts/check-doc-size.sh <file_path>
# Returns: "recommend" if > 5KB, "ok" otherwise

DOC_FILE="$1"
SIZE_THRESHOLD_KB=5  # 5KB ≈ 1000+ tokens

if [ ! -f "$DOC_FILE" ]; then
  echo "error: File not found: $DOC_FILE"
  exit 1
fi

# Get file size in KB
SIZE_KB=$(du -k "$DOC_FILE" | cut -f1)

if [ "$SIZE_KB" -gt "$SIZE_THRESHOLD_KB" ]; then
  echo "recommend"
else
  echo "ok"
fi
```

**Commands:**
```bash
# Create the script
cat > scripts/check-doc-size.sh << 'EOF'
#!/bin/bash
# check-doc-size.sh - Check if doc is large, recommend compact
# Usage: ./scripts/check-doc-size.sh <file_path>
# Returns: "recommend" if > 5KB, "ok" otherwise

DOC_FILE="$1"
SIZE_THRESHOLD_KB=5  # 5KB ≈ 1000+ tokens

if [ ! -f "$DOC_FILE" ]; then
  echo "error: File not found: $DOC_FILE"
  exit 1
fi

# Get file size in KB
SIZE_KB=$(du -k "$DOC_FILE" | cut -f1)

if [ "$SIZE_KB" -gt "$SIZE_THRESHOLD_KB" ]; then
  echo "recommend"
else
  echo "ok"
fi
EOF

chmod +x scripts/check-doc-size.sh
```

**Verification:**
```bash
# Test with small file
echo "small" > /tmp/small.md
./scripts/check-doc-size.sh /tmp/small.md
# Expected: "ok"

# Test with larger file (simulate)
dd if=/dev/zero of=/tmp/large.md bs=1024 count=6 2>/dev/null
./scripts/check-doc-size.sh /tmp/large.md
# Expected: "recommend"

# Cleanup
rm /tmp/small.md /tmp/large.md
```

---

## Task 2: Update Brainstorming Skill

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md`

**Changes:**
- [ ] Add "After Design Saved" section
- [ ] Include check-doc-size.sh call
- [ ] Add compact recommendation message

**Code:**

Add this section after "After Design Approved" section (after line 44):

```markdown
## After Design Saved

After saving the design doc, check if it's large and recommend compact:

```bash
# Check if design doc is large
DOC_FILE="docs/plans/YYYY-MM-DD-<topic>-design.md"  # Use actual filename
if [ "$(./scripts/check-doc-size.sh "$DOC_FILE")" = "recommend" ]; then
  SIZE_KB=$(du -k "$DOC_FILE" | cut -f1)
  reply "Design saved. Doc is large (${SIZE_KB}KB). Consider /compact to free context before planning."
else
  reply "Design saved. Ready for planning phase."
fi
```

Replace `YYYY-MM-DD-<topic>-design.md` with the actual design file path.
```

**Verification:**
```bash
grep -A 15 "After Design Saved" .claude/skills/brainstorming/SKILL.md
# Should show the new section with check-doc-size.sh call
```

---

## Task 3: Update Writing-Plans Skill

**Files:**
- Modify: `.claude/skills/writing-plans/SKILL.md`

**Changes:**
- [ ] Add "After Plan Saved" section
- [ ] Include check-doc-size.sh call
- [ ] Add compact recommendation message

**Code:**

Add this section after "Execution Handoff" section (after line 28):

```markdown
## After Plan Saved

After saving the implementation plan, check if it's large and recommend compact:

```bash
# Check if plan doc is large
PLAN_FILE="docs/plans/YYYY-MM-DD-<feature>-plan.md"  # Use actual filename
if [ "$(./scripts/check-doc-size.sh "$PLAN_FILE")" = "recommend" ]; then
  SIZE_KB=$(du -k "$PLAN_FILE" | cut -f1)
  reply "Plan saved. Doc is large (${SIZE_KB}KB). Consider /compact to free context before execution."
else
  reply "Plan saved. Ready for execution."
fi
```

Replace `YYYY-MM-DD-<feature>-plan.md` with the actual plan file path.
```

**Verification:**
```bash
grep -A 15 "After Plan Saved" .claude/skills/writing-plans/SKILL.md
# Should show the new section with check-doc-size.sh call
```

---

## Task 4: Integration Test

**Files:**
- None (testing only)

**Changes:**
- [ ] Test with existing large doc
- [ ] Verify recommendation appears
- [ ] Test with small doc
- [ ] Verify no recommendation

**Test Script:**

```bash
#!/bin/bash
# Integration test for doc-size compact recommendation

echo "=== Doc Size Check Integration Test ==="

# Test 1: Check script exists and is executable
echo "Test 1: Script exists and executable..."
if [ -x scripts/check-doc-size.sh ]; then
  echo "PASS: check-doc-size.sh is executable"
else
  echo "FAIL: check-doc-size.sh not found or not executable"
  exit 1
fi

# Test 2: Test with small file
echo "Test 2: Small file should return 'ok'..."
echo "small content" > /tmp/test-small.md
RESULT=$(./scripts/check-doc-size.sh /tmp/test-small.md)
if [ "$RESULT" = "ok" ]; then
  echo "PASS: Small file returns 'ok'"
else
  echo "FAIL: Expected 'ok', got '$RESULT'"
  exit 1
fi

# Test 3: Test with large file (> 5KB)
echo "Test 3: Large file should return 'recommend'..."
dd if=/dev/zero of=/tmp/test-large.md bs=1024 count=6 2>/dev/null
RESULT=$(./scripts/check-doc-size.sh /tmp/test-large.md)
if [ "$RESULT" = "recommend" ]; then
  echo "PASS: Large file returns 'recommend'"
else
  echo "FAIL: Expected 'recommend', got '$RESULT'"
  exit 1
fi

# Test 4: Check skills are updated
echo "Test 4: Skills have doc size check..."
if grep -q "check-doc-size.sh" .claude/skills/brainstorming/SKILL.md; then
  echo "PASS: brainstorming skill updated"
else
  echo "FAIL: brainstorming skill not updated"
  exit 1
fi

if grep -q "check-doc-size.sh" .claude/skills/writing-plans/SKILL.md; then
  echo "PASS: writing-plans skill updated"
else
  echo "FAIL: writing-plans skill not updated"
  exit 1
fi

# Cleanup
rm /tmp/test-small.md /tmp/test-large.md

echo "=== All tests passed ==="
```

**Verification:**
```bash
chmod +x scripts/test-doc-size.sh
./scripts/test-doc-size.sh
```

---

## Task 5: Commit Changes

**Files:**
- None (git operations)

**Changes:**
- [ ] Stage all new and modified files
- [ ] Commit with descriptive message

**Commands:**
```bash
git add scripts/check-doc-size.sh
git add .claude/skills/brainstorming/SKILL.md
git add .claude/skills/writing-plans/SKILL.md

git commit -m "feat(compact): add doc-size-based compact recommendation

- Add scripts/check-doc-size.sh to check if docs are large
- Update brainstorming skill to recommend /compact for large designs
- Update writing-plans skill to recommend /compact for large plans
- Threshold: 5KB (≈ 1000+ tokens)

User controls when to compact. No auto-compact, no state tracking.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Success Criteria

After all tasks complete:

- [ ] `scripts/check-doc-size.sh` exists and is executable
- [ ] Script returns "recommend" for files > 5KB
- [ ] Script returns "ok" for files <= 5KB
- [ ] Brainstorming skill includes doc size check
- [ ] Writing-plans skill includes doc size check
- [ ] Integration tests pass
- [ ] Git commit created
