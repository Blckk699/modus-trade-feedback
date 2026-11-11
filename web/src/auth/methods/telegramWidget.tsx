import { useEffect, useRef } from 'react';
import { api, unwrap } from '../../api/client';
import { ApiError } from '../../api/errors';
import type { Schemas } from '../../api/types';
import { config } from '../../config';
import type { AuthMethod, LoginButtonProps, Unregistered } from '../types';

export type WidgetUser = Schemas['TelegramWidgetLoginRequest'];

declare global {
  interface Window {
    onModusTelegramAuth?: (user: WidgetUser) => void;
  }
}

/** Незнакомый аккаунт из колбэка виджета: данные для заявки и для повторного входа после одобрения. */
export function unregisteredFromWidget(user: WidgetUser): Unregistered {
  const name = [user.first_name, user.last_name].filter(Boolean).join(' ').trim();
  return { identity: { telegram_login: user }, suggestedName: name, username: user.username ?? null };
}

/**
 * Виджет Telegram Login. Работает только на домене, привязанном к боту (/setdomain).
 * onUser получает поля колбэка как есть — их же принимают вход, заявка на доступ и приглашение.
 */
export function TelegramWidget({ onUser }: { onUser: (user: WidgetUser) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const handler = useRef(onUser);
  handler.current = onUser;

  useEffect(() => {
    window.onModusTelegramAuth = (user) => handler.current(user);
    const script = document.createElement('script');
    script.src = 'https://telegram.org/js/telegram-widget.js?22';
    script.async = true;
    script.dataset.telegramLogin = config.telegramBotUsername;
    script.dataset.size = 'large';
    script.dataset.radius = '8';
    script.dataset.requestAccess = 'write';
    script.dataset.onauth = 'onModusTelegramAuth(user)';
    const host = ref.current;
    host?.appendChild(script);
    return () => {
      delete window.onModusTelegramAuth;
      if (host) host.innerHTML = '';
    };
  }, []);

  return <div ref={ref} className="telegram-login" />;
}

function TelegramLoginButton({ onSession, onError, onUnregistered }: LoginButtonProps) {
  return (
    <TelegramWidget
      onUser={(user) => {
        unwrap(api.POST('/api/v1/auth/telegram/widget', { body: user }))
          .then(onSession)
          .catch((e) => {
            // Подпись верна, но аккаунта нет среди сотрудников — вместо отказа предлагаем заявку (W-12).
            if (e instanceof ApiError && e.code === 'user_not_registered' && onUnregistered) {
              onUnregistered(unregisteredFromWidget(user));
            } else onError(e);
          });
      }}
    />
  );
}

export const telegramWidgetMethod: AuthMethod = {
  id: 'telegram-widget',
  isAvailable: () => Boolean(config.telegramBotUsername),
  LoginButton: TelegramLoginButton,
};
