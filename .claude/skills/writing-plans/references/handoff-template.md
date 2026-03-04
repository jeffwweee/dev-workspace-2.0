# Execution Handoff Templates

## After Plan Saved

```
Plan saved to `docs/plans/YYYY-MM-DD-<feature-name>.md`.

Start background execution now?
```

## If User Approves (yes/go/start/approve)

1. Use `background-tasks` skill with:
   - Plan file path
   - Task description
   - `run_in_background: true`

2. Confirm to user:
   ```
   Starting background execution. I'll notify you when complete.
   ```

## If User Declines (no/wait/later)

```
Plan saved and ready. Say "execute the plan" anytime to start.
```

## During Execution

Monitor via TaskOutput tool:
- Check status: `TaskOutput(task_id="...", block=false)`
- Wait for completion: `TaskOutput(task_id="...", block=true)`

## After Completion

1. Get results from TaskOutput
2. Format and send via reply.sh
3. Update project-status.md if needed
