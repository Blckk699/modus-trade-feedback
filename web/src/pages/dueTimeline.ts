/**
 * Шкала сроков для экрана «Сегодня»: неделя вперёд от начала сегодняшнего дня, слева — зона «уже просрочено».
 * Только раскладка для показа: сам срок и его состояние посчитал бэкенд.
 */

const DAY = 86_400_000;
/** Часовой пояс системы — UTC+5 (SPEC: сроки). */
const TZ_SHIFT = 5 * 3_600_000;
/** Доля ширины под просроченное: всё, что раньше сегодняшнего дня, встаёт сюда. */
export const OVERDUE_ZONE = 12;
const DAYS = 7;
/** Ширина метки в процентах шкалы — для расчёта, на какую дорожку её поставить. */
const CHIP_W = 13;
const LANES = 3;

export interface DueItem {
  id: number;
  number: string;
  dueAt: string;
}

export interface TimelineChip<T extends DueItem> {
  item: T;
  /** Позиция левого края метки, % ширины шкалы. */
  x: number;
  lane: number;
}

export interface Timeline<T extends DueItem> {
  days: { x: number; label: string }[];
  /** Позиция «сейчас», %. */
  nowX: number;
  chips: TimelineChip<T>[];
  /** Сколько сроков не поместилось: дальше недели или не хватило дорожек. */
  hidden: number;
}

const dayLabel = new Intl.DateTimeFormat('ru-RU', { timeZone: 'Etc/GMT-5', weekday: 'short', day: 'numeric' });

export function startOfDay(now: Date): number {
  return Math.floor((now.getTime() + TZ_SHIFT) / DAY) * DAY - TZ_SHIFT;
}

function position(ms: number, start: number): number {
  if (ms < start) return OVERDUE_ZONE / 2 - CHIP_W / 2 + 1;
  return OVERDUE_ZONE + ((ms - start) / (DAYS * DAY)) * (100 - OVERDUE_ZONE);
}

export function buildTimeline<T extends DueItem>(items: T[], now: Date = new Date()): Timeline<T> {
  const start = startOfDay(now);
  const end = start + DAYS * DAY;
  const days = Array.from({ length: DAYS }, (_, i) => ({
    x: OVERDUE_ZONE + (i / DAYS) * (100 - OVERDUE_ZONE),
    label: dayLabel.format(new Date(start + i * DAY)),
  }));

  const sorted = [...items].sort((a, b) => new Date(a.dueAt).getTime() - new Date(b.dueAt).getTime());
  const laneEnd: number[] = Array(LANES).fill(-Infinity);
  const chips: TimelineChip<T>[] = [];
  let hidden = 0;
  for (const item of sorted) {
    const ms = new Date(item.dueAt).getTime();
    if (ms >= end) {
      hidden++;
      continue;
    }
    const x = Math.min(position(ms, start), 100 - CHIP_W);
    const lane = laneEnd.findIndex((e) => e <= x);
    if (lane < 0) {
      hidden++;
      continue;
    }
    laneEnd[lane] = x + CHIP_W + 0.5;
    chips.push({ item, x, lane });
  }
  return { days, nowX: position(now.getTime(), start), chips, hidden };
}
