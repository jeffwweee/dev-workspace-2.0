---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming

Turn ideas into designs through collaborative dialogue.

## HARD-GATE

**DO NOT write code or implement until design is approved.** Every project, every issue, every bugfix. Even "simple" ones.

## Process

1. **Handle Telegram** - Parse TG_* values, ACK immediately (see `references/telegram-handling.md`)
2. Explore project context (files, docs, commits)
3. Ask clarifying questions (one at a time)
4. Propose 2-3 approaches with trade-offs
5. Present design section-by-section, get approval
6. Write design doc → commit
7. Invoke `writing-plans` skill

## Telegram Mode

See `references/telegram-handling.md` for message parsing and ACK flow.

**DO NOT use AskUserQuestion** - not visible in Telegram.

Use `scripts/reply.sh` with lettered options. See `references/telegram-format.md` for examples.

## After Design Approved

Design doc (WHAT) → Implementation plan (HOW) → Execution

1. Save design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
   - Log: `./scripts/log-session.sh {chat_id} design_saved docs/plans/YYYY-MM-DD-<topic>-design.md`
2. Send via `scripts/send-file.sh` for review
3. **Explicit confirmation required** - Wait for approval signal
4. If approved → invoke `writing-plans` skill
5. If changes → revise and resend

**Approval signals:** "approved", "looks good", "yes proceed", "LGTM"

**Do NOT proceed** without explicit approval. If uncertain, ask: "Approve this design? (yes/no/request changes)"

## After Design Saved

After saving the design doc, check if it's large and recommend compact:

```bash
# Check if design doc is large
DOC_FILE="docs/plans/YYYY-MM-DD-<topic>-design.md"  # Use actual filename
if [ "$(./scripts/check-doc-size.sh "$DOC_FILE")" = "recommend" ]; then
  SIZE_KB=$(du -k "$DOC_FILE" | cut -f1)
  reply "Design saved. Doc is large (${SIZE_KB}KB). Consider /compact to free context before planning."
else
  reply "Design saved. Ready for planning phase."
fi
```

Replace `YYYY-MM-DD-<topic>-design.md` with the actual design file path.

## Key Principles

- One question at a time
- Multiple choice preferred
- YAGNI ruthlessly
- Explore 2-3 approaches
- Incremental validation

<!-- PHASE_COMPLETE: brainstorming -->
