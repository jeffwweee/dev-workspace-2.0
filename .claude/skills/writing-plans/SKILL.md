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

## Plan Approval Flow

Plan → Review → Approval → Compact check → Execution

1. Save plan to `docs/plans/YYYY-MM-DD-<feature>-plan.md`
   - Log: `./scripts/log-session.sh {chat_id} plan_saved docs/plans/YYYY-MM-DD-<feature>-plan.md`
2. Send via `scripts/send-file.sh` for review
3. **Explicit confirmation required** - Wait for approval signal
4. **After approval, check for compact:**
   ```bash
   PLAN_FILE="docs/plans/YYYY-MM-DD-<feature>-plan.md"
   if [ "$(./scripts/check-doc-size.sh "$PLAN_FILE")" = "recommend" ]; then
     SIZE_KB=$(du -k "$PLAN_FILE" | cut -f1)
     reply "Plan approved. Doc is large (${SIZE_KB}KB). Consider /compact to free context before execution."
   else
     reply "Plan approved. Ready for execution phase."
   fi
   ```
5. If approved → User triggers execution (manually or via command)
6. If changes → Revise and resend

**Approval signals:** "approved", "looks good", "yes proceed", "LGTM", "execute"

**Do NOT proceed** without explicit approval. If uncertain, ask: "Approve this plan? (yes/no/request changes)"

**IMPORTANT:** Only check for compact AFTER user approval, not before.

## Guidelines

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

<!-- PHASE_COMPLETE: writing-plans -->
