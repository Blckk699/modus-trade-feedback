import type { Schemas } from '../api/types';
import { dayKey } from '../lib/format';

export type Message = Schemas['Message'];

export interface ChatDay {
  /** Календарный день по UTC+5: «2026-11-12». */
  key: string;
  messages: Message[];
}

/** Сообщения по дням в порядке переписки: между днями окно чата ставит подпись с датой. */
export function chatDays(messages: Message[]): ChatDay[] {
  const days: ChatDay[] = [];
  for (const m of messages) {
    const key = dayKey(m.created_at);
    const last = days[days.length - 1];
    if (last && last.key === key) last.messages.push(m);
    else days.push({ key, messages: [m] });
  }
  return days;
}

/** Аватар стоит у последнего сообщения в ряду одного автора, как в мессенджерах. */
export function endsRun(messages: Message[], index: number): boolean {
  return index === messages.length - 1 || messages[index + 1].author.id !== messages[index].author.id;
}

/** Имя над сообщением нужно, когда автор сменился: подряд идущие сообщения одного человека идут под одним именем. */
export function startsRun(messages: Message[], index: number): boolean {
  return index === 0 || messages[index - 1].author.id !== messages[index].author.id;
}
