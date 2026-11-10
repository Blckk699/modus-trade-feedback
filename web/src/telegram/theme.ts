import type { ThemeParams, WebApp } from './webApp';

/** Переменные темы веба (styles/global.css) ← цвета Telegram. Не заданный Telegram цвет остаётся из CSS. */
const MAPPING: [cssVar: string, key: keyof ThemeParams][] = [
  ['--bg', 'secondary_bg_color'],
  ['--surface', 'bg_color'],
  ['--surface-2', 'secondary_bg_color'],
  ['--text', 'text_color'],
  ['--muted', 'hint_color'],
  ['--border', 'section_separator_color'],
  ['--accent', 'button_color'],
  ['--accent-text', 'button_text_color'],
  ['--danger', 'destructive_text_color'],
];

export function themeVariables(params: ThemeParams): Record<string, string> {
  const vars: Record<string, string> = {};
  for (const [cssVar, key] of MAPPING) {
    const value = params[key];
    if (value) vars[cssVar] = value;
  }
  return vars;
}

/** Применить тему Telegram к <html>: inline-стиль сильнее правил :root и [data-theme]. */
export function applyTelegramTheme(webApp: WebApp, root: HTMLElement = document.documentElement): void {
  for (const [cssVar, value] of Object.entries(themeVariables(webApp.themeParams))) {
    root.style.setProperty(cssVar, value);
  }
  root.style.setProperty('color-scheme', webApp.colorScheme);
  root.setAttribute('data-theme', webApp.colorScheme);
  root.setAttribute('data-telegram', webApp.platform || 'unknown');
}
