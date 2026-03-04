# Hook System Design - after_complete

## Overview

Implement an `after_complete` hook system that captures learnings when subagents finish, storing them for later pattern extraction via `/evolve`.

## Design Decisions

| Aspect | Decision |
|--------|----------|
| Hook type | `after_complete` only (MVP) |
| Capture scope | Full context (results + learnings + memory updates + skill suggestions) |
| Storage | `state/learning/observations.jsonl` (append-only log) |
| Processing | Manual `/evolve` command at session close |
| Destination | Two-tier: obvious → memory files, uncertain → candidates |
| Implementation | Hybrid: Bash capture + Node.js process |

## Architecture

```
Subagent completes
       ↓
scripts/hooks/after-complete.sh
       ↓
state/learning/observations.jsonl
       ↓
User runs /evolve
       ↓
scripts/evolve.js (Node.js)
       ↓
   ┌─────────────────┐
   │ Pattern Router  │
   └────────┬────────┘
            │
    ┌───────┴───────┐
    ↓               ↓
memory/      candidates/
patterns.md  (review queue)
gotchas.md
```

## Components

### 1. Capture Script (Bash)

**File:** `scripts/hooks/after-complete.sh`

**Purpose:** Fast capture of subagent completion context

**Inputs (environment variables):**
- `TASK_ID` - Unique task identifier
- `TASK_TYPE` - Type of task (implement, fix, review, etc.)
- `TASK_PROMPT` - Original prompt given to subagent
- `TASK_RESULT` - Output from TaskOutput
- `FILES_CHANGED` - List of modified files

**Output:** Appends JSON line to `observations.jsonl`

**JSON Structure:**
```json
{
  "timestamp": "2026-03-04T12:00:00Z",
  "task_id": "task-abc123",
  "task_type": "implement",
  "prompt": "...",
  "result_summary": "...",
  "files_changed": ["src/foo.ts"],
  "commands_run": ["npm test"],
  "patterns_detected": [],
  "decisions": [],
  "errors_resolved": []
}
```

### 2. Evolution Processor (Node.js)

**File:** `scripts/evolve.js`

**Purpose:** Extract patterns from observations and route to appropriate destination

**Trigger:** `/evolve` command via Telegram

**Process:**
1. Read all observations from `observations.jsonl`
2. Cluster by pattern type (error resolution, decisions, code patterns)
3. Score confidence (0.0-1.0) for each pattern
4. Route based on confidence:
   - High (≥0.8) → Update memory files directly
   - Medium (0.5-0.8) → Create candidate file for review
   - Low (<0.5) → Discard or keep observation

**Output files:**
- `state/memory/knowledge/patterns.md` - High-confidence patterns
- `state/memory/knowledge/gotchas.md` - High-confidence gotchas
- `state/learning/candidates/{timestamp}.md` - Medium-confidence for review

### 3. Commander Integration

**Update:** `.claude/skills/commander/SKILL.md`

Add `/evolve` command handler:
```markdown
| /evolve | Extract patterns from observations and route to memory/candidates |
```

**Flow:**
1. User sends `/evolve`
2. Pichu runs `scripts/evolve.js`
3. Reports results: "Extracted 3 patterns → memory, 2 → candidates"

### 4. Background Tasks Integration

**Update:** `.claude/skills/background-tasks/SKILL.md`

After TaskOutput received, run hook:
```bash
# After task completes
TASK_ID="..." TASK_RESULT="..." scripts/hooks/after-complete.sh
```

## File Structure

```
state/
├── learning/
│   ├── observations.jsonl    # Append-only log
│   └── candidates/           # Review queue
│       └── 2026-03-04-120000.md
├── memory/
│   └── knowledge/
│       ├── patterns.md       # Auto-updated by /evolve
│       └── gotchas.md        # Auto-updated by /evolve
```

## Observation Schema

```typescript
interface Observation {
  timestamp: string;
  task_id: string;
  task_type: 'implement' | 'fix' | 'review' | 'explore' | 'test';
  prompt: string;
  result_summary: string;
  files_changed: string[];
  commands_run: string[];
  patterns_detected: string[];
  decisions: string[];
  errors_resolved: string[];
}
```

## Pattern Extraction Logic

The `/evolve` processor looks for:

| Pattern Type | Detection Signal | Confidence |
|--------------|------------------|------------|
| Error resolution | "error" + "fixed" + solution | 0.8 |
| Code pattern | Same pattern 3+ times | 0.9 |
| Decision | "decided to" / "chose to" | 0.7 |
| Gotcha | "avoid" / "don't" / "issue" | 0.6 |
| User correction | User said "actually" / "no" | 0.5 |

## Commands

| Command | Description |
|---------|-------------|
| `/evolve` | Process observations → extract patterns → route |
| `/evolve-status` | Show pending observations count |
| `/candidates` | List pending candidates for review |

## Implementation Phases

### Phase 1: Core Infrastructure
- [ ] Create `scripts/hooks/after-complete.sh`
- [ ] Create `state/learning/` directory structure
- [ ] Define observation JSON schema
- [ ] Update background-tasks skill to call hook

### Phase 2: Evolution Processor
- [ ] Create `scripts/evolve.js`
- [ ] Implement pattern detection
- [ ] Implement confidence scoring
- [ ] Implement routing logic

### Phase 3: Commander Integration
- [ ] Add `/evolve` command handler
- [ ] Add `/evolve-status` command
- [ ] Add `/candidates` command
- [ ] Update SKILL.md

### Phase 4: Testing & Polish
- [ ] Test with real tasks
- [ ] Verify JSONL format
- [ ] Verify pattern extraction quality
- [ ] Document usage

## Success Criteria

- [ ] Hook runs after every subagent completion
- [ ] Observations logged to JSONL correctly
- [ ] `/evolve` extracts patterns with confidence scores
- [ ] High-confidence patterns update memory files
- [ ] Medium-confidence patterns go to candidates
- [ ] User can review and promote/discard candidates

## Future Enhancements (Out of Scope)

- `before_spawn` hooks for context injection
- `before_reply` hooks for formatting
- Auto-evolution at observation threshold
- Skill generation from pattern clusters
