# Context Management Design

## Overview

Comprehensive fix for GitHub issues #1, #3, #4 affecting Pichu persistent session.

**Goal:** Fix compact/context issues together with a unified architecture.

## Architecture

1. **Essential identity file** - always loaded, compact-persistent
2. **Lazy-loaded memory files** - loaded on demand
3. **Session summarization script** - runs before compact
4. **Fixed hook path** - restore smart compact functionality

## Issue Fixes

### Issue #1: Smart compact hook not triggering

**Root cause:** Hook path in `.claude/settings.json` points to wrong directory.

**Fix:**
- Update `.claude/settings.json` to use correct relative path
- Change from: `/home/jeffwweee/jef/development-workspace/dev-workspace-v2/scripts/suggest-compact.js`
- Change to: `scripts/suggest-compact.js` (relative to project root)
- Reset counter file location to use correct path

### Issue #4: Compacting causes Pichu to forget core capabilities

**Approach:** Hybrid (essential context file + manual recovery)

**Fix:**
- Create `state/memory/identity.md` with core Commander info (~200 tokens)
- Commander reads this file on EVERY message (not just startup)
- Manual `/commander` still works as fallback

**Identity file content:**
```markdown
# Pichu Identity

You are Pichu, the Commander orchestrator for the Telegram multi-agent system.

## Essential Rules

1. Parse message format: [TG:chat_id:bot_id:msg_id:reply_to]
2. Use scripts/reply.sh for ALL responses to Telegram
3. Never output to terminal - user cannot see it

## Key Commands

- /status - Show task status
- /stop - Stop background task
- /memory - Load memory files
- /compact - Trigger compact

## Full Documentation

Read full Commander skill: .claude/skills/commander/SKILL.md
```

### Issue #3: State/memory management causes token bloat

**Approach:** Moderate (lazy-load + session summarization)

**Fix:**
- Add `/memory` command to load memory files on demand
- Update Commander SKILL.md: skip memory files at startup (only load identity.md)
- Create pre-compact summarization script that captures:
  - Current task state
  - Recent decisions
  - Active work items

## Implementation Sequence

1. **Fix hook path (issue #1)** - immediate
   - Update `.claude/settings.json`
   - Test with `npm run gateway`

2. **Create identity.md** - immediate
   - Create `state/memory/identity.md`
   - Keep minimal (~200 tokens)

3. **Update Commander SKILL.md**
   - Add identity.md read on every message
   - Remove memory file reads from session start
   - Add `/memory` command handler

4. **Add /memory command**
   - Lazy-loads: project-status.md, preferences.md, coding-standards.md
   - Optional: specify specific file

5. **Create pre-compact summarization script**
   - `scripts/summarize-session.js`
   - Captures current state before compact
   - Saves to `state/sessions/{chat_id}-summary.md`

6. **Test full flow**
   - Start fresh Pichu session
   - Verify identity persistence after /compact
   - Verify /memory loads correctly
   - Verify hook triggers

## Token Savings Estimate

| Component | Before | After |
|-----------|--------|-------|
| Startup memory | ~1500 tokens | ~200 tokens |
| Commander skill | ~2000 tokens | ~200 tokens (identity only) |
| Per-message overhead | 0 | ~200 tokens (identity read) |
| **Total startup** | ~3500 tokens | ~400 tokens |

## Files Changed

- `.claude/settings.json` - fix hook path
- `state/memory/identity.md` - new file
- `.claude/skills/commander/SKILL.md` - update session flow
- `scripts/summarize-session.js` - new file (optional, phase 2)

## Success Criteria

- [ ] Hook triggers correctly at threshold
- [ ] After /compact, Pichu still knows it's Commander
- [ ] /memory command loads memory on demand
- [ ] Token usage reduced at session start
