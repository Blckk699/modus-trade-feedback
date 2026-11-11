import type { ThemeParams, WebApp } from './webApp';

/**
 * Переменные темы веба (styles/global.css) ← цвета Telegram. Не заданный Telegram цвет остаётся из CSS.
 * Берём у Telegram только фон, текст, подсказки, разделители и ссылки — Mini App выглядит продолжением чата.
 * Фирменная красная кнопка (--accent), primary, статусы и danger/warn/success остаются нашими
 * и переключаются по colorScheme через data-theme (design/README.md, раздел про Mini App).
 */
const MAPPING: [cssVar: string, key: keyof ThemeParams][] = [
  ['--bg', 'secondary_bg_color'],
  ['--surface', 'bg_color'],
  ['--surface-2', 'secondary_bg_color'],
  ['--text', 'text_color'],
  ['--muted', 'hint_color'],
  ['--border', 'section_separator_color'],
  ['--link', 'link_color'],
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
