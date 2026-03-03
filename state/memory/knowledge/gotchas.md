# Gotchas

Things to avoid based on lessons learned.

## Over-engineering
- Keep code simple and minimal
- Target < 500 lines total
- Delete unused code immediately

## Context Loss
- Always persist important info to memory files
- Update project-status.md after significant work
- Use strategic compact at logical boundaries

## Message Loss
- Redis provides backup for session context
- tmux logs can be reviewed if needed

## Subagent Communication
- Subagents NEVER call /reply directly
- Pichu handles all user communication
- Subagents report back via return value
