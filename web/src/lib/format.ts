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
