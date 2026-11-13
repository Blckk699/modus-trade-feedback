/**
 * Telegram Mini App: доступ к window.Telegram.WebApp (скрипт telegram-web-app.js подключён в index.html).
 * В обычном браузере скрипт тоже загружается, но initData пустой — тогда считаем, что мы не в Telegram.
 * Типы — только то, чем пользуется оболочка (https://core.telegram.org/bots/webapps).
 */

export interface ThemeParams {
  bg_color?: string;
  text_color?: string;
  hint_color?: string;
  link_color?: string;
  button_color?: string;
  button_text_color?: string;
  secondary_bg_color?: string;
  section_bg_color?: string;
  section_separator_color?: string;
  destructive_text_color?: string;
}

interface BottomButton {
  setText(text: string): BottomButton;
  show(): BottomButton;
  hide(): BottomButton;
  enable(): BottomButton;
  disable(): BottomButton;
  showProgress(leaveActive?: boolean): BottomButton;
  hideProgress(): BottomButton;
  onClick(cb: () => void): BottomButton;
  offClick(cb: () => void): BottomButton;
}

interface BackButton {
  show(): BackButton;
  hide(): BackButton;
  onClick(cb: () => void): BackButton;
  offClick(cb: () => void): BackButton;
}

/** Отступы в px (safeAreaInset, contentSafeAreaInset): с версии 8.0. */
export interface Insets {
  top: number;
  bottom: number;
  left: number;
  right: number;
}

/** События, на которые подписывается оболочка. */
export type WebAppEvent = 'themeChanged' | 'safeAreaChanged' | 'contentSafeAreaChanged' | 'fullscreenChanged';

export interface WebApp {
  initData: string;
  initDataUnsafe: { start_param?: string };
  platform: string;
  colorScheme: 'light' | 'dark';
  themeParams: ThemeParams;
  version?: string;
  ready(): void;
  expand(): void;
  isVersionAtLeast?(version: string): boolean;
  /** Цвет шапки Telegram над приложением: '#RRGGBB' с версии 6.9. */
  setHeaderColor?(color: string): void;
  /** Фон под приложением (виден при оттягивании): '#RRGGBB' с версии 6.1. */
  setBackgroundColor?(color: string): void;
  /** Нижняя полоса Telegram под приложением: с версии 7.10. */
  setBottomBarColor?(color: string): void;
  /** Полноэкранный режим: с версии 8.0. На компьютере и в вебе Telegram отвечает fullscreenFailed. */
  isFullscreen?: boolean;
  requestFullscreen?(): void;
  exitFullscreen?(): void;
  /** Свайп вниз больше не закрывает окно: с версии 7.7. */
  disableVerticalSwipes?(): void;
  enableVerticalSwipes?(): void;
  /** Безопасная зона устройства (чёлка, полоска «домой»): с версии 8.0. */
  safeAreaInset?: Insets;
  /** Зона под элементами Telegram поверх приложения (кнопки «Закрыть» и «⋯» в полноэкранном режиме): с 8.0. */
  contentSafeAreaInset?: Insets;
  onEvent(event: WebAppEvent, cb: () => void): void;
  offEvent(event: WebAppEvent, cb: () => void): void;
  BackButton: BackButton;
  MainButton: BottomButton;
}

declare global {
  interface Window {
    Telegram?: { WebApp?: WebApp };
  }
}

/** WebApp, если страница открыта как Mini App (есть подписанные initData), иначе null. */
export function getWebApp(): WebApp | null {
  const webApp = typeof window === 'undefined' ? undefined : window.Telegram?.WebApp;
  return webApp && webApp.initData ? webApp : null;
}

export const isMiniApp = (): boolean => getWebApp() !== null;
