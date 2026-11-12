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
};

export const closedReasonLabel: Record<Schemas['ClosedReason'], string> = {
  feedback_accepted: 'Отзыв принят',
  merged: 'Присоединено к другому обращению',
};
