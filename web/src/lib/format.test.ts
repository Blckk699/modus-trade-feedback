import { describe, expect, it } from 'vitest';
import { dayKey, formatChatDay, formatDay, formatTime } from './format';

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

describe('дни и время в переписке', () => {
  const now = new Date('2026-11-12T10:00:00+05:00');

  it('сегодня и вчера названы словами', () => {
    expect(formatChatDay('2026-11-12T00:05:00+05:00', now)).toBe('Сегодня');
    expect(formatChatDay('2026-11-11T23:55:00+05:00', now)).toBe('Вчера');
  });

  it('раньше — число и месяц, прошлый год — с годом', () => {
    expect(formatChatDay('2026-11-09T14:04:00+05:00', now)).toBe('9 ноября');
    expect(formatChatDay('2025-12-30T09:00:00+05:00', now)).toBe('30 декабря 2025 г.');
  });

  it('день и время считаются по UTC+5', () => {
    expect(dayKey('2026-11-11T20:30:00Z')).toBe('2026-11-12');
    expect(formatTime('2026-11-11T20:30:00Z')).toBe('01:30');
  });
});
