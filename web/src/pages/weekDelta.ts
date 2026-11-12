/** Хорошо ли, что показатель вырос: закрытых больше — хорошо, просроченных больше — плохо, поданных — никак. */
export type Growth = 'good' | 'bad' | 'neutral';
export type Tone = 'good' | 'bad' | 'flat';

export interface Delta {
  /** Изменение со знаком: «+3», «−2», «0». Пусто — сравнить не с чем. */
  chip: string;
  tone: Tone;
}

const MINUS = '−';

function tone(diff: number, growth: Growth): Tone {
  if (diff === 0 || growth === 'neutral') return 'flat';
  return diff > 0 === (growth === 'good') ? 'good' : 'bad';
}

/** Изменение счётчика за неделю к предыдущей. */
export function countDelta(now: number, before: number, growth: Growth): Delta {
  const diff = now - before;
  return { chip: diff === 0 ? '0' : `${diff > 0 ? '+' : MINUS}${Math.abs(diff)}`, tone: tone(diff, growth) };
}

/**
 * Изменение среднего времени первого ответа: меньше — лучше. Если в одной из недель ответов не было,
 * сравнивать не с чем. Разницу меньше шести минут считаем нулевой — иначе «+0 ч» при округлении.
 */
export function hoursDelta(now: number | null, before: number | null, format: (h: number) => string): Delta {
  if (now === null || before === null) return { chip: '', tone: 'flat' };
  const diff = now - before;
  if (Math.abs(diff) < 0.1) return { chip: '0', tone: 'flat' };
  return { chip: `${diff > 0 ? '+' : MINUS}${format(Math.abs(diff))}`, tone: tone(diff, 'bad') };
}
