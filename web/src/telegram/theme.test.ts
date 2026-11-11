import { describe, expect, it, vi } from 'vitest';
import { frameColors, syncTelegramFrame } from './theme';
import type { WebApp } from './webApp';

const vars = (map: Record<string, string>) => (name: string) => map[name] ?? '';

function fakeWebApp(isVersionAtLeast: (v: string) => boolean = () => true) {
  return {
    platform: 'ios',
    colorScheme: 'light',
    // Тема Telegram намеренно другая: она не должна попасть ни в рамку, ни в наши переменные.
    themeParams: { bg_color: '#17212b', text_color: '#f5f5f5', link_color: '#6ab3f3' },
    isVersionAtLeast,
    setHeaderColor: vi.fn(),
    setBackgroundColor: vi.fn(),
    setBottomBarColor: vi.fn(),
  } as unknown as WebApp & Record<'setHeaderColor' | 'setBackgroundColor' | 'setBottomBarColor', ReturnType<typeof vi.fn>>;
}

describe('Mini App в наших цветах', () => {
  it('рамка Telegram берёт цвета нашей темы: шапка и нижняя полоса — поверхность, фон — фон страницы', () => {
    expect(frameColors(vars({ '--surface': ' #FFFFFF', '--bg': '#f4f7fb' }))).toEqual({
      header: '#ffffff',
      background: '#f4f7fb',
      bottomBar: '#ffffff',
    });
  });

  it('значения не в виде #RRGGBB Telegram не передаются', () => {
    expect(frameColors(vars({ '--surface': 'color-mix(in srgb, red 5%, white)', '--bg': '#fff' }))).toEqual({
      header: undefined,
      background: undefined,
      bottomBar: undefined,
    });
  });

  it('рамка красится нашими цветами тёмной темы, а не цветами Telegram', () => {
    const webApp = fakeWebApp();
    syncTelegramFrame(webApp, vars({ '--surface': '#0d2236', '--bg': '#071521' }));
    expect(webApp.setHeaderColor).toHaveBeenCalledWith('#0d2236');
    expect(webApp.setBackgroundColor).toHaveBeenCalledWith('#071521');
    expect(webApp.setBottomBarColor).toHaveBeenCalledWith('#0d2236');
  });

  it('старый клиент Telegram: вызываются только поддерживаемые методы', () => {
    const webApp = fakeWebApp((v) => v === '6.1');
    syncTelegramFrame(webApp, vars({ '--surface': '#ffffff', '--bg': '#f4f7fb' }));
    expect(webApp.setHeaderColor).not.toHaveBeenCalled();
    expect(webApp.setBottomBarColor).not.toHaveBeenCalled();
    expect(webApp.setBackgroundColor).toHaveBeenCalledWith('#f4f7fb');
  });
});
