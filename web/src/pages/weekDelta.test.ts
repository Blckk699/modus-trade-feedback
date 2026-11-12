import { describe, expect, it } from 'vitest';
import { countDelta, hoursDelta } from './weekDelta';

const hours = (h: number) => `${h} ч`;

describe('неделя к неделе', () => {
  it('закрытых стало больше — хорошо', () => {
    expect(countDelta(8, 5, 'good')).toEqual({ chip: '+3', tone: 'good' });
  });

  it('просроченных стало больше — плохо, меньше — хорошо', () => {
    expect(countDelta(4, 1, 'bad')).toEqual({ chip: '+3', tone: 'bad' });
    expect(countDelta(1, 4, 'bad')).toEqual({ chip: '−3', tone: 'good' });
  });

  it('поданных больше или меньше — без оценки', () => {
    expect(countDelta(12, 7, 'neutral')).toEqual({ chip: '+5', tone: 'flat' });
  });

  it('без изменений — ноль без оценки', () => {
    expect(countDelta(3, 3, 'bad')).toEqual({ chip: '0', tone: 'flat' });
  });

  it('первый ответ стал быстрее — хорошо', () => {
    expect(hoursDelta(2, 5, hours)).toEqual({ chip: '−3 ч', tone: 'good' });
    expect(hoursDelta(5, 2, hours)).toEqual({ chip: '+3 ч', tone: 'bad' });
  });

  it('в одной из недель ответов не было — сравнения нет', () => {
    expect(hoursDelta(null, 5, hours)).toEqual({ chip: '', tone: 'flat' });
    expect(hoursDelta(5, null, hours)).toEqual({ chip: '', tone: 'flat' });
  });

  it('разница в пару минут — ноль', () => {
    expect(hoursDelta(2.04, 2, hours)).toEqual({ chip: '0', tone: 'flat' });
  });
});
