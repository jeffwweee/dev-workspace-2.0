# Time Ago Formatter - Design Doc

## Overview

A utility function to format time differences as human-readable strings (e.g., "5m ago", "2h ago").

## File Location

```
gateway/src/utils/formatTimeAgo.ts
gateway/src/utils/formatTimeAgo.test.ts
```

## API

```typescript
type TimeAgoOptions = {
  locale?: 'en' | 'zh'
  short?: boolean
}

function formatTimeAgo(input: Date | number | string, opts?: TimeAgoOptions): string
```

### Examples

```typescript
formatTimeAgo(Date.now() - 5000)           // 'just now'
formatTimeAgo(Date.now() - 300000)         // '5m ago'
formatTimeAgo(Date.now() - 7200000)        // '2h ago'
formatTimeAgo(Date.now() - 86400000)       // '1d ago'
formatTimeAgo(date, {short: true})         // '5m'
formatTimeAgo(date, {locale: 'zh'})        // '5分钟前'
```

## Edge Cases

| Case | Behavior |
|------|----------|
| Future dates | Return 'in X' format (e.g., 'in 1m') |
| Invalid input | Throw TypeError |
| Null/undefined | Throw TypeError |
| Very old (>1 year) | Show formatted date (e.g., 'Mar 4, 2025') |

## Test Plan

File: `gateway/src/utils/formatTimeAgo.test.ts`

Test cases:
1. Basic time ranges (seconds, minutes, hours, days)
2. Short format variations
3. Locale switching (en/zh)
4. Future date handling
5. Invalid input throws
6. Null/undefined throws
7. Year+ old dates show formatted date

Coverage target: 100%

## Checkpoints to Verify

This feature tests the following workflow checkpoints:

- [ ] Brainstorming phase marker
- [ ] Design approval flow
- [ ] Writing-plans phase marker
- [ ] Subagent execution
- [ ] Verification before completion
- [ ] Hook system (after_complete)
