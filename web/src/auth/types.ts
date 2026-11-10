import type { ComponentType } from 'react';
import type { Session } from '../api/types';

export interface LoginButtonProps {
  /** Вход удался: передать сессию из ответа /auth/*. */
  onSession: (session: Session) => void;
  /** Вход не удался: ошибку покажет экран входа. */
  onError: (error: unknown) => void;
}

/**
 * Способ входа. Экраны о способах ничего не знают: AuthProvider перебирает список из methods/index.ts.
 * - autoLogin — вход без участия пользователя (Mini App по initData). Вернуть null, если метод не применим.
 * - LoginButton — элемент на экране входа (Telegram Login, dev-вход).
 */
export interface AuthMethod {
  id: string;
  isAvailable: () => boolean;
  autoLogin?: () => Promise<Session | null>;
  LoginButton?: ComponentType<LoginButtonProps>;
}
