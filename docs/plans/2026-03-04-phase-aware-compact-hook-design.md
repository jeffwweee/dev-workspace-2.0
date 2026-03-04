# Phase-Aware Smart Compact Hook - Design Document

**Date:** 2026-03-04
**Issue:** #1 - Smart compact hook not triggering
**Author:** Pichu + Jeff

## Overview

Auto-trigger compact suggestions at workflow phase boundaries (brainstorming→planning→execution) with **pre-compact state preservation** to memory files.

## Problem Statement

Current compact hook (PreToolUse on Edit|Write) is tool-count based and doesn't respect workflow boundaries. Users want:
- Compacts at logical phase transitions
- State preservation before compacts
- Automatic triggering with warnings

## Solution

Phase-aware compact system that:
1. Detects workflow skill completion
2. Saves current state to memory before compact
3. Triggers 30-second delayed auto-compact
4. Restores context after compact via `/back`

## Architecture

```
User Request → Brainstorming → Save State → [COMPACT] → Planning → Save State → [COMPACT] → Execution → Save State → [COMPACT]
```

## Components

### 1. Phase Tracker (`scripts/track-phase.js`)

Detects skill completion from terminal output and triggers pre-compact flow.

**Detection Method:** Parse skill exit signals
- `<!-- PHASE_COMPLETE: brainstorming -->`
- `<!-- PHASE_COMPLETE: writing-plans -->`
- `<!-- PHASE_COMPLETE: subagent-driven-development -->`

**Responsibilities:**
- Detect when workflow skills complete
- Generate project-id on first design doc completion
- Call `save-state-before-compact.js`
- Call `trigger-compact.sh`

### 2. Pre-Compact State Saver (`scripts/save-state-before-compact.js`)

Saves current session state to `state/memory/{project-id}-status.md`

**What gets saved:**
- Current phase completed
- Design decisions made
- Next phase goals
- Active task IDs
- Key conversation context

**State file template:**
```markdown
# {project-id} Status

**Last Updated:** 2026-03-04
**Current Phase:** planning | execution | complete

## Design Summary
[Key decisions from brainstorming]

## Next Steps
- [ ] Task 1
- [ ] Task 2

## Active Task IDs
- Background task: abc-123
```

### 3. Compact Trigger (`scripts/trigger-compact.sh`)

Executes delayed compact with warning message.

**Flow:**
1. Send warning to Telegram: "Compacting in 30s. I'll be back..."
2. Schedule delayed tmux injection (30s delay)
3. Inject `/compact` into terminal
4. Wait 5s for compact to complete
5. Inject `/back` message to trigger response
6. Pichu reads `state/memory/identity.md` and responds "I'm back"

### 4. Skill Exit Markers

Add exit signals to workflow skills:

**`.claude/skills/brainstorming/SKILL.md`:**
- Add `<!-- PHASE_COMPLETE: brainstorming -->` at end
- Only added AFTER design is approved and saved

**`.claude/skills/writing-plans/SKILL.md`:**
- Add `<!-- PHASE_COMPLETE: writing-plans -->` at end
- Only added AFTER plan is created and saved

## Phase Boundaries

| Transition | Trigger | State Saved |
|------------|---------|-------------|
| Brainstorming → Planning | Design approved | Design summary, decisions |
| Planning → Execution | Plan approved | Task list, acceptance criteria |
| Execution → Complete | Tasks done | Results, verification status |

## Project ID Generation

Created on first design doc completion:
- Format: `{date}-{topic-slug}`
- Example: `2026-03-04-smart-compact-hook`
- Reused for all phases of same project
- Stored in `state/sessions/.project-id.json`

## Files Changed

### New Files
- `scripts/track-phase.js` - Phase detection and coordination
- `scripts/save-state-before-compact.js` - State preservation
- `scripts/trigger-compact.sh` - Delayed compact execution
- `state/sessions/.project-id.json` - Active project tracking

### Modified Files
- `.claude/settings.json` - Add phase tracking hook
- `.claude/skills/brainstorming/SKILL.md` - Add exit marker
- `.claude/skills/writing-plans/SKILL.md` - Add exit marker

## Configuration

```json
// .claude/settings.json
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

## Token Savings Estimate

| Before | After |
|--------|-------|
| Manual compact timing | Automatic at boundaries |
| Context lost after compact | State preserved in memory |
| ~3500 tokens/session startup | ~400 tokens + project status |

## Acceptance Criteria

- [ ] Phase detection triggers on brainstorming completion
- [ ] Phase detection triggers on planning completion
- [ ] Phase detection triggers on execution completion
- [ ] State is saved to `state/memory/{project-id}-status.md` before each compact
- [ ] User receives 30s warning before compact
- [ ] Compact occurs after delay
- [ ] `/back` restores identity correctly
- [ ] Project status persists across compacts

## Technical Notes

- tmux session name: `cc-pichu`
- Delay before compact: 30 seconds
- Delay after compact: 5 seconds
- Identity file: `state/memory/identity.md`
- Phase state: `state/sessions/.phase-state.json`

## Related Issues

- #1 - Smart compact hook not triggering
- #11 - Feature: Hook System for Context Injection (generalization)
- #3 - State/memory management causes token bloat
