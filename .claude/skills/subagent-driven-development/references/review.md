# Two-Stage Review Process

## Stage 1: Spec Compliance Review

**Question:** Did we build EXACTLY what was asked?

### Checklist

- [ ] All requirements implemented
- [ ] Edge cases handled
- [ ] Error handling present
- [ ] No extra features added

### Template

```markdown
## Spec Compliance Review

**Task:** [task name]

**Requirements from plan:**
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

**Issues:**
- [ ] Missing: [what's missing]
- [ ] Extra: [what wasn't requested]

**Verdict:** ✅ PASS / ❌ FAIL
```

## Stage 2: Code Quality Review

**Question:** Is it well-built?

### Checklist

- [ ] Follows coding standards
- [ ] Clean, readable code
- [ ] Proper error handling
- [ ] No security issues
- [ ] Tests written and passing

### Template

```markdown
## Code Quality Review

**Files:** [list files]

**Checks:**
- [ ] Coding standards
- [ ] Code cleanliness
- [ ] Error handling
- [ ] Security issues
- [ ] Test coverage

**Issues:**
- [Critical]: [must fix]
- [Important]: [should fix]
- [Suggestions]: [nice to have]

**Verdict:** ✅ PASS / ❌ FAIL
```

## Review Loop

```
Implementer completes → Spec Review
                              ↓
                         Pass?
                    ↗         ↓
                   NO        YES
                   ↓          ↓
              Fix issues  Quality Review
                              ↓
                         Pass?
                    ↗         ↓
                   NO        YES
                   ↓          ↓
              Fix issues   Task complete
```

## Critical Rules

1. **Spec MUST pass before quality review** - Wrong order = waste
2. **Issues found = re-review required** - Don't skip
3. **Same implementer fixes** - Keep context
4. **No "close enough"** - Spec fails = not done
