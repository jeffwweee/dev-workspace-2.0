# Execution Flow

## Step 1: Load Plan and Prepare State

```bash
# Read the plan file
PLAN_CONTENT=$(cat docs/plans/YYYY-MM-DD-feature-name.md)

# Generate task ID
TASK_ID=$(./scripts/task-state.sh set_running $CHAT_ID)
./scripts/task-state.sh update_last_message $CHAT_ID $MSG_ID

# Reply to user
./scripts/reply.sh $BOT_ID $CHAT_ID "Started background execution. I'll notify when done. /status for updates." $MSG_ID
```

## Step 2: Spawn Background Subagent

Use Task tool with template from `task-template.md`.

## Step 3: Return to Message Loop

After spawning, control returns immediately. Pichu can now handle new messages.

## Step 4: Handle Completion

```bash
# When Task completes (detected via TaskOutput)
./scripts/task-state.sh set_completed $CHAT_ID $TASK_ID

# Set pending notification
./scripts/task-state.sh set_pending_notification $CHAT_ID "Task done: [summary]"

# If user idle > 60s, notify immediately
if [ "$(./scripts/task-state.sh check_idle $CHAT_ID 60)" = "true" ]; then
    SUMMARY=$(./scripts/task-state.sh get_notification_summary $CHAT_ID)
    ./scripts/reply.sh $BOT_ID $CHAT_ID "Background task complete! $SUMMARY"
    ./scripts/task-state.sh clear_notification $CHAT_ID
fi
```

## Smart Notification

On each new message, Commander checks:

```bash
if [ "$(./scripts/task-state.sh has_pending_notification $CHAT_ID)" = "true" ] && \
   [ "$(./scripts/task-state.sh check_idle $CHAT_ID 60)" = "true" ]; then
    SUMMARY=$(./scripts/task-state.sh get_notification_summary $CHAT_ID)
    ./scripts/reply.sh $BOT_ID $CHAT_ID "Background task done! $SUMMARY"
    ./scripts/task-state.sh clear_notification $CHAT_ID
fi
```

## State Files

- `state/tasks/{chat_id}.md` - Summary + last message time + pending notification
- `state/tasks/{chat_id}-{task_id}.md` - Detailed progress

## Commands

- `/status` - Show current task status (Commander handles)
- `/stop` - Stop running task with `TaskStop(task_id=$TASK_ID)`
