import { describe, expect, it } from 'vitest';
import { buildTimeline, OVERDUE_ZONE, startOfDay } from './dueTimeline';

// 12 ноября 2026, 14:00 по UTC+5
const now = new Date('2026-11-12T14:00:00+05:00');
const item = (id: number, dueAt: string) => ({ id, number: `A-${id}`, dueAt });

describe('шкала сроков', () => {
  it('день начинается в полночь по UTC+5', () => {
    expect(new Date(startOfDay(now)).toISOString()).toBe('2026-11-11T19:00:00.000Z');
  });

  it('семь дней, «сейчас» внутри первого', () => {
    const t = buildTimeline([], now);
    expect(t.days).toHaveLength(7);
    expect(t.days[0].x).toBe(OVERDUE_ZONE);
    expect(t.nowX).toBeGreaterThan(t.days[0].x);
    expect(t.nowX).toBeLessThan(t.days[1].x);
  });

  it('просроченное встаёт в левую зону, будущее — правее «сейчас»', () => {
    const t = buildTimeline([item(1, '2026-11-10T13:41:00+05:00'), item(2, '2026-11-14T12:00:00+05:00')], now);
    const [late, future] = t.chips;
    expect(late.x).toBeLessThan(OVERDUE_ZONE);
    expect(future.x).toBeGreaterThan(t.nowX);
    expect(t.hidden).toBe(0);
  });

  it('близкие сроки расходятся по дорожкам, лишние считаются скрытыми', () => {
    const same = '2026-11-13T10:00:00+05:00';
    const t = buildTimeline([item(1, same), item(2, same), item(3, same), item(4, same)], now);
    expect(t.chips.map((c) => c.lane)).toEqual([0, 1, 2]);
    expect(t.hidden).toBe(1);
  });

  it('срок дальше недели на шкалу не попадает', () => {
    const t = buildTimeline([item(1, '2026-11-25T10:00:00+05:00')], now);
    expect(t.chips).toHaveLength(0);
    expect(t.hidden).toBe(1);
  });
});
