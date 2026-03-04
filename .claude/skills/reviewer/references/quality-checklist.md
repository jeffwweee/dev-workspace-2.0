# Code Quality Checklist

## Checklist

- [ ] Follows coding standards (see `state/memory/coding-standards.md`)
- [ ] Clean, readable code
- [ ] Proper error handling
- [ ] No security issues
- [ ] Tests written and passing

## Report Format

```markdown
## Code Quality

**Status:** PASS / FAIL

**Checks:**
- ✅/❌ Follows coding standards
- ✅/❌ Clean, readable
- ✅/❌ Proper error handling
- ✅/❌ No security issues
- ✅/❌ Tests passing

**Issues:** {list any quality problems}

**Verdict:** PASS / FAIL
```

## Common Issues to Check

- Unused imports/variables
- Inconsistent naming conventions
- Missing or inadequate tests
- Hardcoded values that should be constants
- Missing input validation
- SQL injection, XSS vulnerabilities
- Error messages exposing sensitive info
