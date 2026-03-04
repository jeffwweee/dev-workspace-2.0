# Using-Skill Decision Flow

## Detailed Flow

```
1. User message received
   ↓
2. About to EnterPlanMode?
   │
   ├─ YES → Have you already done brainstorming/planning?
   │         │
   │         ├─ NO → Invoke brainstorming skill first
   │         │
   │         └─ YES → Continue to step 3
   │
   └─ NO → Continue to step 3
   ↓
3. MIGHT any skill apply? (even 1% chance)
   │
   ├─ YES → Invoke the Skill tool NOW
   │         ↓
   │         Announce: "Using [skill] to [purpose]"
   │         ↓
   │         Does the skill have a checklist?
   │         │
   │         ├─ YES → Create a todo item for each checklist item
   │         │
   │         └─ NO → Follow the skill instructions exactly
   │
   └─ NO → You may now respond (including clarifying questions)
```

## Examples

| User Request | Skill to Invoke |
|--------------|----------------|
| "Let's build X" | brainstorming |
| "Implement this plan" | subagent-driven-development |
| "Fix this bug" | systematic-debugging |
| "Create a REST API" | nodejs-backend-typescript |
| "Tests passing?" | verification-before-completion |

## After Skill Invocation

If skill doesn't apply after reading it:
- Continue with your response
- Don't force-fit the skill
- You've satisfied the "check first" rule
