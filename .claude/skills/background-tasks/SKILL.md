---
name: background-tasks
description: Execute implementation plans in background while Pichu stays responsive. Wraps subagent-driven-development with run_in_background: true.
---

# Background Tasks

Execute plans in background while staying responsive to new messages.

## When to Use

After `writing-plans` skill completes and user approves execution.

User can also trigger manually: "execute the plan"

## Process

1. Load plan → Generate task ID → Reply "Started background execution..."
2. Spawn subagent with `Task(tool)` - see `references/task-template.md`
3. Return to message loop (task runs in background)
4. Handle completion with smart notification

## Critical Rules

1. **ALWAYS use `run_in_background: true`**
2. **Track state via `scripts/task-state.sh`**
3. **Reply immediately after spawn**
4. **Don't block - return to Commander**
5. **Smart notification - only if user idle > 60s**

## After Complete Hook

After subagent completes, capture the observation:

```bash
# After TaskOutput is received
TASK_ID="<task_id>" \
TASK_TYPE="<implement|fix|review>" \
TASK_PROMPT="<original_prompt>" \
TASK_RESULT="<result_summary>" \
FILES_CHANGED="<file1 file2>" \
./scripts/hooks/after-complete.sh
```

The hook appends to `state/learning/observations.jsonl` for later processing by `/evolve`.

## Integration

- `writing-plans` - creates the plan
- `subagent-driven-development` - execution engine
- `commander` - orchestrates flow and notifications

## Error Handling with Escalation

If task fails:
1. Check TaskOutput for error details
2. Track failure count in task state
3. If failures < 3: Auto-retry with fix subagent
4. If failures ≥ 3: Escalate immediately

**Escalation Triggers:**
- 3 consecutive task failures
- Fix subagent fails 3 times
- Critical errors (auth failures, missing dependencies)

**Escalation Message:**
"Task failed after 3 attempts: [error summary]. Options: Modify plan, Cancel, Try different approach?"
