import type { Schemas } from '../api/types';

/** Подписи статусов, типов, приоритетов и ролей приходят из /dictionaries; здесь — то, чего там нет. */

export const dueStateLabel: Record<Schemas['DueState'], string> = {
  on_time: 'В срок',
  due_soon: 'Срок скоро',
  overdue: 'Просрочено',
  answered: 'Ответ дан',
  no_deadline: 'Без срока',
};

export const historyKindLabel: Record<Schemas['HistoryEvent']['kind'], string> = {
  created: 'Обращение подано',
  assigned: 'Назначен ответственный',
  reassigned: 'Ответственный переназначен',
  status_changed: 'Статус изменён',
  deadline_set: 'Назначен срок',
  clarification_requested: 'Задан уточняющий вопрос',
  clarification_answered: 'Получен ответ на вопрос',
  escalated: 'Эскалация',
  merged: 'Склеено с другим обращением',
  participant_added: 'Добавлен участник',
  attachment_added: 'Добавлено вложение',
  attachment_removed: 'Вложение удалено',
  discussion_published: 'Вынесено на обсуждение',
  discussion_closed: 'Обсуждение завершено',
  bitrix_task_created: 'Создана задача в Битрикс24',
  field_changed: 'Изменено поле',
  nudged: 'Ответственному напомнили',
};

/** Заголовок события истории: общий вид события уточняется по тому, что в нём записано. */
export function historyTitle(ev: Pick<Schemas['HistoryEvent'], 'kind' | 'field' | 'new_value'>): string {
  if (ev.kind === 'assigned' && !ev.new_value) return 'Ответственный не назначен';
  if (ev.kind === 'field_changed' && ev.field === 'category') return 'Изменена категория';
  return historyKindLabel[ev.kind] ?? ev.kind;
}

export const closedReasonLabel: Record<Schemas['ClosedReason'], string> = {
  feedback_accepted: 'Отзыв принят',
  merged: 'Присоединено к другому обращению',
};
