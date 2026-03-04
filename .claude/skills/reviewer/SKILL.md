---
name: reviewer
description: Use after subagent completes to review work. Performs spec compliance check, code quality review, and confidence scoring.
---

# Reviewer

Two-stage review system with confidence check. Use after subagent completes.

## Review Flow

```
Subagent completes → Spec Compliance → Code Quality → Confidence (≥8/10?) → Notify
```

## Decision Matrix

| Spec | Quality | Confidence | Retries | Action |
|------|---------|------------|---------|--------|
| FAIL | - | - | < 3 | Spawn fix subagent |
| PASS | FAIL | - | < 3 | Spawn fix subagent |
| PASS | PASS | < 8 | - | Request manual review |
| PASS | PASS | ≥ 8 | - | Ready to commit |
| FAIL | - | - | ≥ 3 | Escalate to user |
| PASS | FAIL | - | ≥ 3 | Escalate to user |

## Review Stages

**Stage 1: Spec Compliance** - See `references/spec-checklist.md`

**Stage 2: Code Quality** - See `references/quality-checklist.md`

**Stage 3: Confidence Score** - Rate 1-10, ≥8 to pass

## Notification

Use `scripts/reply.sh` with templates from `references/notification-templates.md`

## Fix Subagent with Retry Limit

If review fails, spawn fix subagent with:
```
Task: Fix review issues
Prompt: {list of issues from review}
run_in_background: true
```

**Retry Limit:** Max 3 fix attempts per task. Track via task metadata.
After 3 failures:
1. Mark task as "failed" with error details
2. Escalate to user: "Task failed after 3 attempts. Options: Modify plan, Cancel, Try different approach?"
3. Stop automatic fix attempts

## Retry Tracking

Track attempts in task metadata:
```
metadata: { retry_count: 1, last_issue: "spec compliance failed" }
```

Increment after each fix attempt. At 3 → escalate.
