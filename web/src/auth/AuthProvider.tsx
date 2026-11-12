import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Me, Session } from '../api/types';
import type { Unregistered } from './types';
import { authMethods } from './methods';
import { tokenStore } from './tokenStore';

type AuthState =
  | { status: 'loading' }
  | { status: 'anonymous'; notice?: string }
  | { status: 'error'; message: string }
  | { status: 'authenticated'; me: Me }
  | { status: 'unregistered'; who: Unregistered };

interface AuthContextValue {
  state: AuthState;
  /** Принять сессию от любого способа входа. */
  acceptSession: (session: Session) => void;
  /** Показать ошибку входа на экране входа. */
  failLogin: (error: unknown) => void;
  logout: () => Promise<void>;
  retry: () => void;
  /** Незнакомый аккаунт: перейти к заявке на доступ. */
  needAccess: (who: Unregistered) => void;
  /** Войти теми же данными Telegram (после одобрения заявки). */
  loginAs: (who: Unregistered) => Promise<void>;
  /** Профиль изменил способы входа: сервер вернул свежего Me. */
  setMe: (me: Me) => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

/** Отказ во входе, который нужно объяснить пользователю, а не просто показать экран входа. */
function loginNotice(e: unknown): string | undefined {
  if (e instanceof ApiError && ['user_not_registered', 'user_disabled', 'invalid_telegram_auth'].includes(e.code)) {
    return e.message;
  }
  return undefined;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: 'loading' });
  const [attempt, setAttempt] = useState(0);
  const acceptedRef = useRef(false);

  const acceptSession = useCallback((session: Session) => {
    acceptedRef.current = true;
    tokenStore.set(session.access_token);
    setState({ status: 'authenticated', me: session.user });
  }, []);

  const failLogin = useCallback((e: unknown) => {
    setState({ status: 'anonymous', notice: loginNotice(e) ?? errorMessage(e) });
  }, []);

  useEffect(() => {
    let cancelled = false;
    acceptedRef.current = false;
    setState({ status: 'loading' });

    (async () => {
      // 1. Автоматический вход (Mini App) — если способ применим в этом окружении.
      for (const m of authMethods) {
        if (!m.autoLogin || !m.isAvailable()) continue;
        try {
          const session = await m.autoLogin();
          if (session) {
            if (!cancelled) acceptSession(session);
            return;
          }
        } catch (e) {
          if (cancelled) return;
          const who = e instanceof ApiError && e.code === 'user_not_registered' ? m.identity?.() : null;
          if (who) setState({ status: 'unregistered', who });
          else failLogin(e);
          return;
        }
      }
      // 2. Сохранённая сессия.
      if (!tokenStore.get()) {
        if (!cancelled) setState({ status: 'anonymous' });
        return;
      }
      try {
        const me = await unwrap(api.GET('/api/v1/me'));
        if (!cancelled && !acceptedRef.current) setState({ status: 'authenticated', me });
      } catch (e) {
        if (cancelled || acceptedRef.current) return;
        if (e instanceof ApiError && e.status === 401) setState({ status: 'anonymous' });
        else if (e instanceof ApiError && e.status === 403) {
          tokenStore.set(null);
          setState({ status: 'anonymous', notice: e.message });
        } else setState({ status: 'error', message: errorMessage(e) });
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [attempt, acceptSession, failLogin]);

  // Токен сброшен (401 от API или выход) — возвращаемся на экран входа.
  useEffect(
    () =>
      tokenStore.subscribe((t) => {
        if (!t) setState((s) => (s.status === 'anonymous' ? s : { status: 'anonymous' }));
      }),
    [],
  );

  const logout = useCallback(async () => {
    try {
      await api.POST('/api/v1/auth/logout');
    } catch {
      /* сессию на клиенте закрываем в любом случае */
    }
    tokenStore.set(null);
    setState({ status: 'anonymous' });
  }, []);

  const retry = useCallback(() => setAttempt((n) => n + 1), []);

  const setMe = useCallback((me: Me) => setState((s) => (s.status === 'authenticated' ? { status: 'authenticated', me } : s)), []);

  const needAccess = useCallback((who: Unregistered) => setState({ status: 'unregistered', who }), []);

  const loginAs = useCallback(
    async (who: Unregistered) => {
      const { telegram_login: login, init_data: initData } = who.identity;
      const session = login
        ? await unwrap(api.POST('/api/v1/auth/telegram/widget', { body: login }))
        : await unwrap(api.POST('/api/v1/auth/telegram/mini-app', { body: { init_data: initData ?? '' } }));
      acceptSession(session);
    },
    [acceptSession],
  );

  return (
    <AuthContext.Provider value={{ state, acceptSession, failLogin, logout, retry, needAccess, loginAs, setMe }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth вне AuthProvider');
  return ctx;
}

/** Текущий пользователь. Только внутри экранов после входа. */
export function useMe(): Me {
  const { state } = useAuth();
  if (state.status !== 'authenticated') throw new Error('useMe до входа');
  return state.me;
}
