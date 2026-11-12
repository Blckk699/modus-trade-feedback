import { describe, expect, it } from 'vitest';
import type { Schemas } from '../api/types';
import { historyDays, readHistoryOpen, writeHistoryOpen } from './history';

const ev = (id: number, created_at: string): Schemas['HistoryEvent'] =>
  ({ id, kind: 'created', actor: null, field: null, old_value: null, new_value: null, comment: null, created_at }) as Schemas['HistoryEvent'];

describe('история обращения', () => {
  it('события делятся на дни по UTC+5 и сохраняют порядок', () => {
    const days = historyDays([ev(1, '2026-11-12T22:36:00+05:00'), ev(2, '2026-11-12T22:38:00+05:00'), ev(3, '2026-11-12T20:30:00Z')]);
    expect(days.map((d) => [d.key, d.events.map((e) => e.id)])).toEqual([
      ['2026-11-12', [1, 2]],
      ['2026-11-13', [3]],
    ]);
    expect(historyDays([])).toEqual([]);
  });

  it('по умолчанию свёрнута, выбор запоминается', () => {
    const data = new Map<string, string>();
    const store = () => ({ getItem: (k: string) => data.get(k) ?? null, setItem: (k: string, v: string) => void data.set(k, v) });
    expect(readHistoryOpen(store)).toBe(false);
    writeHistoryOpen(true, store);
    expect(readHistoryOpen(store)).toBe(true);
    writeHistoryOpen(false, store);
    expect(readHistoryOpen(store)).toBe(false);
  });

  it('хранилище бросает при чтении, записи или самом обращении к нему — история свёрнута, ошибок нет', () => {
    const broken = () => ({
      getItem: (): string | null => {
        throw new Error('нет доступа');
      },
      setItem: () => {
        throw new Error('нет доступа');
      },
    });
    const forbidden = () => {
      throw new Error('SecurityError');
    };
    expect(readHistoryOpen(broken)).toBe(false);
    expect(() => writeHistoryOpen(true, broken)).not.toThrow();
    expect(readHistoryOpen(forbidden)).toBe(false);
    expect(() => writeHistoryOpen(true, forbidden)).not.toThrow();
    expect(readHistoryOpen(() => null)).toBe(false);
  });
});
