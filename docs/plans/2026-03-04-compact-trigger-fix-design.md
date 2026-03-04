# Compact Trigger Fix Design

## Overview

Simple doc-size-based compact recommendation. After writing design/plan docs, check size and recommend /compact if document is large.

## Design Decisions

| Aspect | Decision |
|--------|----------|
| Behavior | Manual compact only (user triggered) |
| Detection | Check doc size after writing |
| Trigger | Recommend /compact if doc > 5KB |
| Phases | brainstorming, writing-plans (doc-generating phases) |

## Problem Statement

Current `track-phase.js` hook runs on PreToolUse (before skill outputs), so it misses phase completion markers. Also, state tracking is not reliable for context estimation.

## Solution

After a skill writes a doc (design or plan):
1. Check the file size
2. If > 5KB (≈ 1000+ tokens), recommend /compact to user
3. User decides whether to compact

No auto-compact, no state tracking, no context estimation.

## Architecture

```
Skill writes doc (design or plan)
       ↓
scripts/check-doc-size.sh
       ↓
    Size > 5KB?
    ↓      ↓
   Yes     No
    ↓       ↓
Recommend  Silent
/compact   completion
```

## Components

### 1. Doc Size Checker Script

**File:** `scripts/check-doc-size.sh`

**Purpose:** Check if a doc file is large enough to warrant compact recommendation

**Code:**
```bash
#!/bin/bash
# check-doc-size.sh - Check if doc is large, recommend compact

DOC_FILE="$1"
SIZE_THRESHOLD_KB=5  # 5KB ≈ 1000+ tokens

if [ ! -f "$DOC_FILE" ]; then
  echo "File not found: $DOC_FILE"
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

### 2. Skill Integration

**brainstorming/SKILL.md** - Add after design is saved:
```markdown
## After Design Saved

Check if design doc is large:
\`\`\`bash
if [ "$(./scripts/check-doc-size.sh docs/plans/DESIGN_FILE.md)" = "recommend" ]; then
  reply "Design doc is large. Consider /compact to free context."
fi
\`\`\`
```

**writing-plans/SKILL.md** - Add after plan is saved:
```markdown
## After Plan Saved

Check if plan doc is large:
\`\`\`bash
if [ "$(./scripts/check-doc-size.sh docs/plans/PLAN_FILE.md)" = "recommend" ]; then
  reply "Plan doc is large. Consider /compact to free context."
fi
\`\`\`
```

## Files Changed

### New Files
- `scripts/check-doc-size.sh` - Simple doc size checker

### Modified Files
- `.claude/skills/brainstorming/SKILL.md` - Add size check after design save
- `.claude/skills/writing-plans/SKILL.md` - Add size check after plan save

### Removed/Deprecated Files
- `scripts/track-phase.js` - No longer needed (keep for reference)
- `scripts/smart-compact.sh` - Not needed (simplified approach)

## User Experience

**When doc is large (> 5KB):**
```
[Telegram]
Design saved to docs/plans/2026-03-04-xxx-design.md

Doc is large (8KB). Consider /compact to free context before proceeding.
```

**When doc is small (< 5KB):**
```
[Telegram]
Design saved to docs/plans/2026-03-04-xxx-design.md

Ready for next phase.
```

## Implementation Phases

### Phase 1: Create Script
- [ ] Create `scripts/check-doc-size.sh`
- [ ] Test with various file sizes

### Phase 2: Skill Integration
- [ ] Update brainstorming skill
- [ ] Update writing-plans skill

### Phase 3: Testing
- [ ] Test with small doc (should not recommend)
- [ ] Test with large doc (should recommend)

## Success Criteria

- [ ] Script checks doc file size
- [ ] Recommends /compact if doc > 5KB
- [ ] Silent if doc < 5KB
- [ ] Works from both brainstorming and writing-plans skills
- [ ] No state tracking required
- [ ] No auto-compact (user decides)

## Why This Approach

1. **Simple** - Just check file size, no complex state tracking
2. **Reliable** - File size is always accurate
3. **User control** - User decides when to compact
4. **No dependencies** - Doesn't need session files or task state
5. **Predictable** - Same doc size = same recommendation

## Threshold Rationale

| Doc Size | Tokens (est.) | Action |
|----------|---------------|--------|
| < 3KB | < 600 | Silent |
| 3-5KB | 600-1000 | Silent |
| > 5KB | > 1000 | Recommend /compact |
| > 10KB | > 2000 | Strong recommend |

Large docs indicate complex features that consumed significant context during brainstorming/planning.
