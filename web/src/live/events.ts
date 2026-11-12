/**
 * События живых обновлений (B-24). Событие несёт минимум: что изменилось и id; данные клиент
 * перезапрашивает обычным API. До контракта форма собрана по описанию задачи #205.
 */
export type LiveEvent =
  | { type: 'appeal.created' | 'appeal.updated'; appeal_id: number; number?: string; status?: string; actor_id?: number | null }
  | { type: 'message.created'; appeal_id: number; number?: string; actor_id?: number | null }
  | { type: 'notification.created'; unread_count?: number; appeal_id?: number | null; actor_id?: number | null }
  | { type: 'discussion.updated'; discussion_id: number; actor_id?: number | null };

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
  /** Счётчик стоит перезапросить: событие могло его изменить, а значения не принесло. */
  refreshUnread: boolean;
  /** Тост с переходом к обращению. */
  toast: { text: string; to: string } | null;
  sound: boolean;
}

export interface Viewer {
  id: number;
  /** Обращение, чей чат сейчас открыт: о сообщениях в нём сообщать незачем. */
  openChatAppealId: number | null;
}

const NONE: Reaction = { topics: [], unreadCount: null, refreshUnread: false, toast: null, sound: false };

/** Разобрать текст из сокета. Незнакомое и битое — null: новая версия сервера не должна ломать клиент. */
export function parseEvent(raw: unknown): LiveEvent | null {
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
  switch (e.type) {
    case 'appeal.created':
    case 'appeal.updated':
    case 'message.created':
      return id(e.appeal_id) ? (e as LiveEvent) : null;
    case 'discussion.updated':
      return id(e.discussion_id) ? (e as LiveEvent) : null;
    case 'notification.created':
      return e as LiveEvent;
    default:
      return null;
  }
}

/**
 * Что делать по событию. Свои действия (actor_id — сам зритель) данные обновляют, но не шумят:
 * ни тоста, ни звука. Сообщение в чате, который сейчас открыт, тоже без тоста.
 */
export function react(event: LiveEvent, viewer: Viewer): Reaction {
  const own = event.actor_id != null && event.actor_id === viewer.id;
  switch (event.type) {
    case 'appeal.created':
    case 'appeal.updated':
      return { ...NONE, topics: ['appeals', `appeal:${event.appeal_id}`], refreshUnread: !own };
    case 'message.created': {
      const quiet = own || viewer.openChatAppealId === event.appeal_id;
      return {
        ...NONE,
        topics: ['appeals', `messages:${event.appeal_id}`],
        refreshUnread: !own,
        toast: quiet
          ? null
          : { text: event.number ? `Новое сообщение по ${event.number}` : 'Новое сообщение по обращению', to: `/appeals/${event.appeal_id}` },
        sound: !own,
      };
    }
    case 'notification.created':
      return {
        ...NONE,
        topics: ['notifications', 'appeals'],
        unreadCount: typeof event.unread_count === 'number' ? event.unread_count : null,
        refreshUnread: typeof event.unread_count !== 'number',
        sound: !own,
      };
    case 'discussion.updated':
      return { ...NONE, topics: ['discussions', `discussion:${event.discussion_id}`] };
  }
}

/** Пауза перед переподключением: 1, 2, 4, 8… секунд, не больше 30. */
export function retryDelay(attempt: number): number {
  return Math.min(30_000, 1000 * 2 ** Math.max(0, attempt));
}

/** Звук не чаще раза в четыре секунды. */
export const SOUND_GAP_MS = 4000;
export const maySound = (lastAt: number, now: number) => now - lastAt >= SOUND_GAP_MS;
