import { useEffect, useRef, useState } from 'react';
import { api, unwrap } from '../../api/client';
import { ApiError } from '../../api/errors';
import type { Schemas } from '../../api/types';
import { config } from '../../config';
import type { AuthMethod, LoginButtonProps, Unregistered } from '../types';

export type WidgetUser = Schemas['TelegramWidgetLoginRequest'];

interface TelegramLogin {
  auth: (options: { bot_id: number; request_access?: 'write' }, callback: (user: WidgetUser | false) => void) => void;
}

declare global {
  interface Window {
    onModusTelegramAuth?: (user: WidgetUser) => void;
  }
}

/** window.Telegram объявлен для Mini App (WebApp); Login добавляет telegram-widget.js. */
const telegramLogin = () => (window.Telegram as { Login?: TelegramLogin } | undefined)?.Login;

const SCRIPT_SRC = 'https://telegram.org/js/telegram-widget.js?22';

/** Вход Telegram на этой сборке настроен: есть бот для своей кнопки или для виджета. */
export const telegramLoginConfigured = () => Boolean(config.telegramBotId || config.telegramBotUsername);

/** Незнакомый аккаунт из колбэка виджета: данные для заявки и для повторного входа после одобрения. */
export function unregisteredFromWidget(user: WidgetUser): Unregistered {
  const name = [user.first_name, user.last_name].filter(Boolean).join(' ').trim();
  return { identity: { telegram_login: user }, suggestedName: name, username: user.username ?? null };
}

let scriptLoad: Promise<TelegramLogin> | null = null;

/**
 * Скрипт Telegram Login без атрибутов виджета: он не рисует iframe, а только даёт Telegram.Login.auth.
 * Грузится один раз на страницу; неудачу не запоминаем, чтобы следующий заход попробовал снова.
 */
function loadTelegramLogin(): Promise<TelegramLogin> {
  const ready = telegramLogin();
  if (ready?.auth) return Promise.resolve(ready);
  scriptLoad ??= new Promise<TelegramLogin>((resolve, reject) => {
    const script = document.createElement('script');
    script.src = SCRIPT_SRC;
    script.async = true;
    script.onload = () => {
      const login = telegramLogin();
      if (login?.auth) resolve(login);
      else reject(new Error('no Telegram.Login'));
    };
    script.onerror = () => reject(new Error('script failed'));
    document.head.appendChild(script);
  }).catch((e: unknown) => {
    scriptLoad = null;
    throw e;
  });
  return scriptLoad;
}

/** Значок Telegram: круг с бумажным самолётиком. */
function TelegramMark() {
  return (
    <svg className="sso-btn__mark" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <circle cx="12" cy="12" r="12" fill="#2AABEE" />
      <path
        fill="#fff"
        d="M5.43 11.87c3.5-1.52 5.83-2.53 7-3.02 3.33-1.39 4.02-1.63 4.47-1.64.1 0 .32.02.47.14.12.1.15.23.17.33.02.1.04.31.02.48-.18 1.9-.96 6.5-1.36 8.63-.17.9-.5 1.2-.82 1.23-.7.06-1.22-.46-1.9-.9-1.05-.69-1.64-1.12-2.66-1.79-1.18-.78-.41-1.2.26-1.9.17-.18 3.24-2.97 3.3-3.22.01-.03.01-.15-.06-.21s-.17-.04-.25-.02c-.1.02-1.79 1.14-5.06 3.35-.48.33-.91.49-1.3.48-.43-.01-1.25-.24-1.86-.44-.75-.24-1.35-.37-1.3-.79.03-.22.33-.44.89-.67z"
      />
    </svg>
  );
}

/**
 * Своя кнопка входа через Telegram — того же вида, что «Войти через Битрикс24». По нажатию открывает
 * окно Telegram (Telegram.Login.auth); работает только на домене, привязанном к боту (/setdomain).
 */
function TelegramButton({ onUser, label }: { onUser: (user: WidgetUser) => void; label: string }) {
  const [error, setError] = useState('');
  const handler = useRef(onUser);
  handler.current = onUser;

  // Скрипт подгружаем заранее: окно Telegram должно открыться прямо из нажатия, иначе браузер его заблокирует.
  useEffect(() => {
    loadTelegramLogin().catch(() => {});
  }, []);

  function open() {
    setError('');
    const login = telegramLogin();
    if (!login?.auth) {
      setError('Вход через Telegram не загрузился. Проверьте подключение и попробуйте ещё раз.');
      loadTelegramLogin().catch(() => {});
      return;
    }
    // false — окно закрыли, ничего не подтвердив: просто остаёмся на экране.
    login.auth({ bot_id: config.telegramBotId, request_access: 'write' }, (user: WidgetUser | false) => {
      if (user) handler.current(user);
    });
  }

  return (
    <div className="sso-btn__wrap">
      <button type="button" className="btn btn--soft sso-btn" onClick={open}>
        <TelegramMark />
        {label}
      </button>
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}

/** Прежний iframe-виджет: пока сборке не задан id бота. Обёртка тянется на всю ширину, чтобы ряд был ровным. */
function TelegramIframe({ onUser }: { onUser: (user: WidgetUser) => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const handler = useRef(onUser);
  handler.current = onUser;

  useEffect(() => {
    window.onModusTelegramAuth = (user) => handler.current(user);
    const script = document.createElement('script');
    script.src = SCRIPT_SRC;
    script.async = true;
    script.dataset.telegramLogin = config.telegramBotUsername;
    script.dataset.size = 'large';
    script.dataset.radius = '20';
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

/**
 * Вход Telegram. onUser получает поля ответа Telegram как есть — их же принимают вход, заявка на доступ,
 * приглашение и привязка в профиле. Есть id бота — своя кнопка, нет — прежний виджет.
 */
export function TelegramWidget({ onUser, label = 'Войти через Telegram' }: { onUser: (user: WidgetUser) => void; label?: string }) {
  return config.telegramBotId ? <TelegramButton onUser={onUser} label={label} /> : <TelegramIframe onUser={onUser} />;
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
  isAvailable: telegramLoginConfigured,
  LoginButton: TelegramLoginButton,
};
