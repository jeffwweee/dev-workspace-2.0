# Task Tool Template

Use this to spawn background subagents:

```
Task tool:
  subagent_type: general-purpose
  model: sonnet
  description: "Execute plan: [plan name]"
  prompt: |
    Use subagent-driven-development skill to execute this plan:

    [Plan content or file path]

    Work through all tasks. Report completion with summary.
  run_in_background: true
```

## Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| subagent_type | general-purpose | For implementation tasks |
| model | sonnet | Default for most tasks (use haiku for simple, opus for complex) |
| description | Short task name | For logging |
| prompt | Plan + instructions | Use subagent-driven-development skill |
| run_in_background | true | Required - keeps Pichu responsive |

## Model Selection

| Task | Model |
|------|-------|
| Simple/quick | haiku |
| Standard implementation | sonnet (default) |
| Complex/architectural | opus |
