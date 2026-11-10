import { describe, expect, it } from 'vitest';
import { formatHours } from './DigestPage';

describe('среднее время первого ответа (история 56)', () => {
  it('меньше суток — в часах', () => {
    expect(formatHours(18.5)).toBe('18,5 ч');
    expect(formatHours(20)).toBe('20 ч');
  });
  it('сутки и больше — в днях', () => {
    expect(formatHours(36)).toBe('1,5 д');
    expect(formatHours(48)).toBe('2 д');
  });
});
