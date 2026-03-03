---
name: reviewer
description: Use after subagent completes to review work. Performs spec compliance check, code quality review, and confidence scoring.
---

# Reviewer

## Overview

Two-stage review system with confidence check. Use after subagent completes work.

## Review Flow

```
Subagent reports
    ↓
1. Spec Compliance Review
    ↓ Pass?
2. Code Quality Review
    ↓ Pass?
3. Confidence Check (≥8/10?)
    ↓
Notify user or spawn fix subagent
```

## Stage 1: Spec Compliance Review

Check if subagent built what was asked:

```markdown
## Spec Compliance Checklist

- [ ] All requirements implemented
- [ ] Edge cases handled
- [ ] Error handling present
- [ ] Expected behavior verified

**Issues:** {list any deviations}
**Verdict:** PASS / FAIL
```

## Stage 2: Code Quality Review

Check if it's well-built:

```markdown
## Code Quality Checklist

- [ ] Follows coding standards
- [ ] Clean, readable code
- [ ] Proper error handling
- [ ] No security issues
- [ ] Tests written and passing

**Issues:** {list any problems}
**Verdict:** PASS / FAIL
```

## Stage 3: Confidence Scoring

Rate confidence in the implementation:

```markdown
## Confidence Assessment

| Aspect | Score | Notes |
|--------|-------|-------|
| Spec Compliance | X/10 | {notes} |
| Code Quality | X/10 | {notes} |
| Test Coverage | X/10 | {notes} |
| **Overall** | **X/10** | {summary} |

## Recommendation
- [ ] {actions needed before merge}
```

## Decision Matrix

| Spec | Quality | Confidence | Action |
|------|---------|------------|--------|
| FAIL | - | - | Spawn fix subagent |
| PASS | FAIL | - | Spawn fix subagent |
| PASS | PASS | < 8 | Request manual review |
| PASS | PASS | ≥ 8 | Ready to commit |

## Notification Template

```typescript
// Ready to commit
await fetch('http://localhost:3100/reply', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    bot_id: 'pichu',
    chat_id: sessionState.chat_id,
    text: `✅ Done! {summary}\n\nConfidence: {score}/10\n\nFiles: {files}`
  })
});

// Needs fixes
await fetch('http://localhost:3100/reply', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    bot_id: 'pichu',
    chat_id: sessionState.chat_id,
    text: `⚠️ Issues found:\n\n{issues}\n\nSpawning fix subagent...`
  })
});
```
