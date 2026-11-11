import { describe, expect, it } from 'vitest';
import { themeVariables } from './theme';

describe('тема Telegram', () => {
  it('цвета Telegram переходят в переменные веба', () => {
    expect(
      themeVariables({
        bg_color: '#ffffff',
        secondary_bg_color: '#f0f0f0',
        text_color: '#000000',
        hint_color: '#999999',
        link_color: '#2481cc',
      }),
    ).toEqual({
      '--bg': '#f0f0f0',
      '--surface': '#ffffff',
      '--surface-2': '#f0f0f0',
      '--text': '#000000',
      '--muted': '#999999',
      '--link': '#2481cc',
    });
  });

  it('фирменная кнопка и статусы не берутся у Telegram', () => {
    const vars = themeVariables({
      button_color: '#2481cc',
      button_text_color: '#ffffff',
      destructive_text_color: '#ec3942',
    });
    expect(vars).toEqual({});
  });

  it('не заданный Telegram цвет остаётся из CSS', () => {
    expect(themeVariables({})).toEqual({});
  });
});
