import { createContext, useContext, useEffect, useMemo, useRef, type ReactNode } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { useToast } from '../app/Toast';
import { useUnread } from '../app/unread';
import { useMe } from '../auth';
import { publish, publishAll } from './bus';
import { react } from './events';
import { noticeFor } from './notice';
import { connectLive } from './socket';
import { playNotify } from './sound';

interface LiveValue {
  /** Раздел переписки сообщает, чей чат сейчас открыт: о сообщениях в нём тост не нужен. */
  setOpenChat: (appealId: number | null) => void;
}

const Ctx = createContext<LiveValue>({ setOpenChat: () => {} });

/**
 * Живые обновления (W-16): подписка после входа, закрытие при выходе и смене роли (провайдер стоит
 * внутри части приложения, привязанной к id пользователя). По событию экраны тихо перезапрашивают
 * свои данные; по уведомлению обновляется счётчик на колокольчике, звучит короткий сигнал и
 * появляется тост с переходом. После переподключения всё, что на экране, перечитывается.
 */
export function LiveProvider({ children }: { children: ReactNode }) {
  const me = useMe();
  const unread = useUnread();
  const toast = useToast();
  const navigate = useNavigate();
  const location = useLocation();
  const openChat = useRef<number | null>(null);
  // Обработчик живёт всё время подписки, а экран под ним меняется: берём свежие значения через ref.
  const latest = useRef({ unread, toast, navigate, location });
  latest.current = { unread, toast, navigate, location };

  useEffect(() => {
    let alive = true;

    // В событии только id уведомления: текст и адрес берём из списка непрочитанного.
    const announce = (id: number) => {
      unwrap(api.GET('/api/v1/notifications', { params: { query: { unread_only: true, page_size: 10 } } }))
        .then((page) => {
          const n = page.items.find((x) => x.id === id);
          if (!alive || !n) return;
          const now = latest.current;
          const notice = noticeFor(n, { pathname: now.location.pathname, openChatAppealId: openChat.current });
          if (!notice) return;
          const { to } = notice;
          // Карточка откроется поверх текущего экрана, как из списка.
          const background = (now.location.state as { background?: unknown } | null)?.background ?? now.location;
          now.toast(notice.text, 'info', to ? { label: 'Открыть', run: () => now.navigate(to, { state: { background } }) } : undefined);
        })
        .catch(() => {
          /* тост не критичен: счётчик на колокольчике уже обновлён */
        });
    };

    const close = connectLive({
      onReady: (unreadCount, reconnected) => {
        latest.current.unread.setCount(unreadCount);
        if (reconnected) publishAll();
      },
      onEvent: (event) => {
        const r = react(event);
        publish(r.topics);
        if (r.unreadCount !== null) latest.current.unread.setCount(r.unreadCount);
        if (r.notificationId !== null) {
          playNotify();
          announce(r.notificationId);
        }
      },
    });
    return () => {
      alive = false;
      close();
    };
  }, [me.id]);

  const value = useMemo<LiveValue>(() => ({ setOpenChat: (id) => (openChat.current = id) }), []);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export const useLive = () => useContext(Ctx);
