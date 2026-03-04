---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Creates implementation plans for background-tasks skill.
---

# Writing Plans

Write implementation plans for subagents to execute. Include context: files, patterns, architecture.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`

## Telegram Mode

See `references/telegram-handling.md` for message parsing and ACK flow.

## Plan Review

Before saving, verify:
- [ ] All tasks have file paths
- [ ] Code is complete (not pseudocode)
- [ ] Commands are exact with expected output
- [ ] Context included (files, patterns, memory)

See `.claude/skills/writing-plans/references/plan-template.md` for template.

## Execution Handoff

See `.claude/skills/writing-plans/references/handoff-template.md` for handoff scripts.

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

# Log plan save for session tracking
./scripts/log-session.sh {chat_id} plan_saved docs/plans/YYYY-MM-DD-<feature>-plan.md
```

Replace `YYYY-MM-DD-<feature>-plan.md` with the actual plan file path.

## Guidelines

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

<!-- PHASE_COMPLETE: writing-plans -->
