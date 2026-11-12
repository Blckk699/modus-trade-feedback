import { describe, expect, it } from 'vitest';
import { buildBrief, greeting, type BriefInput } from './homeBrief';

const empty: BriefInput = {
  assignedOpen: null,
  assignedOverdue: 0,
  awaitingMe: 0,
  unassigned: null,
  accessRequests: null,
  newToday: null,
  overdueTotal: null,
  scope: null,
  openDiscussions: 0,
};

describe('главное на сейчас', () => {
  it('ответственный: сколько в работе и сколько просрочено, с верным склонением', () => {
    expect(buildBrief({ ...empty, assignedOpen: 3, assignedOverdue: 1 })[0]).toBe('У вас 3 обращения в работе, 1 просрочено.');
    expect(buildBrief({ ...empty, assignedOpen: 5, assignedOverdue: 2 })[0]).toBe('У вас 5 обращений в работе, 2 просрочены.');
    expect(buildBrief({ ...empty, assignedOpen: 1 })[0]).toBe('У вас 1 обращение в работе.');
  });

  it('автор: вопрос ответственного важнее обсуждений', () => {
    expect(buildBrief({ ...empty, awaitingMe: 1, openDiscussions: 2 })).toEqual([
      'Вас ждёт вопрос по обращению.',
      'Идут 2 обсуждения, можно проголосовать.',
    ]);
    expect(buildBrief({ ...empty, awaitingMe: 2 })[0]).toBe('Вас ждут вопросы по 2 обращениям.');
  });

  it('администратор: нераспределённые и заявки на доступ', () => {
    expect(buildBrief({ ...empty, unassigned: 2, accessRequests: 1 })).toEqual([
      '2 обращения ждут ответственного.',
      '1 заявка на доступ ждёт решения.',
    ]);
  });

  it('руководитель и собственник: строка из сводки по своему охвату', () => {
    expect(buildBrief({ ...empty, scope: 'company', newToday: 1, overdueTotal: 3 })[0]).toBe('В компании: 1 новое за сутки, 3 просрочены.');
    expect(buildBrief({ ...empty, scope: 'department', newToday: 0, overdueTotal: 5 })[0]).toBe('В подразделении: 5 просрочено.');
  });

  it('не больше трёх фраз', () => {
    const all = buildBrief({
      assignedOpen: 2,
      assignedOverdue: 0,
      awaitingMe: 1,
      unassigned: 4,
      accessRequests: 2,
      newToday: 1,
      overdueTotal: 1,
      scope: 'company',
      openDiscussions: 1,
    });
    expect(all).toHaveLength(3);
  });

  it('когда срочного нет — так и говорит и зовёт написать', () => {
    expect(buildBrief(empty)[0]).toBe('Срочного нет.');
    expect(buildBrief({ ...empty, assignedOpen: 0, unassigned: 0, accessRequests: 0 })).toHaveLength(2);
  });
});

describe('приветствие', () => {
  it('подбирается по времени суток и берёт имя', () => {
    expect(greeting('Марат Сейткали', new Date(2026, 10, 12, 9))).toBe('Доброе утро, Марат');
    expect(greeting('Анна Ли', new Date(2026, 10, 12, 14))).toBe('Добрый день, Анна');
    expect(greeting('Ержан Касымов', new Date(2026, 10, 12, 21))).toBe('Добрый вечер, Ержан');
    expect(greeting('', new Date(2026, 10, 12, 2))).toBe('Доброй ночи');
  });
});
