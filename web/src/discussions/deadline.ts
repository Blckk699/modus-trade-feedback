/**
 * Срок обсуждения выбирается датой; бэкенд ждёт date-time. Берём конец рабочего дня 18:00 по UTC+5 —
 * часовой пояс системы (SPEC: сроки), так срок одинаков для всех клиентов.
 */
export function deadlineFromDate(date: string): string {
  return `${date}T18:00:00+05:00`;
}

/** Дата по умолчанию для поля срока: через N дней, в UTC+5, формат YYYY-MM-DD. */
export function defaultDeadlineDate(days = 3, now: Date = new Date()): string {
  const shifted = new Date(now.getTime() + 5 * 3600_000 + days * 86400_000);
  return shifted.toISOString().slice(0, 10);
}

/** Минимальная дата для поля: сегодня в UTC+5. */
export function todayDate(now: Date = new Date()): string {
  return defaultDeadlineDate(0, now);
}
