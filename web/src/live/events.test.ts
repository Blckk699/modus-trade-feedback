import { describe, expect, it } from 'vitest';
import { closeAction, maySound, parseMessage, react, retryDelay, SOUND_GAP_MS } from './events';

describe('разбор кадров сокета', () => {
  it('ready, pong и события контракта проходят, строка JSON разбирается', () => {
    const ready = { type: 'ready', user_id: 4, unread_count: 2, session_expires_at: '2026-12-12T09:00:00+05:00' };
    expect(parseMessage(JSON.stringify(ready))).toEqual(ready);
    expect(parseMessage({ type: 'pong' })).toEqual({ type: 'pong' });
    expect(parseMessage('{"type":"message.created","appeal_id":42,"message_id":318}')).toEqual({ type: 'message.created', appeal_id: 42, message_id: 318 });
    expect(parseMessage({ type: 'discussion.updated', discussion_id: 6, changed: 'vote' })).toMatchObject({ discussion_id: 6 });
    expect(parseMessage({ type: 'notification.created', notification_id: 905, unread_count: 0 })).toMatchObject({ unread_count: 0 });
  });

  it('незнакомое, битое и без обязательных id — отбрасывается', () => {
    expect(parseMessage('не json')).toBeNull();
    expect(parseMessage({ type: 'appeal.archived', appeal_id: 1 })).toBeNull();
    expect(parseMessage({ type: 'appeal.updated' })).toBeNull();
    expect(parseMessage({ type: 'appeal.updated', appeal_id: '28' })).toBeNull();
    expect(parseMessage({ type: 'notification.created', unread_count: 3 })).toBeNull();
    expect(parseMessage({ type: 'ready', user_id: 4 })).toBeNull();
    expect(parseMessage(null)).toBeNull();
  });
});

describe('что делать по событию', () => {
  it('обращение: карточка и списки, без счётчика и уведомления', () => {
    expect(react({ type: 'appeal.updated', appeal_id: 7, number: 'MT-000007', status: 'in_progress', changed: ['status_changed'] })).toEqual({
      topics: ['appeals', 'appeal:7'],
      unreadCount: null,
      notificationId: null,
    });
    expect(react({ type: 'appeal.created', appeal_id: 8, number: 'MT-000008', status: 'new' }).topics).toEqual(['appeals', 'appeal:8']);
  });

  it('сообщение: переписка и списки; тоста и звука нет — своё сообщение сервер тоже присылает', () => {
    expect(react({ type: 'message.created', appeal_id: 28, message_id: 318 })).toEqual({
      topics: ['appeals', 'messages:28'],
      unreadCount: null,
      notificationId: null,
    });
  });

  it('уведомление: счётчик из события и id для тоста', () => {
    expect(react({ type: 'notification.created', notification_id: 905, unread_count: 5 })).toEqual({
      topics: ['notifications'],
      unreadCount: 5,
      notificationId: 905,
    });
  });

  it('обсуждение: лента и открытое обсуждение', () => {
    expect(react({ type: 'discussion.updated', discussion_id: 1, changed: 'comment' }).topics).toEqual(['discussions', 'discussion:1']);
  });
});

describe('закрытие, переподключение и звук', () => {
  it('4401 — на вход, 4429 и 4400 — не переподключаться, остальное — повтор', () => {
    expect(closeAction(4401)).toBe('relogin');
    expect([4429, 4400].map(closeAction)).toEqual(['stop', 'stop']);
    expect([4408, 1001, 1012, 1006, 1000].map(closeAction)).toEqual(['retry', 'retry', 'retry', 'retry', 'retry']);
  });

  it('пауза растёт вдвое и останавливается на 30 секундах', () => {
    expect([0, 1, 2, 3, 4, 5, 9].map(retryDelay)).toEqual([1000, 2000, 4000, 8000, 16000, 30000, 30000]);
  });

  it('звук не чаще раза в четыре секунды', () => {
    expect(maySound(0, SOUND_GAP_MS)).toBe(true);
    expect(maySound(10_000, 10_000 + SOUND_GAP_MS - 1)).toBe(false);
  });
});
