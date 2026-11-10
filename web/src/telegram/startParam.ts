/**
 * Переход по ссылке из бота. Контракт (Notification.path): маршрут клиента передаётся в Mini App через
 * startapp, `/` заменяется на `_`: `/appeals/21` → `appeals_21`, `/discussions/5` → `discussions_5`,
 * `/analytics` → `analytics`. Telegram пропускает в start_param только [A-Za-z0-9_-], до 512 символов.
 */

/** Маршруты контракта, у которых в вебе другой адрес. */
const ALIASES: Record<string, string> = {
  '/analytics': '/digest',
};

export function pathFromStartParam(param: string | undefined | null): string | null {
  if (!param || !/^[A-Za-z0-9_-]{1,512}$/.test(param)) return null;
  const path = '/' + param.split('_').filter(Boolean).join('/');
  return ALIASES[path] ?? path;
}

/** Обратное преобразование — для ссылок t.me/<бот>/<app>?startapp=… */
export function startParamFromPath(path: string): string {
  return path.replace(/^\/+|\/+$/g, '').replace(/\//g, '_');
}
