import type { Insets, WebApp } from './webApp';

/**
 * Окно Mini App: на телефоне — на весь экран, без закрытия свайпом вниз, с отступами под чёлку
 * и под кнопки Telegram «Закрыть» и «⋯».
 *
 * Отступы раздаём CSS-переменными на <html>: --app-safe-top|right|bottom|left = безопасная зона устройства
 * (safeAreaInset) + зона, которую занимают элементы Telegram поверх приложения (contentSafeAreaInset).
 * global.css берёт их через --safe-*; вне Telegram и в старых клиентах остаётся env(safe-area-inset-*).
 */

const MOBILE = new Set(['ios', 'android', 'android_x']);
const SIDES = ['top', 'right', 'bottom', 'left'] as const;
const EVENTS = ['safeAreaChanged', 'contentSafeAreaChanged', 'fullscreenChanged'] as const;

/** Метод доступен в этой версии Telegram: старые клиенты пишут предупреждение в консоль вместо вызова. */
function supports(webApp: WebApp, version: string): boolean {
  return webApp.isVersionAtLeast ? webApp.isVersionAtLeast(version) : true;
}

/** Телефон и Telegram 8.0+: открываем на весь экран. Иначе (компьютер, веб, старые клиенты) — expand(). */
export function shouldGoFullscreen(webApp: WebApp): boolean {
  return MOBILE.has(webApp.platform) && !!webApp.requestFullscreen && supports(webApp, '8.0');
}

/** Раскрыть окно: expand() всегда, на телефоне ещё и requestFullscreen(); отключить закрытие свайпом (7.7+). */
export function openFullWindow(webApp: WebApp): void {
  webApp.expand();
  if (shouldGoFullscreen(webApp) && !webApp.isFullscreen) webApp.requestFullscreen!();
  if (webApp.disableVerticalSwipes && supports(webApp, '7.7')) webApp.disableVerticalSwipes();
}

/** Отступы в px по сторонам: безопасная зона устройства плюс зона под элементами Telegram. */
export function safeInsets(webApp: WebApp): Record<(typeof SIDES)[number], number> | null {
  if (!webApp.safeAreaInset && !webApp.contentSafeAreaInset) return null;
  const px = (insets: Insets | undefined, side: (typeof SIDES)[number]) => Math.max(0, Number(insets?.[side]) || 0);
  return {
    top: px(webApp.safeAreaInset, 'top') + px(webApp.contentSafeAreaInset, 'top'),
    right: px(webApp.safeAreaInset, 'right') + px(webApp.contentSafeAreaInset, 'right'),
    bottom: px(webApp.safeAreaInset, 'bottom') + px(webApp.contentSafeAreaInset, 'bottom'),
    left: px(webApp.safeAreaInset, 'left') + px(webApp.contentSafeAreaInset, 'left'),
  };
}

/**
 * Держать --app-safe-* в актуальном виде: сейчас и на safeAreaChanged, contentSafeAreaChanged,
 * fullscreenChanged (поворот, вход и выход из полноэкранного режима). Возвращает отписку.
 */
export function watchSafeArea(webApp: WebApp, root: HTMLElement = document.documentElement): () => void {
  const apply = () => {
    const insets = safeInsets(webApp);
    for (const side of SIDES) {
      if (insets) root.style.setProperty(`--app-safe-${side}`, `${insets[side]}px`);
      else root.style.removeProperty(`--app-safe-${side}`);
    }
    root.toggleAttribute('data-telegram-fullscreen', !!webApp.isFullscreen);
  };
  apply();
  for (const event of EVENTS) webApp.onEvent(event, apply);
  return () => {
    for (const event of EVENTS) webApp.offEvent(event, apply);
  };
}
