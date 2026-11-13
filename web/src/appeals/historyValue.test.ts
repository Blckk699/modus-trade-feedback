import { describe, expect, it } from 'vitest';
import { formatDateTime } from '../lib/format';
import { historyValue } from './historyValue';

const labels = {
  statusLabel: (c: string) => ({ new: 'Новое', in_review: 'На рассмотрении' })[c] ?? c,
  typeLabel: (c: string) => ({ problem: 'Проблема' })[c] ?? c,
  priorityLabel: (c: string) => ({ high: 'Высокий' })[c] ?? c,
};

describe('значения в истории обращения (история 11)', () => {
  it('срок из deadline_set показывается датой, а не строкой ISO', () => {
    const iso = '2026-11-18T09:55:15.058981+05:00';
    const out = historyValue('first_response_due_at', iso, labels);
    expect(out).toBe(formatDateTime(iso));
    expect(out).not.toContain('T09');
  });

  it('дата без поля тоже форматируется', () => {
    expect(historyValue(null, '2026-11-18T18:00:00+05:00', labels)).toBe(formatDateTime('2026-11-18T18:00:00+05:00'));
  });

  it('коды статуса, типа и приоритета — подписями', () => {
    expect(historyValue('status', 'in_review', labels)).toBe('На рассмотрении');
    expect(historyValue('type', 'problem', labels)).toBe('Проблема');
    expect(historyValue('priority', 'high', labels)).toBe('Высокий');
  });

  it('обычный текст и пустое значение — как есть', () => {
    expect(historyValue('assignee', 'Олжас Мукашев', labels)).toBe('Олжас Мукашев');
    expect(historyValue('assignee', null, labels)).toBeNull();
    expect(historyValue('comment', '2026 год', labels)).toBe('2026 год');
  });
});
