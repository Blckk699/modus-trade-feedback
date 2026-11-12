import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bell, CheckCheck } from 'lucide-react';
import { api, unwrap } from '../api/client';
import type { Schemas } from '../api/types';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { pathFromStartParam, startParamFromPath } from '../telegram/startParam';
import { useBackground } from './background';
import { useUnread } from './unread';
import { usePopover } from './usePopover';

type Notification = Schemas['Notification'];

/** Текст уведомления приходит с разметкой для Telegram (<b>, <i>, <a>): в списке показываем его без тегов, строки сохраняем. */
export function plainText(html: string): string {
  return html
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&')
    .split('\n')
    .map((line) => line.replace(/\s+/g, ' ').trim())
    .filter(Boolean)
    .join('\n');
}

/** Куда ведёт уведомление: path из контракта (с теми же заменами, что у ссылок бота) или карточка обращения. */
export function notificationTarget(n: Pick<Notification, 'path' | 'appeal'>): string | null {
  if (n.path) return pathFromStartParam(startParamFromPath(n.path)) ?? n.path;
  return n.appeal ? `/appeals/${n.appeal.id}` : null;
}

/** Колокольчик со счётчиком и список последних уведомлений. */
export function NotificationsBell() {
  const unread = useUnread();
  const pop = usePopover<HTMLDivElement>();
  const navigate = useNavigate();
  const background = useBackground();
  const list = useAsync(
    () => (pop.open ? unwrap(api.GET('/api/v1/notifications', { params: { query: { page_size: 20 } } })) : Promise.resolve(null)),
    [pop.open],
  );
  const { refresh } = unread;
  useEffect(() => {
    if (pop.open) refresh();
  }, [pop.open, refresh]);

  const items = list.state.status === 'ready' && list.state.data ? list.state.data.items : [];

  async function readAll() {
    await unwrap(api.POST('/api/v1/notifications/read', { body: { all: true } })).catch(() => null);
    refresh();
    list.reload();
  }

  function openItem(n: Notification) {
    if (!n.is_read) {
      unwrap(api.POST('/api/v1/notifications/read', { body: { ids: [n.id] } }))
        .then(refresh)
        .catch(() => {});
    }
    const target = notificationTarget(n);
    pop.setOpen(false);
    if (!target) return;
    // Обращения и обсуждения открываются панелью поверх текущего экрана, остальное — переходом.
    const asCard = /^\/(appeals|discussions)\/\d+$/.test(target);
    navigate(target, asCard ? { state: { background } } : undefined);
  }

  const label = unread.count > 0 ? `Уведомления, непрочитанных: ${unread.count}` : 'Уведомления';

  return (
    <div className="bell" ref={pop.ref}>
      <button
        type="button"
        className="tool-btn"
        aria-label={label}
        aria-haspopup="dialog"
        aria-expanded={pop.open}
        data-popover-trigger
        onClick={() => pop.setOpen(!pop.open)}
      >
        <Bell size={18} aria-hidden="true" />
        {unread.count > 0 && (
          <span className="bell__count" aria-hidden="true">
            {unread.count > 99 ? '99+' : unread.count}
          </span>
        )}
      </button>
      {pop.open && (
        <div className="pop pop--right pop--wide" role="dialog" aria-label="Уведомления">
          <div className="pop__head">
            <h2 className="pop__title">Уведомления</h2>
            {unread.count > 0 && (
              <button type="button" className="link-btn" onClick={readAll}>
                <CheckCheck size={16} aria-hidden="true" /> Прочитать все
              </button>
            )}
          </div>
          {list.state.status === 'loading' && <p className="pop__note">Загружаем…</p>}
          {list.state.status === 'error' && <p className="pop__note error-text">{list.state.message}</p>}
          {list.state.status === 'ready' && items.length === 0 && (
            <p className="pop__note">Пока тихо. Сюда придут ответы, вопросы и напоминания о сроках.</p>
          )}
          {items.length > 0 && (
            <ul className="notes">
              {items.map((n) => (
                <li key={n.id}>
                  <button type="button" className={n.is_read ? 'note' : 'note note--unread'} onClick={() => openItem(n)}>
                    <span className="note__dot" aria-hidden="true" />
                    <span className="note__body">
                      <span className="note__text">
                        {!n.is_read && <span className="sr-only">Новое. </span>}
                        {plainText(n.text)}
                      </span>
                      <span className="note__time">{formatDateTime(n.created_at)}</span>
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}
