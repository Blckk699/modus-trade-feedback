import createClient, { type Middleware } from 'openapi-fetch';
import type { paths } from './schema';
import { config } from '../config';
import { tokenStore } from '../auth/tokenStore';
import { ApiError, toApiError } from './errors';

const auth: Middleware = {
  onRequest({ request, schemaPath }) {
    const token = tokenStore.get();
    if (token && !request.headers.has('Authorization')) {
      request.headers.set('Authorization', `Bearer ${token}`);
    }
    if (config.mockMeExample && schemaPath === '/api/v1/me' && !request.headers.has('Prefer')) {
      request.headers.set('Prefer', `example=${config.mockMeExample}`);
    }
    return request;
  },
  onResponse({ request, response, schemaPath }) {
    // Истёкшая или отозванная сессия: выходим. Маршруты входа сами отвечают 401 на неверные данные,
    // как и привязка Telegram (POST /me/telegram: 401 — Telegram не подтвердил подпись, сессия при этом жива).
    // Отвязка (DELETE того же пути) — обычный запрос: её 401 значит, что сессии больше нет.
    const ownAuthError =
      schemaPath.startsWith('/api/v1/auth/') || (schemaPath === '/api/v1/me/telegram' && request.method === 'POST');
    if (response.status === 401 && !ownAuthError) {
      tokenStore.set(null);
    }
    return response;
  },
};

/** Типизированный клиент API, сгенерированный из contract/openapi.yaml (npm run gen:api). */
export const api = createClient<paths>({ baseUrl: config.apiBaseUrl });
api.use(auth);

/**
 * Достаёт data из ответа openapi-fetch или бросает ApiError.
 * Пример: const me = await unwrap(api.GET('/api/v1/me'));
 */
export async function unwrap<T>(
  call: Promise<{ data?: T; error?: unknown; response: Response }>,
): Promise<T> {
  let res;
  try {
    res = await call;
  } catch {
    throw new ApiError(0, 'network_error', 'Не удалось связаться с сервером. Проверьте подключение.');
  }
  if (res.response.ok) return res.data as T;
  throw toApiError(res.response.status, res.error);
}
