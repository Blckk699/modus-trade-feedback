import { describe, expect, it } from 'vitest';
import { timeLeftLabel } from './timeLeft';

const now = new Date('2026-11-10T12:00:00+05:00');

describe('оставшееся время до срока (история 27)', () => {
  it('часы и минуты до срока', () => {
    expect(timeLeftLabel('2026-11-10T14:30:00+05:00', now)).toBe('осталось 2 ч 30 мин');
  });
  it('дни до срока', () => {
    expect(timeLeftLabel('2026-11-12T15:00:00+05:00', now)).toBe('осталось 2 д 3 ч');
  });
  it('просрочка', () => {
    expect(timeLeftLabel('2026-11-09T18:00:00+05:00', now)).toBe('просрочено на 18 ч 0 мин');
  });
});
