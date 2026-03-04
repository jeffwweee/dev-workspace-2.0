# Subagent-Driven Development Flow

## Detailed Workflow

```
1. Read plan file once (extract all tasks with full text and context)
2. Create TodoWrite with all tasks
3. For each task:
   a. Dispatch implementer subagent
   b. Handle any questions (answer, re-dispatch)
   c. Implementer completes → self-review → commit
   d. Dispatch spec compliance reviewer
   e. If spec fails → implementer fixes → re-review
   f. Spec passes → Dispatch code quality reviewer
   g. If quality fails → implementer fixes → re-review
   h. Quality passes → Mark task complete in TodoWrite
4. After all tasks → Final review → Complete
```

## Per-Task Cycle

```
┌─────────────────────────────────────────────────────────┐
│ Task: [Task Name]                                       │
├─────────────────────────────────────────────────────────┤
│ 1. Implementer → 2. Spec Review → 3. Quality Review    │
│    ↓              ↓                   ↓                 │
│  Questions?     Fail?              Fail?                │
│    ↓              ↓                   ↓                 │
│  Answer          Fix                 Fix                 │
│    ↓              ↓                   ↓                 │
│  Re-dispatch    Re-review           Re-review           │
│    ↓              ↓                   ↓                 │
│  Implement      Pass                Pass                │
│    ↓                                  ↓                 │
│  Self-review                         Complete            │
│    ↓                                                     │
│  Commit                                                │
└─────────────────────────────────────────────────────────┘
```

## Dispatch Template

```
Task tool:
  subagent_type: general-purpose
  model: sonnet
  description: "Implement: [task name]"
  prompt: |
    You are implementing this task:

    [FULL TASK TEXT WITH CONTEXT]

    Follow TDD: test → implement → verify → commit.
    Self-review before reporting complete.
```

## If Subagent Fails

- Dispatch fix subagent with specific issue
- Don't fix manually (context pollution)
- Use same model (sonnet)
