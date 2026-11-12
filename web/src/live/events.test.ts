import { describe, expect, it } from 'vitest';
import { maySound, parseEvent, react, retryDelay, SOUND_GAP_MS } from './events';

const me = { id: 4, openChatAppealId: null };

describe('разбор событий', () => {
  it('знакомые события проходят, строка JSON разбирается', () => {
    expect(parseEvent('{"type":"message.created","appeal_id":28}')).toEqual({ type: 'message.created', appeal_id: 28 });
    expect(parseEvent({ type: 'discussion.updated', discussion_id: 1 })).toEqual({ type: 'discussion.updated', discussion_id: 1 });
    expect(parseEvent({ type: 'notification.created', unread_count: 3 })).toEqual({ type: 'notification.created', unread_count: 3 });
  });

  it('незнакомое, битое и без id — отбрасывается', () => {
    expect(parseEvent('не json')).toBeNull();
    expect(parseEvent({ type: 'pong' })).toBeNull();
    expect(parseEvent({ type: 'appeal.updated' })).toBeNull();
    expect(parseEvent({ type: 'appeal.updated', appeal_id: '28' })).toBeNull();
    expect(parseEvent(null)).toBeNull();
  });
});

describe('что делать по событию', () => {
  it('чужое сообщение: перезапрос переписки и списков, тост с переходом, звук', () => {
    expect(react({ type: 'message.created', appeal_id: 28, number: 'A-028', actor_id: 3 }, me)).toEqual({
      topics: ['appeals', 'messages:28'],
      unreadCount: null,
      refreshUnread: true,
      toast: { text: 'Новое сообщение по A-028', to: '/appeals/28' },
      sound: true,
    });
  });

  it('своё сообщение: данные обновляются, тоста и звука нет', () => {
    const r = react({ type: 'message.created', appeal_id: 28, actor_id: 4 }, me);
    expect(r).toMatchObject({ topics: ['appeals', 'messages:28'], toast: null, sound: false, refreshUnread: false });
  });

  it('чат этого обращения открыт: звук есть, тоста нет', () => {
    const r = react({ type: 'message.created', appeal_id: 28, actor_id: 3 }, { id: 4, openChatAppealId: 28 });
    expect(r).toMatchObject({ toast: null, sound: true });
  });

  it('номер обращения в событии не пришёл — тост без номера', () => {
    expect(react({ type: 'message.created', appeal_id: 28 }, me).toast).toEqual({ text: 'Новое сообщение по обращению', to: '/appeals/28' });
  });

  it('смена статуса: карточка и списки, без тоста и звука', () => {
    expect(react({ type: 'appeal.updated', appeal_id: 7, status: 'in_progress', actor_id: 3 }, me)).toMatchObject({
      topics: ['appeals', 'appeal:7'],
      toast: null,
      sound: false,
    });
  });

  it('уведомление: счётчик из события, звук; без счётчика — перезапросить', () => {
    expect(react({ type: 'notification.created', unread_count: 5 }, me)).toMatchObject({
      topics: ['notifications', 'appeals'],
      unreadCount: 5,
      refreshUnread: false,
      sound: true,
    });
    expect(react({ type: 'notification.created' }, me)).toMatchObject({ unreadCount: null, refreshUnread: true });
  });

  it('обсуждение: лента и открытое обсуждение', () => {
    expect(react({ type: 'discussion.updated', discussion_id: 1 }, me).topics).toEqual(['discussions', 'discussion:1']);
  });
});

describe('переподключение и звук', () => {
  it('пауза растёт вдвое и останавливается на 30 секундах', () => {
    expect([0, 1, 2, 3, 4, 5, 9].map(retryDelay)).toEqual([1000, 2000, 4000, 8000, 16000, 30000, 30000]);
  });

  it('звук не чаще раза в четыре секунды', () => {
    expect(maySound(0, SOUND_GAP_MS)).toBe(true);
    expect(maySound(10_000, 10_000 + SOUND_GAP_MS - 1)).toBe(false);
  });
});
