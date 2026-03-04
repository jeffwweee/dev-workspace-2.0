---
name: using-skill
description: Use at conversation start. If 1% chance a skill applies, invoke BEFORE any response. Always check first.
---

# Using Skills

## The Rule

**IF A SKILL APPLIES TO YOUR TASK, YOU MUST USE IT.**

Invoke relevant skills BEFORE any response. Even 1% chance = invoke.

## Decision Flow

```
User message → About to EnterPlanMode? → Have design? → Any skill apply? → Invoke skill or respond
```

See `references/flow.md` for detailed flow.

## Dev Workspace Workflow

| Order | Skill | Purpose |
|-------|-------|---------|
| 1 | brainstorming | Explore requirements, approaches |
| 2 | writing-plans | Create implementation tasks |
| 3 | background-tasks | Execute in background |
| 4 | verification-before-completion | Verify before claiming done |

## Skill Priority

1. **Workflow skills** (brainstorming, writing-plans, etc.)
2. **Process skills** (debugging, systematic-debugging)
3. **Implementation skills** (nodejs-backend-typescript, etc.)

**Multiple skills?** Apply in priority order.

## Red Flags

Stop and check for skills if you think:
- "This is simple" → Check anyway
- "I need context first" → Skill check comes first
- "I'll just do this one thing" → Check BEFORE doing

See `references/red-flags.md` for more.
