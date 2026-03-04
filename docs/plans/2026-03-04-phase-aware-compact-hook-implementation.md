# Phase-Aware Smart Compact Hook - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `background-tasks` to implement this plan task-by-task.

**Goal:** Build a phase-aware compact system that detects workflow skill completion, saves state before compacts, and triggers delayed auto-compact with Telegram warnings.

**Architecture:**
- Phase detection via skill exit markers parsed by track-phase.js (PreToolUse hook)
- State preservation via save-state-before-compact.js
- Delayed compact via tmux injection with Telegram warning
- Project ID tracking per session for state file persistence

**Tech Stack:**
- Node.js for hook scripts
- Bash for tmux injection and Telegram messaging
- File-based JSON state tracking

**Context:**
- Project root: `/home/jeffwweee/jef/development-workspace/dev-workspace-v2`
- Gateway runs on port 3100 for Telegram messages
- tmux session: `cc-pichu:0.0`
- Identity file: `state/memory/identity.md` (~200 tokens, always loaded)
- Current hook: `.claude/settings.json` has PreToolUse hook for `suggest-compact.js`
- Reference `state/memory/coding-standards.md` for TypeScript/bash conventions

---

## Task 1: Create Project ID Tracker

**Files:**
- Create: `state/sessions/.project-id.json`

**Changes:**
- [ ] Create project ID tracking file
- [ ] Commit: "feat: add project ID tracker for phase-aware compacts"

**Code:**

```json
{
  "currentProject": null,
  "chatProjects": {}
}
```

**Format:**
- `currentProject`: `{date}-{topic-slug}` or null
- `chatProjects`: Map of `chat_id` → `project_id`

---

## Task 2: Create Phase Tracker Hook Script

**Files:**
- Create: `scripts/track-phase.js`

**Changes:**
- [ ] Create phase detection script
- [ ] Test: `node scripts/track-phase.js`
- [ ] Commit: "feat: add phase detection hook script"

**Code:**

```javascript
#!/usr/bin/env node

/**
 * Phase Tracker Hook
 *
 * Detects workflow skill completion and triggers pre-compact flow.
 * Called as PreToolUse hook on Edit|Write operations.
 *
 * Detection: Parses terminal output for skill exit markers:
 *   <!-- PHASE_COMPLETE: brainstorming -->
 *   <!-- PHASE_COMPLETE: writing-plans -->
 *   <!-- PHASE_COMPLETE: subagent-driven-development -->
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const PROJECT_ID_FILE = path.join(__dirname, '..', 'state/sessions/.project-id.json');
const PHASE_STATE_FILE = path.join(__dirname, '..', 'state/sessions/.phase-state.json');
const TMUX_SESSION = 'cc-pichu:0.0';
const COMPACT_DELAY = 30; // seconds

// Phase markers to detect
const PHASE_MARKERS = {
  'brainstorming': 'planning',
  'writing-plans': 'execution',
  'subagent-driven-development': 'complete'
};

function getProjectId() {
  try {
    const data = fs.readFileSync(PROJECT_ID_FILE, 'utf8');
    return JSON.parse(data);
  } catch {
    return { currentProject: null, chatProjects: {} };
  }
}

function saveProjectId(data) {
  fs.writeFileSync(PROJECT_ID_FILE, JSON.stringify(data, null, 2));
}

function getPhaseState() {
  try {
    const data = fs.readFileSync(PHASE_STATE_FILE, 'utf8');
    return JSON.parse(data);
  } catch {
    return { lastPhase: null, canTrigger: true };
  }
}

function savePhaseState(state) {
  fs.writeFileSync(PHASE_STATE_FILE, JSON.stringify(state, null, 2));
}

function detectPhaseFromTerminal() {
  try {
    // Get recent terminal output from tmux
    const output = execSync(
      `tmux capture-pane -t ${TMUX_SESSION} -p -S -100`,
      { encoding: 'utf8' }
    );

    // Check for phase completion markers
    for (const [phase, nextPhase] of Object.entries(PHASE_MARKERS)) {
      const marker = `<!-- PHASE_COMPLETE: ${phase} -->`;
      if (output.includes(marker)) {
        return { phase, nextPhase, detected: true };
      }
    }

    return { detected: false };
  } catch (error) {
    // Silently fail if tmux not available
    return { detected: false };
  }
}

function generateProjectId(designFile) {
  // Extract date and slug from design file path
  // e.g., "2026-03-04-phase-aware-compact-hook-design.md"
  const match = designFile.match(/(\d{4}-\d{2}-\d{2})-(.+)-design\.md/);
  if (match) {
    return `${match[1]}-${match[2]}`;
  }
  // Fallback: use current date and generic name
  const date = new Date().toISOString().split('T')[0];
  return `${date}-project`;
}

function extractDesignFileFromTerminal() {
  try {
    const output = execSync(
      `tmux capture-pane -t ${TMUX_SESSION} -p -S -50`,
      { encoding: 'utf8' }
    );

    // Look for design file being written
    const match = output.match(/docs\/plans\/(\d{4}-\d{2}-\d{2}-.+)-design\.md/);
    return match ? match[0] : null;
  } catch {
    return null;
  }
}

function triggerPreCompactFlow(phase, nextPhase) {
  try {
    // 1. Save state before compact
    execSync(`node ${path.join(__dirname, 'save-state-before-compact.js')} ${phase} ${nextPhase}`);

    // 2. Trigger delayed compact
    execSync(`${path.join(__dirname, 'trigger-compact.sh')}`);

    // Update phase state to prevent duplicate triggers
    savePhaseState({ lastPhase: phase, canTrigger: false });

    console.error(`\n📦 Phase transition detected: ${phase} → ${nextPhase}`);
    console.error(`   State saved. Compacting in ${COMPACT_DELAY}s...\n`);
  } catch (error) {
    console.error(`Failed to trigger pre-compact flow: ${error.message}`);
  }
}

function main() {
  const phaseState = getPhaseState();

  // Check if we recently triggered (prevent duplicates)
  if (!phaseState.canTrigger) {
    // Reset canTrigger after some time (e.g., 2 minutes)
    // This allows multiple compacts in a long session
    // but prevents rapid-fire triggers
    return;
  }

  const detection = detectPhaseFromTerminal();

  if (detection.detected) {
    const { phase, nextPhase } = detection;

    // Check if this is a new phase transition (not duplicate)
    if (phaseState.lastPhase !== phase) {
      // Generate project ID if this is brainstorming completion
      if (phase === 'brainstorming') {
        const designFile = extractDesignFileFromTerminal();
        if (designFile) {
          const projectId = generateProjectId(designFile);
          const projectData = getProjectId();
          projectData.currentProject = projectId;
          saveProjectId(projectData);
        }
      }

      // Trigger the pre-compact flow
      triggerPreCompactFlow(phase, nextPhase);
    }
  }
}

main();
```

---

## Task 3: Create Pre-Compact State Saver

**Files:**
- Create: `scripts/save-state-before-compact.js`

**Changes:**
- [ ] Create state preservation script
- [ ] Test: `node scripts/save-state-before-compact.js brainstorming planning`
- [ ] Commit: "feat: add pre-compact state preservation"

**Code:**

```javascript
#!/usr/bin/env node

/**
 * Pre-Compact State Saver
 *
 * Saves current session state to memory before compact.
 * Usage: node scripts/save-state-before-compact.js <current_phase> <next_phase>
 *
 * Saves to: state/memory/{project-id}-status.md
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Arguments
const CURRENT_PHASE = process.argv[2] || 'unknown';
const NEXT_PHASE = process.argv[3] || 'unknown';

// Configuration
const PROJECT_ID_FILE = path.join(__dirname, '..', 'state/sessions/.project-id.json');
const MEMORY_DIR = path.join(__dirname, '..', 'state/memory');
const TMUX_SESSION = 'cc-pichu:0.0';

function getProjectId() {
  try {
    const data = fs.readFileSync(PROJECT_ID_FILE, 'utf8');
    const parsed = JSON.parse(data);
    return parsed.currentProject || 'unknown-project';
  } catch {
    return 'unknown-project';
  }
}

function extractContextFromTerminal() {
  try {
    // Get recent terminal context
    const output = execSync(
      `tmux capture-pane -t ${TMUX_SESSION} -p -S -200`,
      { encoding: 'utf8' }
    );

    // Extract relevant sections
    const lines = output.split('\n');

    // Look for key patterns
    const context = {
      designDecisions: [],
      nextSteps: [],
      activeTasks: []
    };

    let inDesignSection = false;
    let inTaskSection = false;

    for (const line of lines) {
      // Design decisions often follow specific patterns
      if (line.match(/(decision|approach|selected)/i)) {
        context.designDecisions.push(line.trim());
      }

      // Tasks/next steps
      if (line.match(/^\s*-\s+\[.\]/)) {
        context.nextSteps.push(line.trim());
      }

      // Active task IDs
      const taskMatch = line.match(/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i);
      if (taskMatch) {
        context.activeTasks.push(taskMatch[0]);
      }
    }

    return context;
  } catch (error) {
    return { designDecisions: [], nextSteps: [], activeTasks: [] };
  }
}

function generateStatusFile(projectId, context) {
  const date = new Date().toISOString();

  return `# ${projectId} Status

**Last Updated:** ${date.split('T')[0]}
**Current Phase:** ${NEXT_PHASE}

## Phase Transition

**From:** ${CURRENT_PHASE}
**To:** ${NEXT_PHASE}

## Design Decisions
${context.designDecisions.length > 0 ? context.designDecisions.map(d => `- ${d}`).join('\n') : '_No decisions captured_'}

## Next Steps
${context.nextSteps.length > 0 ? context.nextSteps.join('\n') : '- [ ] Continue to next phase'}

## Active Task IDs
${context.activeTasks.length > 0 ? context.activeTasks.map(t => `- ${t}`).join('\n') : '_No active tasks_'}

---
*Auto-generated by save-state-before-compact.js*
`;
}

function main() {
  const projectId = getProjectId();
  const context = extractContextFromTerminal();
  const statusContent = generateStatusFile(projectId, context);

  // Ensure memory directory exists
  if (!fs.existsSync(MEMORY_DIR)) {
    fs.mkdirSync(MEMORY_DIR, { recursive: true });
  }

  // Write status file
  const statusFile = path.join(MEMORY_DIR, `${projectId}-status.md`);
  fs.writeFileSync(statusFile, statusContent);

  console.error(`✓ State saved to: ${statusFile}`);
}

main();
```

---

## Task 4: Create Compact Trigger Script

**Files:**
- Create: `scripts/trigger-compact.sh`

**Changes:**
- [ ] Create delayed compact trigger script
- [ ] Test: `./scripts/trigger-compact.sh` (verify warning sent)
- [ ] Make executable: `chmod +x scripts/trigger-compact.sh`
- [ ] Commit: "feat: add delayed compact trigger with Telegram warning"

**Code:**

```bash
#!/bin/bash
# trigger-compact.sh - Trigger delayed compact with warning
# Usage: ./scripts/trigger-compact.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
TMUX_SESSION="cc-pichu:0.0"
COMPACT_DELAY=30  # seconds
RECOVERY_DELAY=5  # seconds after compact

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
  tmux send-keys -t "$TMUX_SESSION" "/compact" Enter

  # Wait for compact to complete
  sleep $RECOVERY_DELAY

  # Inject /back message to trigger recovery response
  # Format: [TG:chat_id:bot_id:msg_id:reply_to]
  tmux send-keys -t "$TMUX_SESSION" "[TG:${CHAT_ID}:${BOT_ID}:0:0] /back" Enter
) &

echo "Compact scheduled in ${COMPACT_DELAY}s"
```

---

## Task 5: Create Active Chat Tracker

**Files:**
- Create: `state/sessions/.active-chat.json`

**Changes:**
- [ ] Create active chat tracking file
- [ ] Commit: "feat: add active chat tracker for compact messaging"

**Code:**

```json
{
  "chat_id": "195061634",
  "bot_id": "pichu",
  "last_updated": "2026-03-04"
}
```

**Note:** This file should be updated by the Commander skill when receiving messages.

---

## Task 6: Update Hook Configuration

**Files:**
- Modify: `.claude/settings.json`

**Changes:**
- [ ] Update PreToolUse hook to use track-phase.js
- [ ] Test: Run any Edit|Write operation, verify hook executes
- [ ] Commit: "feat: update hook to phase-aware tracker"

**Current content:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node scripts/suggest-compact.js"
          }
        ]
      }
    ]
  }
}
```

**New content:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node scripts/track-phase.js"
          }
        ]
      }
    ]
  }
}
```

---

## Task 7: Add Exit Marker to Brainstorming Skill

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md`

**Changes:**
- [ ] Add exit marker at end of brainstorming skill
- [ ] Only add AFTER design is approved and saved
- [ ] Commit: "feat: add phase completion marker to brainstorming skill"

**Location:** End of file, after all instructions

**Add this line:**
```markdown
<!-- PHASE_COMPLETE: brainstorming -->
```

**Note:** This marker should be added AFTER the design document is saved to disk, not during the brainstorming process itself.

---

## Task 8: Add Exit Marker to Writing-Plans Skill

**Files:**
- Modify: `.claude/skills/writing-plans/SKILL.md`

**Changes:**
- [ ] Add exit marker at end of writing-plans skill
- [ ] Only add AFTER plan is created and saved
- [ ] Commit: "feat: add phase completion marker to writing-plans skill"

**Location:** End of file, after all instructions

**Add this line:**
```markdown
<!-- PHASE_COMPLETE: writing-plans -->
```

**Note:** This marker should be added AFTER the implementation plan is saved to disk.

---

## Task 9: Update Commander Skill for Chat Tracking

**Files:**
- Modify: `.claude/skills/commander/SKILL.md`

**Changes:**
- [ ] Add active chat tracking when messages received
- [ ] Commit: "feat: track active chat for compact messaging"

**Location:** In "Message Flow" section, add step after parsing:

```markdown
## Message Flow

1. **Parse message** - Extract TG_* values
2. **Track active chat** - Update state/sessions/.active-chat.json
3. **Read identity** - cat state/memory/identity.md
4. **ACK immediately** - Send contextual ack via reply.sh
...
```

**Implementation in Commander skill (reference for subagent):**

The Commander skill should update the active chat file when parsing messages:

```bash
# In Commander SKILL.md, add after message parsing
echo "{\"chat_id\": \"$TG_CHAT_ID\", \"bot_id\": \"$TG_BOT_ID\", \"last_updated\": \"$(date -I)\"}" > state/sessions/.active-chat.json
```

---

## Task 10: Integration Testing

**Files:**
- Test: Manual integration test

**Changes:**
- [ ] Test full flow: brainstorming → compact → planning → compact → execution
- [ ] Verify state files created correctly
- [ ] Verify Telegram warnings sent
- [ ] Verify compact executes with delay
- [ ] Verify /back restores identity
- [ ] Commit: "test: verify phase-aware compact integration"

**Test Commands:**

```bash
# 1. Start fresh session
# 2. Run through brainstorming workflow
# 3. Verify phase detection triggers
node scripts/track-phase.js

# 4. Check state file created
cat state/memory/*-status.md

# 5. Verify compact warning sent (check Telegram)

# 6. Wait 30s, verify compact executed

# 7. Verify /back works
```

**Expected Results:**
- Phase detected on brainstorming completion
- State file saved to `state/memory/{project-id}-status.md`
- Telegram warning: "Compacting in 30s..."
- Compact executes after delay
- `/back` restores identity from `state/memory/identity.md`

---

## Notes

- Each task should be completable in 5-10 minutes
- All scripts should be executable (chmod +x for .sh files)
- State files use JSON for easy parsing
- tmux session name must match `cc-pichu` or update configuration
- Gateway must be running on port 3100 for Telegram messages
- **Do NOT close issue #11** - this is specific to compact, not general hook system
- Reference `state/memory/coding-standards.md` for TypeScript/bash conventions
- Exit markers in skills should be added AFTER phase completion, not during
