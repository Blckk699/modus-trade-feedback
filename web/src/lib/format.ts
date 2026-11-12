/** Часовой пояс системы — UTC+5 (SPEC: сроки и эскалация). Etc/GMT-5 и есть UTC+5. */
const TZ = 'Etc/GMT-5';

const dateTime = new Intl.DateTimeFormat('ru-RU', {
  timeZone: TZ,
  day: 'numeric',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
});
const dateOnly = new Intl.DateTimeFormat('ru-RU', { timeZone: TZ, day: 'numeric', month: 'long', year: 'numeric' });

const dayShort = new Intl.DateTimeFormat('ru-RU', { timeZone: TZ, day: 'numeric', month: 'short' });
const dayShortYear = new Intl.DateTimeFormat('ru-RU', { timeZone: TZ, day: 'numeric', month: 'short', year: 'numeric' });
const yearOf = new Intl.DateTimeFormat('ru-RU', { timeZone: TZ, year: 'numeric' });

/** Короткая дата для строк списков: «12 нояб.», а для прошлых лет — «12 нояб. 2025 г.». */
export function formatDay(iso: string | null | undefined, now: Date = new Date()): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return yearOf.format(d) === yearOf.format(now) ? dayShort.format(d) : dayShortYear.format(d);
}

const timeOnly = new Intl.DateTimeFormat('ru-RU', { timeZone: TZ, hour: '2-digit', minute: '2-digit' });
const dayLong = new Intl.DateTimeFormat('ru-RU', { timeZone: TZ, day: 'numeric', month: 'long' });
const dayIso = new Intl.DateTimeFormat('en-CA', { timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit' });

/** Время сообщения: «14:06». */
export function formatTime(iso: string): string {
  return timeOnly.format(new Date(iso));
}

/** Календарный день по UTC+5 в виде «2026-11-12»: по нему сообщения делятся на дни. */
export function dayKey(iso: string | Date): string {
  return dayIso.format(typeof iso === 'string' ? new Date(iso) : iso);
}

/** Подпись дня в переписке: «Сегодня», «Вчера», «9 ноября», а для прошлых лет — «30 декабря 2025 г.». */
export function formatChatDay(iso: string, now: Date = new Date()): string {
  const key = dayKey(iso);
  if (key === dayKey(now)) return 'Сегодня';
  if (key === dayKey(new Date(now.getTime() - 24 * 60 * 60 * 1000))) return 'Вчера';
  const d = new Date(iso);
  return yearOf.format(d) === yearOf.format(now) ? dayLong.format(d) : dateOnly.format(d);
}

export function formatDateTime(iso: string | null | undefined): string {
  return iso ? dateTime.format(new Date(iso)) : '—';
}

export function formatDate(iso: string | null | undefined): string {
  return iso ? dateOnly.format(new Date(iso)) : '—';
}

export function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} Б`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} КБ`;
  return `${(bytes / 1024 / 1024).toFixed(1).replace('.', ',')} МБ`;
}
