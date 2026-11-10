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
        button_color: '#2481cc',
        button_text_color: '#ffffff',
      }),
    ).toEqual({
      '--bg': '#f0f0f0',
      '--surface': '#ffffff',
      '--surface-2': '#f0f0f0',
      '--text': '#000000',
      '--muted': '#999999',
      '--accent': '#2481cc',
      '--accent-text': '#ffffff',
    });
  });

  it('не заданный Telegram цвет остаётся из CSS', () => {
    expect(themeVariables({})).toEqual({});
  });
});
