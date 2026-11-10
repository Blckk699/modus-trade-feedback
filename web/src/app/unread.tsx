import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import { api, unwrap } from '../api/client';

interface UnreadValue {
  count: number;
  refresh: () => void;
  /** Отметить прочитанным всё по обращению (при открытии карточки). */
  markAppealRead: (appealId: number) => void;
}

const Ctx = createContext<UnreadValue>({ count: 0, refresh: () => {}, markAppealRead: () => {} });
const POLL_MS = 30_000;

/** Счётчик непрочитанного: GET /notifications/unread-count раз в 30 с и при возврате на вкладку. */
export function UnreadProvider({ children }: { children: ReactNode }) {
  const [count, setCount] = useState(0);

  const refresh = useCallback(() => {
    unwrap(api.GET('/api/v1/notifications/unread-count'))
      .then((r) => setCount(r.count))
      .catch(() => {
        /* счётчик не критичен: оставляем прежнее значение */
      });
  }, []);

  const markAppealRead = useCallback((appealId: number) => {
    unwrap(api.POST('/api/v1/notifications/read', { body: { appeal_id: appealId } }))
      .then((r) => setCount(r.count))
      .catch(() => {});
  }, []);

  useEffect(() => {
    refresh();
    const timer = window.setInterval(refresh, POLL_MS);
    const onVisible = () => document.visibilityState === 'visible' && refresh();
    document.addEventListener('visibilitychange', onVisible);
    return () => {
      window.clearInterval(timer);
      document.removeEventListener('visibilitychange', onVisible);
    };
  }, [refresh]);

  return <Ctx.Provider value={{ count, refresh, markAppealRead }}>{children}</Ctx.Provider>;
}

export const useUnread = () => useContext(Ctx);
