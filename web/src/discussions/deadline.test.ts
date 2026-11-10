import { describe, expect, it } from 'vitest';
import { deadlineFromDate, defaultDeadlineDate, todayDate } from './deadline';

describe('срок обсуждения (история 38)', () => {
  it('дата → конец рабочего дня UTC+5', () => {
    expect(deadlineFromDate('2026-11-13')).toBe('2026-11-13T18:00:00+05:00');
  });
  it('по умолчанию через 3 дня по UTC+5', () => {
    // 21:00 UTC 10 ноября — уже 11 ноября в UTC+5
    const now = new Date('2026-11-10T21:00:00Z');
    expect(todayDate(now)).toBe('2026-11-11');
    expect(defaultDeadlineDate(3, now)).toBe('2026-11-14');
  });
});
