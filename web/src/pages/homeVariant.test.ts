import { describe, expect, it } from 'vitest';
import type { Schemas } from '../api/types';
import { attention, homeVariant, setupGaps, variantScope } from './homeVariant';

const stuck = (id: number, days: number, level: number) =>
  ({ appeal: { id, number: `A-${id}`, summary: null, status: 'new', type: 'problem' }, assignee: null, days_overdue: days, escalation_level: level }) as Schemas['StuckAppeal'];
const user = { id: 1 } as Schemas['UserBrief'];

describe('версия экрана «Сегодня»', () => {
  it('собственник, руководитель и администратор — по роли', () => {
    expect((['owner', 'head', 'admin'] as const).map((r) => homeVariant(r, 3))).toEqual(['owner', 'head', 'admin']);
  });

  it('сотрудник с назначенными обращениями — ответственный, без них — автор', () => {
    expect(homeVariant('employee', 2)).toBe('assignee');
    expect(homeVariant('employee', 0)).toBe('author');
  });

  it('подпись охвата', () => {
    expect(variantScope('owner', null)).toBe('Вся компания');
    expect(variantScope('head', 'Закупки')).toBe('Подразделение «Закупки»');
    expect(variantScope('head', null)).toBe('Ваше подразделение');
  });
});

describe('требуют внимания', () => {
  it('зависшие и просроченные без повторов, сначала выше эскалация, затем больше просрочка', () => {
    const list = attention({ stuck: [stuck(1, 5, 3)], overdue: [stuck(1, 5, 3), stuck(2, 9, 1), stuck(3, 2, 1), stuck(4, 1, 2)] });
    expect(list.map((s) => s.appeal.id)).toEqual([1, 4, 2, 3]);
  });

  it('пусто — пустой список', () => {
    expect(attention({ stuck: [], overdue: [] })).toEqual([]);
  });
});

describe('пробелы в настройках', () => {
  it('считает только действующие категории; заместитель важен, когда есть ответственный', () => {
    const cats = [
      { responsible: null, deputy: null, is_active: true },
      { responsible: null, deputy: null, is_active: false },
      { responsible: user, deputy: null, is_active: true },
      { responsible: user, deputy: user, is_active: true },
    ];
    expect(setupGaps(cats, [{ head: null }, { head: user }])).toEqual({ noResponsible: 1, noDeputy: 1, noHead: 1 });
  });
});
