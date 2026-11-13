import { describe, expect, it, vi } from 'vitest';
import { openFullWindow, safeInsets, watchSafeArea } from './viewport';
import type { WebApp } from './webApp';

function fakeWebApp(platform: string, version = '8.0', extra: Partial<WebApp> = {}) {
  const handlers = new Map<string, Set<() => void>>();
  const webApp = {
    platform,
    version,
    isVersionAtLeast: (v: string) => {
      const [a, b] = version.split('.').map(Number);
      const [c, d] = v.split('.').map(Number);
      return a > c || (a === c && b >= d);
    },
    isFullscreen: false,
    expand: vi.fn(),
    requestFullscreen: vi.fn(),
    disableVerticalSwipes: vi.fn(),
    onEvent: (event: string, cb: () => void) => {
      if (!handlers.has(event)) handlers.set(event, new Set());
      handlers.get(event)!.add(cb);
    },
    offEvent: (event: string, cb: () => void) => handlers.get(event)?.delete(cb),
    ...extra,
  };
  const fire = (event: string) => handlers.get(event)?.forEach((cb) => cb());
  return { webApp: webApp as unknown as WebApp & typeof webApp, fire, handlers };
}

/** Корень страницы без DOM (тесты идут в node): только то, что трогает watchSafeArea. */
function fakeRoot() {
  const props = new Map<string, string>();
  const attrs = new Set<string>();
  return {
    style: {
      setProperty: (name: string, value: string) => props.set(name, value),
      removeProperty: (name: string) => props.delete(name),
      getPropertyValue: (name: string) => props.get(name) ?? '',
    },
    toggleAttribute: (name: string, on: boolean) => (on ? attrs.add(name) : attrs.delete(name)),
    hasAttribute: (name: string) => attrs.has(name),
  } as unknown as HTMLElement;
}

describe('Mini App на весь экран', () => {
  it('на телефоне с Telegram 8.0+ — requestFullscreen, свайп вниз не закрывает окно', () => {
    for (const platform of ['ios', 'android', 'android_x']) {
      const { webApp } = fakeWebApp(platform);
      openFullWindow(webApp);
      expect(webApp.expand).toHaveBeenCalled();
      expect(webApp.requestFullscreen).toHaveBeenCalledOnce();
      expect(webApp.disableVerticalSwipes).toHaveBeenCalledOnce();
    }
  });

  it('на компьютере и в вебе — только expand()', () => {
    for (const platform of ['tdesktop', 'macos', 'weba', 'webk', 'unknown']) {
      const { webApp } = fakeWebApp(platform);
      openFullWindow(webApp);
      expect(webApp.expand).toHaveBeenCalled();
      expect(webApp.requestFullscreen).not.toHaveBeenCalled();
    }
  });

  it('старый клиент: до 8.0 без полного экрана, до 7.7 свайпы не трогаем', () => {
    const v77 = fakeWebApp('ios', '7.7');
    openFullWindow(v77.webApp);
    expect(v77.webApp.requestFullscreen).not.toHaveBeenCalled();
    expect(v77.webApp.disableVerticalSwipes).toHaveBeenCalledOnce();

    const v76 = fakeWebApp('android', '7.6');
    openFullWindow(v76.webApp);
    expect(v76.webApp.expand).toHaveBeenCalled();
    expect(v76.webApp.disableVerticalSwipes).not.toHaveBeenCalled();
  });

  it('уже на весь экран (запуск в режиме fullscreen) — повторно не просим', () => {
    const { webApp } = fakeWebApp('ios', '8.0', { isFullscreen: true });
    openFullWindow(webApp);
    expect(webApp.requestFullscreen).not.toHaveBeenCalled();
  });
});

describe('отступы под чёлку и кнопки Telegram', () => {
  it('складывает безопасную зону устройства и зону под кнопками Telegram', () => {
    const { webApp } = fakeWebApp('ios', '8.0', {
      safeAreaInset: { top: 47, bottom: 34, left: 0, right: 0 },
      contentSafeAreaInset: { top: 46, bottom: 0, left: 0, right: 0 },
    });
    expect(safeInsets(webApp)).toEqual({ top: 93, right: 0, bottom: 34, left: 0 });
  });

  it('старый клиент без зон — переменных нет, CSS берёт env()', () => {
    const { webApp } = fakeWebApp('ios', '7.7');
    expect(safeInsets(webApp)).toBeNull();
    const root = fakeRoot();
    watchSafeArea(webApp, root);
    expect(root.style.getPropertyValue('--app-safe-top')).toBe('');
  });

  it('пишет --app-safe-* и обновляет их по событиям Telegram; отписка снимает обработчики', () => {
    const { webApp, fire, handlers } = fakeWebApp('android', '8.0', {
      safeAreaInset: { top: 24, bottom: 0, left: 0, right: 0 },
      contentSafeAreaInset: { top: 0, bottom: 0, left: 0, right: 0 },
    });
    const root = fakeRoot();
    const stop = watchSafeArea(webApp, root);
    expect(root.style.getPropertyValue('--app-safe-top')).toBe('24px');
    expect(root.hasAttribute('data-telegram-fullscreen')).toBe(false);

    webApp.isFullscreen = true;
    webApp.contentSafeAreaInset = { top: 48, bottom: 0, left: 0, right: 0 };
    fire('contentSafeAreaChanged');
    expect(root.style.getPropertyValue('--app-safe-top')).toBe('72px');

    fire('fullscreenChanged');
    expect(root.hasAttribute('data-telegram-fullscreen')).toBe(true);

    stop();
    for (const event of ['safeAreaChanged', 'contentSafeAreaChanged', 'fullscreenChanged']) {
      expect(handlers.get(event)?.size ?? 0).toBe(0);
    }
  });
});
