# Confidence Scoring

## Scoring Guide

| Score | Meaning | Action |
|-------|---------|--------|
| 9-10 | Excellent, confident | Ready to commit |
| 8 | Good, minor concerns | Ready to commit |
| 6-7 | Acceptable, some concerns | Manual review |
| 1-5 | Significant issues | Spawn fix subagent |

## Scoring Template

```markdown
## Confidence Assessment

| Aspect | Score | Notes |
|--------|-------|-------|
| Spec Compliance | X/10 | {notes} |
| Code Quality | X/10 | {notes} |
| Test Coverage | X/10 | {notes} |
| **Overall** | **X/10** | {summary} |

## Recommendation
- [ ] Ready to commit
- [ ] Manual review needed
- [ ] Fixes required
```

## Scoring Criteria

**Spec Compliance:**
- 10: All requirements met, edge cases covered
- 8-9: Minor gaps, non-critical
- 6-7: Some missing requirements
- 1-5: Significant gaps

**Code Quality:**
- 10: Clean, follows standards, well-tested
- 8-9: Minor style issues
- 6-7: Some quality concerns
- 1-5: Major quality issues

**Test Coverage:**
- 10: Comprehensive tests, edge cases covered
- 8-9: Good coverage, minor gaps
- 6-7: Basic tests, missing cases
- 1-5: Inadequate or no tests

**Overall:** Average of three scores, or lower if critical concerns.
