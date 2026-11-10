import { useEffect, useRef } from 'react';
import { api, unwrap } from '../../api/client';
import type { Schemas } from '../../api/types';
import { config } from '../../config';
import type { AuthMethod, LoginButtonProps } from '../types';

type WidgetUser = Schemas['TelegramWidgetLoginRequest'];

declare global {
  interface Window {
    onModusTelegramAuth?: (user: WidgetUser) => void;
  }
}

/** Виджет Telegram Login. Работает только на домене, привязанном к боту (/setdomain), проверяется в W-10. */
function TelegramLoginButton({ onSession, onError }: LoginButtonProps) {
  const ref = useRef<HTMLDivElement>(null);
  const handlers = useRef({ onSession, onError });
  handlers.current = { onSession, onError };

  useEffect(() => {
    window.onModusTelegramAuth = (user) => {
      unwrap(api.POST('/api/v1/auth/telegram/widget', { body: user }))
        .then((s) => handlers.current.onSession(s))
        .catch((e) => handlers.current.onError(e));
    };
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

export const telegramWidgetMethod: AuthMethod = {
  id: 'telegram-widget',
  isAvailable: () => Boolean(config.telegramBotUsername),
  LoginButton: TelegramLoginButton,
};
