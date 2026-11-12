import type { Schemas } from '../api/types';
import { dayKey } from '../lib/format';

type HistoryEvent = Schemas['HistoryEvent'];

export interface HistoryDay {
  /** Календарный день по UTC+5: «2026-11-12». */
  key: string;
  events: HistoryEvent[];
}

/** События по дням в порядке времени: дата пишется один раз над группой, у событий остаётся время. */
export function historyDays(events: HistoryEvent[]): HistoryDay[] {
  const days: HistoryDay[] = [];
  for (const ev of events) {
    const key = dayKey(ev.created_at);
    const last = days[days.length - 1];
    if (last && last.key === key) last.events.push(ev);
    else days.push({ key, events: [ev] });
  }
  return days;
}

const KEY = 'modus.history_open';

type Store = Pick<Storage, 'getItem' | 'setItem'>;

/** Хранилище браузера. Само обращение к window.localStorage может бросить (песочница, запрет хранилища). */
const browserStore = (): Store | null => (typeof window === 'undefined' ? null : window.localStorage);

/** Раскрыта ли история: выбор запоминается, чтобы не раскрывать её в каждой карточке заново. */
export function readHistoryOpen(store: () => Store | null = browserStore): boolean {
  try {
    return store()?.getItem(KEY) === '1';
  } catch {
    return false;
  }
}

export function writeHistoryOpen(open: boolean, store: () => Store | null = browserStore): void {
  try {
    store()?.setItem(KEY, open ? '1' : '0');
  } catch {
    /* хранилище недоступно — выбор живёт до закрытия карточки */
  }
}
