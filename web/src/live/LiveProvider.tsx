import { createContext, useContext, useEffect, useMemo, useRef, type ReactNode } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useToast } from '../app/Toast';
import { useUnread } from '../app/unread';
import { useMe } from '../auth';
import { publish } from './bus';
import { react } from './events';
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
 * свои данные, обновляется счётчик на колокольчике, на чужие события — тост и короткий звук.
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

  useEffect(
    () =>
      connectLive((event) => {
        const r = react(event, { id: me.id, openChatAppealId: openChat.current });
        const now = latest.current;
        publish(r.topics);
        if (r.unreadCount !== null) now.unread.setCount(r.unreadCount);
        else if (r.refreshUnread) now.unread.refresh();
        if (r.toast) {
          const { to, text } = r.toast;
          // Карточка откроется поверх текущего экрана, как из списка.
          const background = (now.location.state as { background?: unknown } | null)?.background ?? now.location;
          if (now.location.pathname !== to) {
            now.toast(text, 'info', { label: 'Открыть', run: () => now.navigate(to, { state: { background } }) });
          }
        }
        if (r.sound) playNotify();
      }),
    [me.id],
  );

  const value = useMemo<LiveValue>(() => ({ setOpenChat: (id) => (openChat.current = id) }), []);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export const useLive = () => useContext(Ctx);
