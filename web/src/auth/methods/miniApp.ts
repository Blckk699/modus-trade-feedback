import { api, unwrap } from '../../api/client';
import type { Session } from '../../api/types';
import { getWebApp } from '../../telegram/webApp';

/** Профиль из initData (поле user — JSON). Только для подстановки имени в заявку; подпись проверяет бэкенд. */
function profileFromInitData(initData: string): { name: string; username: string | null } {
  try {
    const raw = new URLSearchParams(initData).get('user');
    const u = raw ? (JSON.parse(raw) as { first_name?: string; last_name?: string; username?: string }) : {};
    return { name: [u.first_name, u.last_name].filter(Boolean).join(' ').trim(), username: u.username ?? null };
  } catch {
    return { name: '', username: null };
  }
}
import type { AuthMethod, Unregistered } from '../types';

/**
 * Вход Mini App (T-06): подписанные initData Telegram → POST /api/v1/auth/telegram/mini-app.
 * Ошибки (401 invalid_telegram_auth, 403 user_not_registered / user_disabled) пробрасываются —
 * AuthProvider покажет экран входа с message из ответа.
 */
export const miniAppMethod: AuthMethod = {
  id: 'mini-app',
  isAvailable: () => getWebApp() !== null,
  autoLogin: async (): Promise<Session | null> => {
    const webApp = getWebApp();
    if (!webApp) return null;
    return unwrap(api.POST('/api/v1/auth/telegram/mini-app', { body: { init_data: webApp.initData } }));
  },
  identity: (): Unregistered | null => {
    const webApp = getWebApp();
    if (!webApp) return null;
    const p = profileFromInitData(webApp.initData);
    return { identity: { init_data: webApp.initData }, suggestedName: p.name, username: p.username };
  },
};
