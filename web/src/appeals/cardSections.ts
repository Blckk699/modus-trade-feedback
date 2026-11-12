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
 * Обращение без ответственного, и зрителю разрешено назначить (история 70): в карточке показываем
 * блок назначения, а кнопку «Переназначить» в нижней панели убираем — переназначать пока некого.
 */
export function needsAssignee(a: Pick<Appeal, 'assignee' | 'allowed_actions'>): boolean {
  return !a.assignee && a.allowed_actions.includes('reassign');
}

/** Кому бэкенд отдаёт приватную переписку: автор, ответственный, руководитель подразделения, собственник. */
const MESSAGE_READERS: Appeal['viewer_relations'] = ['author', 'assignee', 'department_head', 'owner'];

/**
 * Приватная переписка видна только её участникам (SPEC: «Администратор видит все обращения, но не участвует
 * в приватной переписке»). Остальным GET /appeals/{id}/messages отвечает 403 — не запрашиваем и блок не рисуем.
 */
export function canReadMessages(a: Pick<Appeal, 'viewer_relations'>): boolean {
  return a.viewer_relations.some((r) => MESSAGE_READERS.includes(r));
}

/**
 * Какие разделы карточки показывать (истории 17, 19, 37). Участник склеенного повтора (access=participant)
 * видит статус, срок и итог основного обращения, но не его переписку, вложения, историю и инструменты обработки:
 * бэкенд и так отдаст там 403, клиент просто не рисует эти блоки.
 */
export function cardSections(a: Pick<Appeal, 'access' | 'participants_count' | 'viewer_relations'>): CardSections {
  const full = a.access !== 'participant';
  return {
    participantNotice: !full,
    participantsCounter: full && a.participants_count > 1,
    duplicates: full,
    bitrix: full,
    messages: full && canReadMessages(a),
    attachments: full,
    history: full,
  };
}
