import { describe, expect, it } from 'vitest';
import { dueExplanation, whoWhen } from './whoWhen';

const base = {
  type: 'problem' as const,
  status: 'new' as const,
  assignee: null,
  category: null,
  first_response_due_at: null,
  first_response_at: null,
  due_state: 'no_deadline' as const,
  escalation_level: 0,
};
const person = { id: 3, full_name: 'Марат Сейткали' } as never;
const category = { id: 9, name: 'Закупки' } as never;

describe('кто и когда для автора', () => {
  it('без ответственного и категории — администратор, срок появится вместе с ответственным', () => {
    const r = whoWhen(base, false);
    expect(r.who).toBe('Администратор выберет ответственного: категорию не удалось определить.');
    expect(r.when).toMatch(/^Срок первого ответа появится вместе с ответственным/);
    expect(r.steps).toHaveLength(3);
    expect(r.where).toMatch(/Привяжите Telegram/);
  });

  it('категория без ответственного — названа', () => {
    expect(whoWhen({ ...base, category }, true).who).toBe('Администратор выберет ответственного: у категории «Закупки» сейчас его нет.');
  });

  it('назначен — имя и категория, срок, Telegram привязан', () => {
    const r = whoWhen({ ...base, assignee: person, category, first_response_due_at: '2026-11-17T18:00:00+05:00' }, true);
    expect(r.who).toBe('Марат Сейткали, ответственный за «Закупки»');
    expect(r.when).toMatch(/^Первый ответ — до /);
    expect(r.where).toMatch(/^Ответы и смена статуса придут в Telegram/);
  });

  it('срок прошёл — так и пишем, с текущим шагом эскалации', () => {
    const r = whoWhen({ ...base, first_response_due_at: '2026-11-10T13:41:00+05:00', due_state: 'overdue', escalation_level: 2 }, true);
    expect(r.when).toMatch(/^Срок первого ответа прошёл .*руководитель подразделения уведомлён\.$/);
  });

  it('ответ уже дан — пишем когда', () => {
    expect(whoWhen({ ...base, first_response_at: '2026-11-13T10:00:00+05:00' }, true).when).toMatch(/^Первый ответ дан /);
  });

  it('отзыв — без срока и без шагов', () => {
    const r = whoWhen({ ...base, type: 'praise' }, true);
    expect(r.when).toBe('Без срока: отзыв передадут, ответ не обязателен.');
    expect(r.steps).toEqual([]);
  });

  it('у предложения в решении есть обсуждение', () => {
    expect(whoWhen({ ...base, type: 'suggestion' }, true).steps[2]).toMatch(/общее обсуждение/);
  });
});

describe('просрочка', () => {
  it('правило одно, шаг — по уровню эскалации', () => {
    expect(dueExplanation(0)).toMatchObject({ now: null });
    expect(dueExplanation(0).rule).toMatch(/только на первый ответ/);
    expect(dueExplanation(1).now).toMatch(/напоминание/);
    expect(dueExplanation(2).now).toMatch(/руководитель/);
    expect(dueExplanation(3).now).toMatch(/Зависло/);
  });
});
