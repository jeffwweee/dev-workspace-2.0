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
      // Use 90 seconds and 2.5 hours to avoid race condition with Date.now()
      expect(formatTimeAgo(now + 90000)).toBe('in 1m')
      expect(formatTimeAgo(now + 9000000)).toBe('in 2h')
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
