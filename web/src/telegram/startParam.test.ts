import { describe, expect, it } from 'vitest';
import { pathFromStartParam, startParamFromPath } from './startParam';

describe('startapp ↔ маршрут', () => {
  it('ссылка из уведомления открывает карточку обращения', () => {
    expect(pathFromStartParam('appeals_21')).toBe('/appeals/21');
    expect(pathFromStartParam('discussions_5')).toBe('/discussions/5');
  });

  it('ссылка из сводки открывает экран аналитики веба', () => {
    expect(pathFromStartParam('analytics')).toBe('/digest');
  });

  it('пустой или чужой параметр игнорируется', () => {
    expect(pathFromStartParam(undefined)).toBeNull();
    expect(pathFromStartParam('')).toBeNull();
    expect(pathFromStartParam('../evil')).toBeNull();
    expect(pathFromStartParam('a b')).toBeNull();
  });

  it('обратное преобразование для ссылок t.me', () => {
    expect(startParamFromPath('/appeals/21')).toBe('appeals_21');
    expect(startParamFromPath('/analytics')).toBe('analytics');
  });
});
