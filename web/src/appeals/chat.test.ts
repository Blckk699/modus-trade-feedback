import { describe, expect, it } from 'vitest';
import { chatDays, endsRun, startsRun, type Message } from './chat';

const user = (id: number, full_name: string) => ({ id, full_name, role: 'employee' as const, department: null });
const msg = (id: number, authorId: number, created_at: string): Message => ({
  id,
  appeal_id: 1,
  author: user(authorId, authorId === 4 ? 'Карина Шаймерденова' : 'Олжас Мукашев'),
  text: `Сообщение ${id}`,
  is_clarification_question: false,
  created_at,
});

describe('переписка по дням', () => {
  it('делит сообщения на дни по UTC+5 и сохраняет порядок', () => {
    const days = chatDays([
      msg(1, 3, '2026-11-09T14:04:00+05:00'),
      msg(2, 4, '2026-11-09T14:06:00+05:00'),
      // 20:30 UTC 11 ноября — уже 12 ноября по UTC+5
      msg(3, 3, '2026-11-11T20:30:00Z'),
    ]);
    expect(days.map((d) => [d.key, d.messages.map((m) => m.id)])).toEqual([
      ['2026-11-09', [1, 2]],
      ['2026-11-12', [3]],
    ]);
  });

  it('пустая переписка — дней нет', () => {
    expect(chatDays([])).toEqual([]);
  });

  it('имя ставится у первого сообщения и когда автор сменился', () => {
    const list = [msg(1, 3, '2026-11-09T14:04:00+05:00'), msg(2, 3, '2026-11-09T14:05:00+05:00'), msg(3, 4, '2026-11-09T14:06:00+05:00')];
    expect(list.map((_, i) => startsRun(list, i))).toEqual([true, false, true]);
    // аватар — у последнего сообщения в ряду
    expect(list.map((_, i) => endsRun(list, i))).toEqual([false, true, true]);
  });
});
