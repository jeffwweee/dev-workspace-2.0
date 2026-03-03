# Commands Reference

## /stop
Stops any currently running task/subagent.

**Action:**
- Check if there's a running background task
- Call TaskStop if applicable
- Reply with confirmation

## /clear
Clears session state for the current chat.

**Action:**
- Reset state/sessions/{chat_id}.md to initial state
- Reply with confirmation

## /compact
Triggers context compaction.

**Action:**
- Use strategic compact to reduce context
- Reply with confirmation

## /status
Shows current project status.

**Action:**
- Read state/memory/project-status.md
- Format and send key info (phase, active work, blockers)
