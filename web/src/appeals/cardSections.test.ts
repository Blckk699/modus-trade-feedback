import { describe, expect, it } from 'vitest';
import { cardSections } from './cardSections';

describe('разделы карточки по access (истории 17, 19, 37)', () => {
  it('полный доступ: переписка, вложения, история, повторы, Битрикс24', () => {
    const s = cardSections({ access: 'full', participants_count: 1 });
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
    const s = cardSections({ access: 'participant', participants_count: 3 });
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
    expect(cardSections({ access: 'full', participants_count: 1 }).participantsCounter).toBe(false);
    expect(cardSections({ access: 'full', participants_count: 2 }).participantsCounter).toBe(true);
  });
});
