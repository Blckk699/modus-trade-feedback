import { describe, expect, it } from 'vitest';
import { formatDay } from './format';

describe('короткая дата в списках', () => {
  const now = new Date('2026-11-12T10:00:00+05:00');

  it('в этом году — без года', () => {
    expect(formatDay('2026-11-05T13:41:00+05:00', now)).toBe('5 нояб.');
  });

  it('прошлый год — с годом', () => {
    expect(formatDay('2025-12-30T09:00:00+05:00', now)).toBe('30 дек. 2025 г.');
  });

  it('день считается по UTC+5', () => {
    expect(formatDay('2026-11-11T20:30:00Z', now)).toBe('12 нояб.');
  });

  it('нет даты — прочерк', () => {
    expect(formatDay(null, now)).toBe('—');
  });
});
