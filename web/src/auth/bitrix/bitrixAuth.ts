import { api, unwrap } from '../../api/client';
import { ApiError } from '../../api/errors';
import type { Session } from '../../api/types';
import { config } from '../../config';
import { CODES } from '../email/forms';

/**
 * Вход через Битрикс24 (B-23). Экраны знают только этот интерфейс.
 *
 * Маршруты по контракту B-23:
 * - GET  /api/v1/auth/methods — { bitrix24 } : включён ли вход;
 * - GET  /api/v1/auth/bitrix/start — переход браузера: бэкенд ставит state и уводит на портал;
 * - портал возвращает на бэкенд, бэкенд — на /auth/bitrix/done?code=… (одноразовый, 60 с) или ?error=<код>;
 * - POST /api/v1/auth/bitrix/exchange {code} — сессия, как у других способов входа.
 */
export interface BitrixAuthApi {
  /** Сервер включил вход через Битрикс24 (заданы ключи портала). */
  enabled(): Promise<boolean>;
  /** Куда отправить браузер, чтобы начать вход. */
  startUrl(): string;
  /** Одноразовый код с экрана возврата — на сессию. */
  exchange(code: string): Promise<Session>;
  /** Запасной путь: бэкенд вернул готовый токен во фрагменте адреса. */
  sessionFromToken(token: string): Promise<Session>;
}

async function sessionFromToken(token: string): Promise<Session> {
  const user = await unwrap(api.GET('/api/v1/me', { headers: { Authorization: `Bearer ${token}` } }));
  return { access_token: token, token_type: 'bearer', expires_at: '', user };
}

export const httpBitrixAuth: BitrixAuthApi = {
  // Старый сервер маршрута не знает (404) — кнопку не показываем.
  enabled: () => unwrap(api.GET('/api/v1/auth/methods')).then((m) => m.bitrix24 === true),
  startUrl: () => `${config.apiBaseUrl}/api/v1/auth/bitrix/start`,
  exchange: (code) => unwrap(api.POST('/api/v1/auth/bitrix/exchange', { body: { code } })),
  sessionFromToken,
};

/**
 * Мок для проверки экранов без портала (VITE_BITRIX_AUTH_MOCK=true). «Портал» сразу возвращает на экран возврата
 * с кодом mock-ok; другие состояния открываются адресом вручную:
 * /auth/bitrix/done?code=mock-pending | mock-rejected | mock-disabled, ?error=user_disabled | invalid_bitrix_auth | bitrix_unavailable.
 * Удачный вход берёт сессию через dev-вход локального бэкенда.
 */
export function createMockBitrixAuth(): BitrixAuthApi {
  const refuse = (code: (typeof CODES)[keyof typeof CODES], message: string, details: Record<string, unknown> | null = null) =>
    new ApiError(403, code, message, details);
  return {
    enabled: async () => true,
    startUrl: () => '/auth/bitrix/done?code=mock-ok',
    async exchange(code) {
      if (code === 'mock-pending') throw refuse(CODES.pending, 'Заявка на рассмотрении.');
      if (code === 'mock-rejected') throw refuse(CODES.rejected, 'Заявка отклонена.', { reason: 'Подрядчикам доступ не выдаём' });
      if (code === 'mock-disabled') throw refuse(CODES.disabled, 'Доступ отключён.');
      if (code !== 'mock-ok') throw new ApiError(401, 'invalid_bitrix_auth', 'Не удалось подтвердить вход через Битрикс24. Попробуйте ещё раз.');
      return unwrap(api.POST('/api/v1/auth/dev/login', { body: { user_id: 4 } }));
    },
    sessionFromToken,
  };
}

export const bitrixAuth: BitrixAuthApi = config.bitrixAuthMock ? createMockBitrixAuth() : httpBitrixAuth;
