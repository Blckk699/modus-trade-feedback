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

export interface WebApp {
  initData: string;
  initDataUnsafe: { start_param?: string };
  platform: string;
  colorScheme: 'light' | 'dark';
  themeParams: ThemeParams;
  ready(): void;
  expand(): void;
  onEvent(event: 'themeChanged', cb: () => void): void;
  offEvent(event: 'themeChanged', cb: () => void): void;
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
