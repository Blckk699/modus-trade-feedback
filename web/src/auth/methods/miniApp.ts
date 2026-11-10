import { api, unwrap } from '../../api/client';
import type { Session } from '../../api/types';
import { getWebApp } from '../../telegram/webApp';
import type { AuthMethod } from '../types';

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
};
