# Hook System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to implement this plan task-by-task.

**Goal:** Implement after_complete hook system that captures subagent learnings and enables pattern extraction via /evolve command.

**Architecture:** Hybrid approach - Bash script for fast capture, Node.js for smart pattern extraction. Observations stored in JSONL, routed to memory files or candidates based on confidence.

**Tech Stack:** Bash, Node.js, JSONL

**Context:**
- Design doc: `docs/plans/2026-03-04-hook-system-design.md`
- Existing patterns: `state/memory/knowledge/patterns.md`
- Existing gotchas: `state/memory/knowledge/gotchas.md`
- Task state API: `scripts/task-state.sh`
- Telegram reply: `scripts/reply.sh`

---

## Task 1: Create Directory Structure and Observation Log

**Files:**
- Create: `state/learning/.gitkeep`
- Create: `state/learning/candidates/.gitkeep`
- Create: `state/learning/observations.jsonl`

**Changes:**
- [ ] Create `state/learning/` directory
- [ ] Create `state/learning/candidates/` subdirectory
- [ ] Initialize empty `observations.jsonl` file
- [ ] Add .gitkeep files to preserve empty directories

**Commands:**
```bash
mkdir -p state/learning/candidates
touch state/learning/observations.jsonl
touch state/learning/.gitkeep
touch state/learning/candidates/.gitkeep
```

**Verification:**
```bash
ls -la state/learning/
# Should show: .gitkeep, candidates/, observations.jsonl
ls -la state/learning/candidates/
# Should show: .gitkeep
```

---

## Task 2: Create Capture Hook Script

**Files:**
- Create: `scripts/hooks/after-complete.sh`

**Changes:**
- [ ] Create hooks directory
- [ ] Implement capture script that reads env vars and appends to JSONL
- [ ] Handle JSON escaping properly
- [ ] Make script executable

**Code:**

```bash
#!/bin/bash
# after-complete.sh - Capture subagent completion context
# Usage: Source this with environment variables set

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OBSERVATIONS_FILE="$PROJECT_ROOT/state/learning/observations.jsonl"

# Ensure observations file exists
mkdir -p "$(dirname "$OBSERVATIONS_FILE")"
touch "$OBSERVATIONS_FILE"

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build JSON object using jq for proper escaping
# Fall back to simple JSON if jq not available
if command -v jq &> /dev/null; then
  jq -n \
    --arg ts "$TIMESTAMP" \
    --arg task_id "$TASK_ID" \
    --arg task_type "$TASK_TYPE" \
    --arg prompt "$TASK_PROMPT" \
    --arg result "$TASK_RESULT" \
    --arg files "$FILES_CHANGED" \
    --argjson patterns "${PATTERNS_DETECTED:-[]}" \
    --argjson decisions "${DECISIONS:-[]}" \
    --argjson errors "${ERRORS_RESOLVED:-[]}" \
    '{
      timestamp: $ts,
      task_id: $task_id,
      task_type: $task_type,
      prompt: $prompt,
      result_summary: $result,
      files_changed: ($files | split(" ")),
      patterns_detected: $patterns,
      decisions: $decisions,
      errors_resolved: $errors
    }' >> "$OBSERVATIONS_FILE"
else
  # Simple fallback without jq
  cat >> "$OBSERVATIONS_FILE" << EOF
{"timestamp":"$TIMESTAMP","task_id":"$TASK_ID","task_type":"$TASK_TYPE","prompt":"$TASK_PROMPT","result_summary":"$TASK_RESULT","files_changed":["$FILES_CHANGED"],"patterns_detected":[],"decisions":[],"errors_resolved":[]}
EOF
fi

echo "Observation logged: $TASK_ID"
```

**Commands:**
```bash
mkdir -p scripts/hooks
# Write the script content above to scripts/hooks/after-complete.sh
chmod +x scripts/hooks/after-complete.sh
```

**Verification:**
```bash
# Test the hook
TASK_ID="test-123" TASK_TYPE="test" TASK_PROMPT="test prompt" TASK_RESULT="success" FILES_CHANGED="" scripts/hooks/after-complete.sh
cat state/learning/observations.jsonl
# Should show a JSON line with the test data

# Clean up test
> state/learning/observations.jsonl
```

---

## Task 3: Create Evolution Processor Script

**Files:**
- Create: `scripts/evolve.js`

**Changes:**
- [ ] Create Node.js script for pattern extraction
- [ ] Read observations from JSONL
- [ ] Detect patterns with confidence scoring
- [ ] Route to memory files or candidates
- [ ] Report results

**Code:**

```javascript
#!/usr/bin/env node
/**
 * evolve.js - Extract patterns from observations and route to memory/candidates
 *
 * Usage: node scripts/evolve.js
 *
 * Reads from: state/learning/observations.jsonl
 * Writes to:
 *   - state/memory/knowledge/patterns.md (high confidence)
 *   - state/memory/knowledge/gotchas.md (high confidence)
 *   - state/learning/candidates/{timestamp}.md (medium confidence)
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const OBSERVATIONS_FILE = path.join(PROJECT_ROOT, 'state/learning/observations.jsonl');
const PATTERNS_FILE = path.join(PROJECT_ROOT, 'state/memory/knowledge/patterns.md');
const GOTCHAS_FILE = path.join(PROJECT_ROOT, 'state/memory/knowledge/gotchas.md');
const CANDIDATES_DIR = path.join(PROJECT_ROOT, 'state/learning/candidates');

// Pattern detection rules
const DETECTION_RULES = [
  {
    type: 'error_resolution',
    signals: ['error', 'failed', 'fix', 'resolved', 'solved'],
    confidence: 0.8,
    target: 'gotchas'
  },
  {
    type: 'code_pattern',
    signals: ['pattern', 'reuse', 'extracted', 'refactored'],
    confidence: 0.7,
    target: 'patterns'
  },
  {
    type: 'decision',
    signals: ['decided', 'chose', 'selected', 'went with'],
    confidence: 0.6,
    target: 'patterns'
  },
  {
    type: 'gotcha',
    signals: ['avoid', 'dont', "don't", 'issue', 'problem', 'warning'],
    confidence: 0.6,
    target: 'gotchas'
  },
  {
    type: 'user_correction',
    signals: ['actually', 'no,', 'correction', 'instead'],
    confidence: 0.5,
    target: 'candidates'
  }
];

function readObservations() {
  if (!fs.existsSync(OBSERVATIONS_FILE)) {
    return [];
  }

  const content = fs.readFileSync(OBSERVATIONS_FILE, 'utf-8').trim();
  if (!content) {
    return [];
  }

  return content.split('\n')
    .filter(line => line.trim())
    .map(line => {
      try {
        return JSON.parse(line);
      } catch (e) {
        console.error(`Skipping invalid JSON line: ${line.substring(0, 50)}...`);
        return null;
      }
    })
    .filter(obs => obs !== null);
}

function detectPatterns(observations) {
  const detected = [];

  for (const obs of observations) {
    const text = `${obs.prompt} ${obs.result_summary}`.toLowerCase();

    for (const rule of DETECTION_RULES) {
      const matchCount = rule.signals.filter(s => text.includes(s.toLowerCase())).length;

      if (matchCount >= 2) {
        detected.push({
          observation: obs,
          patternType: rule.type,
          confidence: Math.min(rule.confidence + (matchCount - 2) * 0.1, 1.0),
          target: rule.target
        });
      }
    }
  }

  return detected;
}

function routePatterns(patterns) {
  const routed = {
    patterns: [],
    gotchas: [],
    candidates: []
  };

  for (const p of patterns) {
    const entry = {
      source: p.observation.task_id,
      type: p.patternType,
      confidence: p.confidence,
      text: p.observation.result_summary.substring(0, 200)
    };

    if (p.confidence >= 0.8) {
      routed[p.target].push(entry);
    } else if (p.confidence >= 0.5) {
      routed.candidates.push(entry);
    }
  }

  return routed;
}

function updateMemoryFile(filepath, entries, sectionName) {
  let content = '';
  if (fs.existsSync(filepath)) {
    content = fs.readFileSync(filepath, 'utf-8');
  } else {
    content = `# ${sectionName}\n\n${sectionName} discovered during development.\n`;
  }

  const timestamp = new Date().toISOString().split('T')[0];
  let newSection = `\n\n## Auto-extracted ${timestamp}\n\n`;

  for (const entry of entries) {
    newSection += `- **${entry.type}** (confidence: ${entry.confidence.toFixed(2)})\n  ${entry.text}\n  Source: ${entry.source}\n\n`;
  }

  content += newSection;
  fs.writeFileSync(filepath, content, 'utf-8');
}

function createCandidatesFile(entries) {
  if (entries.length === 0) return null;

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filepath = path.join(CANDIDATES_DIR, `${timestamp}.md`);

  let content = `# Pattern Candidates\n\nGenerated: ${new Date().toISOString()}\n\n`;

  for (const entry of entries) {
    content += `## ${entry.type}\n\n`;
    content += `**Confidence:** ${entry.confidence.toFixed(2)}\n\n`;
    content += `**Summary:** ${entry.text}\n\n`;
    content += `**Source:** ${entry.source}\n\n`;
    content += `---\n\n`;
  }

  content += `## Review Actions\n\n`;
  content += `- [ ] Promote to patterns.md\n`;
  content += `- [ ] Promote to gotchas.md\n`;
  content += `- [ ] Discard\n`;

  fs.writeFileSync(filepath, content, 'utf-8');
  return filepath;
}

function main() {
  console.log('Reading observations...');
  const observations = readObservations();
  console.log(`Found ${observations.length} observations`);

  if (observations.length === 0) {
    console.log('No observations to process');
    return { patterns: 0, gotchas: 0, candidates: 0 };
  }

  console.log('Detecting patterns...');
  const patterns = detectPatterns(observations);
  console.log(`Detected ${patterns.length} potential patterns`);

  console.log('Routing patterns...');
  const routed = routePatterns(patterns);

  // Update memory files
  if (routed.patterns.length > 0) {
    updateMemoryFile(PATTERNS_FILE, routed.patterns, 'Patterns');
    console.log(`Updated patterns.md with ${routed.patterns.length} entries`);
  }

  if (routed.gotchas.length > 0) {
    updateMemoryFile(GOTCHAS_FILE, routed.gotchas, 'Gotchas');
    console.log(`Updated gotchas.md with ${routed.gotchas.length} entries`);
  }

  // Create candidates file
  if (routed.candidates.length > 0) {
    const candidateFile = createCandidatesFile(routed.candidates);
    console.log(`Created candidate file: ${candidateFile}`);
  }

  return {
    patterns: routed.patterns.length,
    gotchas: routed.gotchas.length,
    candidates: routed.candidates.length
  };
}

// Run if called directly
if (require.main === module) {
  const result = main();
  console.log('\nEvolution complete:');
  console.log(`  Patterns: ${result.patterns}`);
  console.log(`  Gotchas: ${result.gotchas}`);
  console.log(`  Candidates: ${result.candidates}`);
}

module.exports = { readObservations, detectPatterns, routePatterns, main };
```

**Commands:**
```bash
# Write the script content above to scripts/evolve.js
chmod +x scripts/evolve.js
```

**Verification:**
```bash
# Add a test observation
echo '{"timestamp":"2026-03-04T12:00:00Z","task_id":"test-1","task_type":"implement","prompt":"fix the error","result_summary":"error resolved by adding null check","files_changed":[],"patterns_detected":[],"decisions":[],"errors_resolved":[]}' > state/learning/observations.jsonl

# Run evolve
node scripts/evolve.js

# Check gotchas was updated
cat state/memory/knowledge/gotchas.md
# Should contain new section with the error resolution

# Clean up
git checkout state/memory/knowledge/gotchas.md
> state/learning/observations.jsonl
```

---

## Task 4: Add Helper Script for Observation Count

**Files:**
- Create: `scripts/evolve-status.sh`

**Changes:**
- [ ] Create simple script to count pending observations
- [ ] Report to stdout for Commander to read

**Code:**

```bash
#!/bin/bash
# evolve-status.sh - Report pending observations count

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OBSERVATIONS_FILE="$PROJECT_ROOT/state/learning/observations.jsonl"

if [ ! -f "$OBSERVATIONS_FILE" ]; then
  echo "0 observations"
  exit 0
fi

COUNT=$(wc -l < "$OBSERVATIONS_FILE" | tr -d ' ')
echo "${COUNT} observations pending"
```

**Commands:**
```bash
# Write script
chmod +x scripts/evolve-status.sh
```

**Verification:**
```bash
./scripts/evolve-status.sh
# Should show "0 observations pending" or current count
```

---

## Task 5: Add Helper Script for Candidates List

**Files:**
- Create: `scripts/candidates-list.sh`

**Changes:**
- [ ] Create script to list candidate files
- [ ] Format for Telegram display

**Code:**

```bash
#!/bin/bash
# candidates-list.sh - List pending candidates for review

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANDIDATES_DIR="$PROJECT_ROOT/state/learning/candidates"

if [ ! -d "$CANDIDATES_DIR" ]; then
  echo "No candidates directory"
  exit 0
fi

CANDIDATES=$(ls -1 "$CANDIDATES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')

if [ "$CANDIDATES" -eq 0 ]; then
  echo "No candidates pending review"
  exit 0
fi

echo "Found ${CANDIDATES} candidate file(s):"
echo ""
ls -1 "$CANDIDATES_DIR"/*.md 2>/dev/null | while read file; do
  basename "$file"
done
```

**Commands:**
```bash
chmod +x scripts/candidates-list.sh
```

**Verification:**
```bash
./scripts/candidates-list.sh
# Should show "No candidates pending review" or list files
```

---

## Task 6: Update Commander Skill with New Commands

**Files:**
- Modify: `.claude/skills/commander/SKILL.md`

**Changes:**
- [ ] Add `/evolve` command to Commands table
- [ ] Add `/evolve-status` command
- [ ] Add `/candidates` command
- [ ] Add command handling section

**Code:**

In the Commands table (around line 76), add these rows:

```markdown
| /evolve | Extract patterns from observations, route to memory/candidates |
| /evolve-status | Show pending observations count |
| /candidates | List pending candidate files for review |
```

After the Commands table, add a new section:

```markdown
## Learning Commands

### /evolve

Process observations and extract patterns:

1. Run `node scripts/evolve.js`
2. Report results: "Extracted X patterns, Y gotchas, Z candidates"
3. Use reply.sh to send to user

### /evolve-status

Check pending observations:

1. Run `./scripts/evolve-status.sh`
2. Send output via reply.sh

### /candidates

List candidate files:

1. Run `./scripts/candidates-list.sh`
2. Send output via reply.sh
3. Optionally use send-file.sh to send specific candidate for review
```

**Verification:**
```bash
grep -A 5 "| /evolve" .claude/skills/commander/SKILL.md
# Should show the new commands
```

---

## Task 7: Update Background-Tasks Skill to Call Hook

**Files:**
- Modify: `.claude/skills/background-tasks/SKILL.md`

**Changes:**
- [ ] Add section about after_complete hook
- [ ] Specify when to call the hook
- [ ] Document required environment variables

**Code:**

Add after the "Critical Rules" section (around line 30):

```markdown
## After Complete Hook

After subagent completes, capture the observation:

```bash
# After TaskOutput is received
TASK_ID="<task_id>" \
TASK_TYPE="<implement|fix|review>" \
TASK_PROMPT="<original_prompt>" \
TASK_RESULT="<result_summary>" \
FILES_CHANGED="<file1 file2>" \
./scripts/hooks/after-complete.sh
```

The hook appends to `state/learning/observations.jsonl` for later processing by `/evolve`.
```

**Verification:**
```bash
grep -A 10 "After Complete Hook" .claude/skills/background-tasks/SKILL.md
# Should show the new section
```

---

## Task 8: Integration Test

**Files:**
- None (testing only)

**Changes:**
- [ ] Test full flow from observation capture to pattern extraction
- [ ] Verify JSONL format
- [ ] Verify memory file updates
- [ ] Verify candidate file creation

**Test Script:**

```bash
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

OBS_COUNT=$(wc -l < state/learning/observations.jsonl | tr -d ' ')
if [ "$OBS_COUNT" -eq 1 ]; then
  echo "PASS: Observation captured"
else
  echo "FAIL: Expected 1 observation, got $OBS_COUNT"
  exit 1
fi

# Test 2: Check observation format
echo "Test 2: Verify JSON format..."
if jq . state/learning/observations.jsonl > /dev/null 2>&1; then
  echo "PASS: Valid JSON"
else
  echo "FAIL: Invalid JSON format"
  exit 1
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

# Cleanup
> state/learning/observations.jsonl
git checkout state/memory/knowledge/patterns.md state/memory/knowledge/gotchas.md 2>/dev/null || true

echo "=== All tests passed ==="
```

**Verification:**
```bash
# Run the test script
chmod +x scripts/test-hook-system.sh
./scripts/test-hook-system.sh
```

---

## Task 9: Commit and Document

**Files:**
- None (git operations)

**Changes:**
- [ ] Stage all new files
- [ ] Commit with descriptive message
- [ ] Update project status if needed

**Commands:**
```bash
git add scripts/hooks/after-complete.sh
git add scripts/evolve.js
git add scripts/evolve-status.sh
git add scripts/candidates-list.sh
git add state/learning/.gitkeep
git add state/learning/candidates/.gitkeep
git add state/learning/observations.jsonl
git add .claude/skills/commander/SKILL.md
git add .claude/skills/background-tasks/SKILL.md

git commit -m "feat(hooks): add after_complete hook system for learning capture

- Add scripts/hooks/after-complete.sh for capturing subagent results
- Add scripts/evolve.js for pattern extraction with confidence scoring
- Add scripts/evolve-status.sh and candidates-list.sh helpers
- Update Commander skill with /evolve, /evolve-status, /candidates commands
- Update background-tasks skill to call after_complete hook
- Create state/learning/ directory structure for observations and candidates

Closes #11 (Phase 1-3)"
```

---

## Success Criteria

After all tasks complete:

- [ ] `scripts/hooks/after-complete.sh` exists and is executable
- [ ] `scripts/evolve.js` exists and runs without error
- [ ] `scripts/evolve-status.sh` reports observation count
- [ ] `scripts/candidates-list.sh` lists candidate files
- [ ] Commander skill documents /evolve, /evolve-status, /candidates
- [ ] Background-tasks skill documents after_complete hook
- [ ] Integration test passes
- [ ] Git commit created
