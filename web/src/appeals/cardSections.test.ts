import { describe, expect, it } from 'vitest';
import { canReadMessages, cardSections, needsAssignee } from './cardSections';

describe('разделы карточки по access (истории 17, 19, 37)', () => {
  it('полный доступ: переписка, вложения, история, повторы, Битрикс24', () => {
    const s = cardSections({ access: 'full', participants_count: 1, viewer_relations: ['assignee'] });
    expect(s).toMatchObject({
      participantNotice: false,
      messages: true,
      attachments: true,
      history: true,
      duplicates: true,
      bitrix: true,
    });
  });

  it('участник склеенного повтора не видит переписку, вложения, историю и обработку', () => {
    const s = cardSections({ access: 'participant', participants_count: 3, viewer_relations: ['participant'] });
    expect(s).toEqual({
      participantNotice: true,
      participantsCounter: false,
      duplicates: false,
      bitrix: false,
      messages: false,
      attachments: false,
      history: false,
    });
  });

  it('счётчик обратившихся — только когда сообщили двое и больше', () => {
    expect(cardSections({ access: 'full', participants_count: 1, viewer_relations: ['author'] }).participantsCounter).toBe(false);
    expect(cardSections({ access: 'full', participants_count: 2, viewer_relations: ['author'] }).participantsCounter).toBe(true);
  });
});

describe('назначение ответственного в карточке (история 70)', () => {
  const marat = { id: 3, full_name: 'Олжас Мукашев', role: 'head' as const, department: { id: 2, name: 'Закупки' } };

  it('без ответственного и с правом reassign — показываем блок назначения', () => {
    expect(needsAssignee({ assignee: null, allowed_actions: ['reassign'] })).toBe(true);
  });

  it('ответственный уже есть — блока нет, остаётся «Переназначить»', () => {
    expect(needsAssignee({ assignee: marat, allowed_actions: ['reassign'] })).toBe(false);
  });

  it('без права reassign блока нет, даже если ответственного нет', () => {
    expect(needsAssignee({ assignee: null, allowed_actions: [] })).toBe(false);
  });
});

describe('приватная переписка — только участникам (SPEC: администратор в ней не участвует)', () => {
  it.each([['author'], ['assignee'], ['department_head'], ['owner']] as const)('%s видит переписку', (relation) => {
    expect(canReadMessages({ viewer_relations: [relation] })).toBe(true);
    expect(cardSections({ access: 'full', participants_count: 1, viewer_relations: [relation] }).messages).toBe(true);
  });

  it('администратор в чужом обращении: переписки нет, остальные разделы на месте', () => {
    const s = cardSections({ access: 'full', participants_count: 1, viewer_relations: ['admin'] });
    expect(s).toMatchObject({ messages: false, attachments: true, history: true, duplicates: true, bitrix: true });
  });

  it('администратор — автор обращения: свою переписку видит', () => {
    expect(canReadMessages({ viewer_relations: ['author', 'admin'] })).toBe(true);
  });

  it('участник повтора и зритель без отношения к обращению переписку не видят', () => {
    expect(canReadMessages({ viewer_relations: ['participant'] })).toBe(false);
    expect(canReadMessages({ viewer_relations: [] })).toBe(false);
  });
});
