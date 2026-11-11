import type { ComponentType } from 'react';
import type { Schemas, Session } from '../api/types';

/** Подписанные данные Telegram без сессии: ровно одно из init_data (Mini App) или telegram_login (виджет). */
export type TelegramIdentity = Schemas['TelegramIdentity'];

/** Незнакомый системе аккаунт Telegram (403 user_not_registered): ему показываем заявку на доступ. */
export interface Unregistered {
  identity: TelegramIdentity;
  /** Имя из профиля Telegram — по умолчанию в заявке. */
  suggestedName: string;
  username: string | null;
}

export interface LoginButtonProps {
  /** Вход удался: передать сессию из ответа /auth/*. */
  onSession: (session: Session) => void;
  /** Вход не удался: ошибку покажет экран входа. */
  onError: (error: unknown) => void;
  /** Аккаунт Telegram подлинный, но не заведён в системе — показать заявку на доступ (W-12). */
  onUnregistered?: (who: Unregistered) => void;
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
  /** Для autoLogin: кто пытался войти, если сервер ответил user_not_registered. */
  identity?: () => Unregistered | null;
  LoginButton?: ComponentType<LoginButtonProps>;
}
