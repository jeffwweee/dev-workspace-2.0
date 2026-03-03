# Context Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix compact/context issues #1, #3, #4 to restore smart compact and preserve Pichu identity.

**Architecture:** Essential identity file read every message + lazy-loaded memory files via /memory command + fixed hook path.

**Tech Stack:** Node.js (hooks), Markdown (memory files), Bash (reply scripts)

---

## Task 1: Fix Hook Path (Issue #1)

**Files:**
- Modify: `.claude/settings.json`

**Step 1: Update settings.json hook path**

Change the hook command from absolute path to relative path.

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

**Step 2: Verify the script runs**

Run: `node scripts/suggest-compact.js`
Expected: No error (script runs silently until threshold)

**Step 3: Clean up old counter file if exists**

Run: `rm -f .compact-counter.json`
Expected: File removed (if existed)

**Step 4: Commit**

```bash
git add .claude/settings.json
git commit -m "fix(hooks): use relative path for suggest-compact script

Fixes #1 - hook was pointing to non-existent old directory path."
```

---

## Task 2: Create Identity File (Issue #4)

**Files:**
- Create: `state/memory/identity.md`

**Step 1: Create identity.md**

Create the essential identity file that will be read on every message:

```markdown
# Pichu Identity

You are Pichu, the Commander orchestrator for the Telegram multi-agent system.

## Essential Rules

1. **Parse message format:** `[TG:chat_id:bot_id:msg_id:reply_to]`
2. **Reply via script:** Use `scripts/reply.sh` for ALL responses
3. **No terminal output:** User cannot see terminal from Telegram

## Key Commands

| Command | Action |
|---------|--------|
| /status | Show task status |
| /stop | Stop background task |
| /memory | Load memory files |
| /compact | Trigger compact |

## Full Documentation

See: `.claude/skills/commander/SKILL.md`
```

**Step 2: Verify file exists**

Run: `cat state/memory/identity.md`
Expected: File contents displayed

**Step 3: Commit**

```bash
git add state/memory/identity.md
git commit -m "feat(memory): add identity file for compact persistence

Part of #4 - essential context preserved through compacts."
```

---

## Task 3: Update Commander Session Start (Issue #3)

**Files:**
- Modify: `.claude/skills/commander/SKILL.md` (lines 12-22)

**Step 1: Update Session Start section**

Replace the current "Session Start" section (lines 12-22) with:

```markdown
## Session Start

When starting a new session:

1. **Read identity file:** `state/memory/identity.md`
2. **Wait for messages** (injected via tmux)

Note: Memory files (project-status, preferences, etc.) are loaded on demand via /memory command.
```

**Step 2: Verify the change**

Run: `grep -A 8 "## Session Start" .claude/skills/commander/SKILL.md`
Expected: New section content displayed

**Step 3: Commit**

```bash
git add .claude/skills/commander/SKILL.md
git commit -m "refactor(commander): lazy-load memory files at session start

Part of #3 - reduces startup token usage from ~3500 to ~400 tokens."
```

---

## Task 4: Add Identity Read to Message Flow (Issue #4)

**Files:**
- Modify: `.claude/skills/commander/SKILL.md` (after line 80)

**Step 1: Add new section after "Step 1: Parse the message"**

Insert after line 80 (after the parse step):

```markdown
### Step 1b: Read identity file (every message)

Always read the identity file to ensure compact persistence:

```bash
# Read identity to maintain Commander awareness after compacts
cat state/memory/identity.md
```

This ensures Pichu remembers its role even after /compact.
```

**Step 2: Verify the change**

Run: `grep -A 8 "Step 1b" .claude/skills/commander/SKILL.md`
Expected: New section displayed

**Step 3: Commit**

```bash
git add .claude/skills/commander/SKILL.md
git commit -m "feat(commander): read identity file on every message

Fixes #4 - ensures Pichu maintains identity after /compact."
```

---

## Task 5: Add /memory Command (Issue #3)

**Files:**
- Modify: `.claude/skills/commander/SKILL.md` (Command Detection section)

**Step 1: Add /memory to Command Detection table**

Update the Command Detection table (around line 178-187) to include /memory:

```markdown
## Command Detection

If message starts with `/`, handle as command:

| Command | Action |
|---------|--------|
| /status | Show running task status + pending notifications |
| /stop | Stop current background task (TaskStop) |
| /memory | Load memory files (project-status, preferences, coding-standards) |
| /clear | Reset session file |
| /compact | Trigger strategic compact |
| /save | Force memory update |
| /tasks | List recent task files |
```

**Step 2: Add /memory handler documentation**

Add new section after Command Detection:

```markdown
### /memory Command

Load memory files on demand:

```bash
# Load all memory files
cat state/memory/project-status.md
cat state/memory/preferences.md
cat state/memory/coding-standards.md
cat state/memory/phrases.md
```

Then acknowledge: "Memory loaded."
```

**Step 3: Verify the changes**

Run: `grep -A 15 "## Command Detection" .claude/skills/commander/SKILL.md`
Expected: Table with /memory command and handler section

**Step 4: Commit**

```bash
git add .claude/skills/commander/SKILL.md
git commit -m "feat(commander): add /memory command for lazy loading

Part of #3 - memory files now loaded on demand."
```

---

## Task 6: Update Memory Files Section (Issue #3)

**Files:**
- Modify: `.claude/skills/commander/SKILL.md` (Memory Files section)

**Step 1: Update Memory Files section**

Replace the Memory Files section (around line 220-229) with:

```markdown
## Memory Files

**Identity (always loaded):**
- `state/memory/identity.md` - Core Commander identity (read every message)

**On-demand (via /memory command):**
- `state/memory/project-status.md` - Current phase, active work
- `state/memory/preferences.md` - User preferences
- `state/memory/coding-standards.md` - Coding conventions
- `state/memory/phrases.md` - Response phrase variations

**Knowledge (reference only):**
- `state/memory/knowledge/patterns.md` - Reusable patterns
- `state/memory/knowledge/gotchas.md` - Things to avoid

Update at session end:
- `state/memory/project-status.md` - Update status
- `state/memory/knowledge/` - Add learnings
```

**Step 2: Verify the change**

Run: `grep -A 20 "## Memory Files" .claude/skills/commander/SKILL.md`
Expected: New section with identity/on-demand split

**Step 3: Commit**

```bash
git add .claude/skills/commander/SKILL.md
git commit -m "docs(commander): update memory files section for lazy loading

Clarifies which files are always loaded vs on-demand."
```

---

## Task 7: Final Verification

**Step 1: Verify all files changed**

Run: `git status`
Expected: All changes committed, clean working tree

**Step 2: View commit log**

Run: `git log --oneline -6`
Expected: 6 commits for this implementation

**Step 3: Push to remote**

Run: `git push origin main`
Expected: Push successful

**Step 4: Close GitHub issues**

Run: `gh issue close 1 --comment "Fixed: Hook path corrected to use relative path."`
Run: `gh issue close 3 --comment "Fixed: Memory files now lazy-loaded via /memory command."`
Run: `gh issue close 4 --comment "Fixed: Identity file read on every message ensures compact persistence."`

---

## Summary

**Files Modified:**
- `.claude/settings.json` - Fixed hook path
- `.claude/skills/commander/SKILL.md` - Updated session flow, added /memory

**Files Created:**
- `state/memory/identity.md` - Essential identity file

**Token Savings:**
- Startup: ~3500 → ~400 tokens (87% reduction)
- Per-message: +200 tokens (identity read)

**Issues Resolved:**
- #1: Smart compact hook not triggering
- #3: Token bloat from context inheritance
- #4: Compact causes identity loss
