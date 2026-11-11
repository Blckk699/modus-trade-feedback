import type { WebApp } from './webApp';

/**
 * Mini App рисуется нашими токенами без перекраски под тему Telegram: выглядит так же, как мобильный веб.
 * Светлая или тёмная — по той же логике, что в вебе (useTheme: системная тема или выбор пользователя).
 * Telegram только подкрашивает свою рамку вокруг приложения нашими цветами текущей темы,
 * чтобы шапка и нижняя полоса Telegram не отличались от нашей шапки и фона (design/README.md, раздел про Mini App).
 */

export interface FrameColors {
  /** Шапка Telegram — как наша шапка (--surface). */
  header?: string;
  /** Фон под приложением — как фон страницы (--bg). */
  background?: string;
  /** Нижняя полоса Telegram — как наша нижняя панель разделов (--surface). */
  bottomBar?: string;
}

const HEX = /^#[0-9a-f]{6}$/i;

/** Цвета рамки из CSS-переменных текущей темы. Telegram принимает только '#RRGGBB' — остальное пропускаем. */
export function frameColors(readVar: (name: string) => string): FrameColors {
  const pick = (name: string) => {
    const value = readVar(name).trim();
    return HEX.test(value) ? value.toLowerCase() : undefined;
  };
  const surface = pick('--surface');
  return { header: surface, background: pick('--bg'), bottomBar: surface };
}

/** Метод доступен в этой версии Telegram: старые клиенты пишут предупреждение в консоль вместо вызова. */
function supports(webApp: WebApp, version: string): boolean {
  return webApp.isVersionAtLeast ? webApp.isVersionAtLeast(version) : true;
}

/**
 * Покрасить рамку Telegram цветами нашей текущей темы. Только читает переменные (readVar)
 * и вызывает методы Telegram — наши CSS-переменные и data-theme не трогает.
 */
export function syncTelegramFrame(webApp: WebApp, readVar: (name: string) => string): void {
  const c = frameColors(readVar);
  if (c.header && webApp.setHeaderColor && supports(webApp, '6.9')) webApp.setHeaderColor(c.header);
  if (c.background && webApp.setBackgroundColor && supports(webApp, '6.1')) webApp.setBackgroundColor(c.background);
  if (c.bottomBar && webApp.setBottomBarColor && supports(webApp, '7.10')) webApp.setBottomBarColor(c.bottomBar);
}

/**
 * Держать рамку Telegram в цвет нашей темы: сейчас и при каждой смене — пользователь переключил тему
 * (data-theme на <html>) или сменилась системная тема (prefers-color-scheme). Возвращает отписку.
 */
export function watchTelegramFrame(webApp: WebApp, root: HTMLElement = document.documentElement): () => void {
  root.setAttribute('data-telegram', webApp.platform || 'unknown');
  const sync = () => {
    const style = getComputedStyle(root);
    syncTelegramFrame(webApp, (name) => style.getPropertyValue(name));
  };
  sync();
  const observer = new MutationObserver(sync);
  observer.observe(root, { attributes: true, attributeFilter: ['data-theme'] });
  const media = window.matchMedia?.('(prefers-color-scheme: dark)');
  media?.addEventListener('change', sync);
  return () => {
    observer.disconnect();
    media?.removeEventListener('change', sync);
  };
}
