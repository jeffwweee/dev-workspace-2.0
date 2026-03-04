# Time Ago Formatter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `background-tasks` to implement this plan task-by-task.

**Goal:** Create a time ago formatter utility with locale support and full test coverage.

**Architecture:** Single utility function with configurable options. Uses time thresholds to determine appropriate unit (seconds, minutes, hours, days). Falls back to date string for dates older than 1 year.

**Tech Stack:** TypeScript, Vitest (testing)

**Context:**
- No existing utils folder - will create `gateway/src/utils/`
- No test framework - will add Vitest to gateway
- TypeScript strict mode enabled
- See design doc: `docs/plans/2026-03-04-time-ago-formatter-design.md`

---

## Task 1: Set up Vitest

**Files:**
- Modify: `gateway/package.json`
- Create: `gateway/vitest.config.ts`

**Changes:**
- [ ] Add vitest dependency
- [ ] Create vitest config
- [ ] Add test script
- [ ] Run `npm install -w gateway`

**Code:**

`gateway/package.json` - add to devDependencies and scripts:
```json
{
  "devDependencies": {
    "vitest": "^1.2.0"
  },
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

`gateway/vitest.config.ts`:
```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    include: ['src/**/*.test.ts'],
  },
})
```

**Command:** `npm install -w gateway`

**Commit:** `chore: add vitest for testing`

---

## Task 2: Write Tests (TDD)

**Files:**
- Create: `gateway/src/utils/formatTimeAgo.test.ts`

**Changes:**
- [ ] Create utils folder
- [ ] Write all test cases
- [ ] Run tests (expect failures)

**Code:**

`gateway/src/utils/formatTimeAgo.test.ts`:
```typescript
import { describe, it, expect } from 'vitest'
import { formatTimeAgo } from './formatTimeAgo'

describe('formatTimeAgo', () => {
  const now = Date.now()

  describe('basic time ranges', () => {
    it('returns "just now" for <10 seconds', () => {
      expect(formatTimeAgo(now - 5000)).toBe('just now')
    })

    it('returns seconds for <1 minute', () => {
      expect(formatTimeAgo(now - 30000)).toBe('30s ago')
    })

    it('returns minutes for <1 hour', () => {
      expect(formatTimeAgo(now - 300000)).toBe('5m ago')
      expect(formatTimeAgo(now - 1800000)).toBe('30m ago')
    })

    it('returns hours for <24 hours', () => {
      expect(formatTimeAgo(now - 7200000)).toBe('2h ago')
      expect(formatTimeAgo(now - 82800000)).toBe('23h ago')
    })

    it('returns days for <1 year', () => {
      expect(formatTimeAgo(now - 86400000)).toBe('1d ago')
      expect(formatTimeAgo(now - 604800000)).toBe('7d ago')
    })
  })

  describe('short format', () => {
    it('omits "ago" suffix', () => {
      expect(formatTimeAgo(now - 300000, { short: true })).toBe('5m')
      expect(formatTimeAgo(now - 7200000, { short: true })).toBe('2h')
    })
  })

  describe('locale switching', () => {
    it('supports Chinese', () => {
      expect(formatTimeAgo(now - 300000, { locale: 'zh' })).toBe('5分钟前')
      expect(formatTimeAgo(now - 7200000, { locale: 'zh' })).toBe('2小时前')
      expect(formatTimeAgo(now - 86400000, { locale: 'zh' })).toBe('1天前')
    })
  })

  describe('future dates', () => {
    it('returns "in X" format', () => {
      expect(formatTimeAgo(now + 60000)).toBe('in 1m')
      expect(formatTimeAgo(now + 7200000)).toBe('in 2h')
    })
  })

  describe('invalid input', () => {
    it('throws TypeError for invalid string', () => {
      expect(() => formatTimeAgo('invalid')).toThrow(TypeError)
    })

    it('throws TypeError for null', () => {
      expect(() => formatTimeAgo(null as unknown as string)).toThrow(TypeError)
    })

    it('throws TypeError for undefined', () => {
      expect(() => formatTimeAgo(undefined as unknown as string)).toThrow(TypeError)
    })
  })

  describe('very old dates', () => {
    it('shows formatted date for >1 year', () => {
      const twoYearsAgo = now - 63072000000 // 2 years in ms
      const result = formatTimeAgo(twoYearsAgo)
      // Should match date format like "Mar 4, 2024"
      expect(result).toMatch(/^[A-Z][a-z]{2} \d{1,2}, \d{4}$/)
    })
  })

  describe('input types', () => {
    it('accepts Date object', () => {
      expect(formatTimeAgo(new Date(now - 300000))).toBe('5m ago')
    })

    it('accepts number (timestamp)', () => {
      expect(formatTimeAgo(now - 300000)).toBe('5m ago')
    })

    it('accepts ISO string', () => {
      expect(formatTimeAgo(new Date(now - 300000).toISOString())).toBe('5m ago')
    })
  })
})
```

**Command:** `npm test -w gateway` (expect failures)

**Commit:** `test: add formatTimeAgo tests`

---

## Task 3: Implement formatTimeAgo

**Files:**
- Create: `gateway/src/utils/formatTimeAgo.ts`

**Changes:**
- [ ] Implement the function
- [ ] Run tests (expect pass)

**Code:**

`gateway/src/utils/formatTimeAgo.ts`:
```typescript
const SECOND = 1000
const MINUTE = 60 * SECOND
const HOUR = 60 * MINUTE
const DAY = 24 * HOUR
const YEAR = 365 * DAY

type TimeAgoOptions = {
  locale?: 'en' | 'zh'
  short?: boolean
}

const LOCALES = {
  en: {
    justNow: 'just now',
    ago: (value: string) => `${value} ago`,
    in: (value: string) => `in ${value}`,
    second: (n: number) => `${n}s`,
    minute: (n: number) => `${n}m`,
    hour: (n: number) => `${n}h`,
    day: (n: number) => `${n}d`,
  },
  zh: {
    justNow: '刚刚',
    ago: (value: string) => `${value}前`,
    in: (value: string) => `${value}后`,
    second: (n: number) => `${n}秒`,
    minute: (n: number) => `${n}分钟`,
    hour: (n: number) => `${n}小时`,
    day: (n: number) => `${n}天`,
  },
}

export function formatTimeAgo(
  input: Date | number | string,
  opts?: TimeAgoOptions
): string {
  const locale = opts?.locale ?? 'en'
  const short = opts?.short ?? false
  const t = LOCALES[locale]

  // Parse input to timestamp
  let timestamp: number
  if (input instanceof Date) {
    timestamp = input.getTime()
  } else if (typeof input === 'number') {
    timestamp = input
  } else if (typeof input === 'string') {
    const parsed = Date.parse(input)
    if (isNaN(parsed)) {
      throw new TypeError(`Invalid date string: ${input}`)
    }
    timestamp = parsed
  } else {
    throw new TypeError(`Invalid input type: ${typeof input}`)
  }

  if (isNaN(timestamp)) {
    throw new TypeError('Invalid date')
  }

  const now = Date.now()
  const diff = now - timestamp
  const absDiff = Math.abs(diff)
  const isFuture = diff < 0

  // Very old dates (>1 year) - show formatted date
  if (absDiff > YEAR) {
    return formatDate(timestamp, locale)
  }

  // Build the time value
  let value: string
  if (absDiff < 10 * SECOND) {
    if (short) return 'now'
    return t.justNow
  } else if (absDiff < MINUTE) {
    const seconds = Math.floor(absDiff / SECOND)
    value = t.second(seconds)
  } else if (absDiff < HOUR) {
    const minutes = Math.floor(absDiff / MINUTE)
    value = t.minute(minutes)
  } else if (absDiff < DAY) {
    const hours = Math.floor(absDiff / HOUR)
    value = t.hour(hours)
  } else {
    const days = Math.floor(absDiff / DAY)
    value = t.day(days)
  }

  // Apply suffix/prefix
  if (short) {
    return value
  }
  if (isFuture) {
    return t.in(value)
  }
  return t.ago(value)
}

function formatDate(timestamp: number, locale: 'en' | 'zh'): string {
  const date = new Date(timestamp)
  if (locale === 'zh') {
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}
```

**Command:** `npm test -w gateway` (expect pass)

**Commit:** `feat: add formatTimeAgo utility`

---

## Task 4: Add Index Export

**Files:**
- Create: `gateway/src/utils/index.ts`

**Changes:**
- [ ] Create barrel export
- [ ] Run tests (verify still pass)

**Code:**

`gateway/src/utils/index.ts`:
```typescript
export { formatTimeAgo } from './formatTimeAgo'
export type { TimeAgoOptions } from './formatTimeAgo'
```

**Command:** `npm test -w gateway`

**Commit:** `feat: add utils barrel export`

---

## Task 5: Verify Checkpoints

**Files:**
- None (verification only)

**Changes:**
- [ ] Run all tests
- [ ] Verify coverage
- [ ] Verify build passes

**Commands:**
```bash
npm test -w gateway
npm run build -w gateway
```

**Commit:** None (verification task)

---

## Verification Command

```bash
npm test -w gateway && npm run build -w gateway
```

Expected: All tests pass, build succeeds.
