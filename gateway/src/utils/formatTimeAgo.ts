const SECOND = 1000
const MINUTE = 60 * SECOND
const HOUR = 60 * MINUTE
const DAY = 24 * HOUR
const YEAR = 365 * DAY

export type TimeAgoOptions = {
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
