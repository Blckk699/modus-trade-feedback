import type { Schemas } from '../api/types';

/**
 * События живых обновлений (B-24, контракт `/api/v1/ws`). В событии только идентификаторы и признак
 * того, что поменялось; данные клиент перезапрашивает обычным API.
 */
export type LiveEvent = Schemas['WsEvent'];
export type ServerMessage = Schemas['WsReady'] | Schemas['WsPong'] | LiveEvent;

/** Что перезапросить. Экраны подписываются на темы и тихо перечитывают свои данные. */
export type Topic =
  | 'appeals' // списки обращений и «Сегодня»
  | `appeal:${number}` // открытая карточка
  | `messages:${number}` // переписка обращения
  | 'notifications' // список под колокольчиком
  | 'discussions' // лента
  | `discussion:${number}`; // открытое обсуждение

export interface Reaction {
  topics: Topic[];
  /** Новое значение счётчика непрочитанного, если событие его принесло. */
  unreadCount: number | null;
  /** Пришло уведомление: показать его тостом и дать короткий звук. */
  notificationId: number | null;
}

const NONE: Reaction = { topics: [], unreadCount: null, notificationId: null };

/** Разобрать кадр из сокета. Незнакомое и битое — null: список событий будет расширяться. */
export function parseMessage(raw: unknown): ServerMessage | null {
  let data: unknown = raw;
  if (typeof raw === 'string') {
    try {
      data = JSON.parse(raw);
    } catch {
      return null;
    }
  }
  if (!data || typeof data !== 'object') return null;
  const e = data as Record<string, unknown>;
  const id = (v: unknown) => typeof v === 'number' && Number.isInteger(v) && v > 0;
  const count = (v: unknown) => typeof v === 'number' && Number.isInteger(v) && v >= 0;
  switch (e.type) {
    case 'ready':
      return count(e.unread_count) ? (e as ServerMessage) : null;
    case 'pong':
      return e as ServerMessage;
    case 'appeal.created':
    case 'appeal.updated':
    case 'message.created':
      return id(e.appeal_id) ? (e as ServerMessage) : null;
    case 'discussion.updated':
      return id(e.discussion_id) ? (e as ServerMessage) : null;
    case 'notification.created':
      return id(e.notification_id) && count(e.unread_count) ? (e as ServerMessage) : null;
    default:
      return null;
  }
}

/**
 * Что делать по событию. Свои действия сервер тоже присылает событием и автора не называет, поэтому
 * `appeal.*`, `message.created` и `discussion.updated` только обновляют данные. Тост и звук — по
 * `notification.created`: уведомление создаётся только получателю, о собственных действиях его нет.
 */
export function react(event: LiveEvent): Reaction {
  switch (event.type) {
    case 'appeal.created':
    case 'appeal.updated':
      return { ...NONE, topics: ['appeals', `appeal:${event.appeal_id}`] };
    case 'message.created':
      return { ...NONE, topics: ['appeals', `messages:${event.appeal_id}`] };
    case 'notification.created':
      return { topics: ['notifications'], unreadCount: event.unread_count, notificationId: event.notification_id };
    case 'discussion.updated':
      return { ...NONE, topics: ['discussions', `discussion:${event.discussion_id}`] };
  }
}

export type CloseAction = 'relogin' | 'stop' | 'retry';

/**
 * Что делать после закрытия сокета. 4401 — сессии больше нет (истекла, выход, смена или сброс пароля,
 * доступ отключён): переподключаться с тем же токеном нельзя, ведём на вход. 4429 — сервер закрыл
 * самое старое из одиннадцати соединений, 4400 — ошибка в самом клиенте: повтор ничего не даст.
 */
export function closeAction(code: number): CloseAction {
  if (code === 4401) return 'relogin';
  if (code === 4429 || code === 4400) return 'stop';
  return 'retry';
}

/** Пауза перед переподключением: 1, 2, 4, 8… секунд, не больше 30. */
export function retryDelay(attempt: number): number {
  return Math.min(30_000, 1000 * 2 ** Math.max(0, attempt));
}

/** Пинг раз в 30 секунд, как советует контракт. */
export const PING_MS = 30_000;

/** Звук не чаще раза в четыре секунды. */
export const SOUND_GAP_MS = 4000;
export const maySound = (lastAt: number, now: number) => now - lastAt >= SOUND_GAP_MS;
