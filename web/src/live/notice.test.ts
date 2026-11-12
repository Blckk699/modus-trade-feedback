import { describe, expect, it } from 'vitest';
import type { Schemas } from '../api/types';
import { noticeFor } from './notice';

const base: Schemas['Notification'] = {
  id: 905,
  kind: 'message_received',
  text: '<b>Новое сообщение</b> по MT-000042\nТекст сообщения',
  appeal: { id: 42, number: 'MT-000042' } as Schemas['AppealRef'],
  path: '/appeals/42',
  buttons: [],
  is_read: false,
  created_at: '2026-11-12T10:00:00+05:00',
};
const elsewhere = { pathname: '/queue', openChatAppealId: null };

describe('тост по уведомлению', () => {
  it('первая строка без разметки и переход по адресу уведомления', () => {
    expect(noticeFor(base, elsewhere)).toEqual({ text: 'Новое сообщение по MT-000042', to: '/appeals/42' });
  });

  it('чат этого обращения открыт — тоста нет', () => {
    expect(noticeFor(base, { pathname: '/queue', openChatAppealId: 42 })).toBeNull();
  });

  it('человек уже на экране, куда ведёт уведомление, — тоста нет', () => {
    expect(noticeFor({ ...base, kind: 'status_changed' }, { pathname: '/appeals/42', openChatAppealId: null })).toBeNull();
  });

  it('другое уведомление по обращению с открытым чатом показывается', () => {
    expect(noticeFor({ ...base, kind: 'status_changed', path: null }, { pathname: '/queue', openChatAppealId: 42 })?.to).toBe('/appeals/42');
  });

  it('без адреса — тост без перехода, длинный текст обрезается', () => {
    const n = noticeFor({ ...base, kind: 'digest', appeal: null, path: null, text: 'а'.repeat(200) }, elsewhere);
    expect(n?.to).toBeNull();
    expect(n?.text.length).toBe(90);
  });
});
