import type { Schemas } from '../api/types';

type Appeal = Schemas['Appeal'];

export interface CardSections {
  /** Пояснение «ваше обращение присоединили к этому как повтор». */
  participantNotice: boolean;
  /** «Об этом сказали N человек». */
  participantsCounter: boolean;
  /** Подсказки о повторах и Битрикс24. */
  duplicates: boolean;
  bitrix: boolean;
  /** Приватная переписка, вложения, история. */
  messages: boolean;
  attachments: boolean;
  history: boolean;
}

/**
 * Какие разделы карточки показывать (истории 17, 19, 37). Участник склеенного повтора (access=participant)
 * видит статус, срок и итог основного обращения, но не его переписку, вложения, историю и инструменты обработки:
 * бэкенд и так отдаст там 403, клиент просто не рисует эти блоки.
 */
export function cardSections(a: Pick<Appeal, 'access' | 'participants_count'>): CardSections {
  const full = a.access !== 'participant';
  return {
    participantNotice: !full,
    participantsCounter: full && a.participants_count > 1,
    duplicates: full,
    bitrix: full,
    messages: full,
    attachments: full,
    history: full,
  };
}
