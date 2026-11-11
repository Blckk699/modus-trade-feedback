import { formatDateTime } from '../lib/format';

/** Дата-время ISO 8601, как бэкенд пишет сроки в историю: 2026-11-18T09:55:15.058981+05:00. */
const ISO_DATE_TIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/;

interface Labels {
  statusLabel: (code: string) => string;
  typeLabel: (code: string) => string;
  priorityLabel: (code: string) => string;
}

/**
 * Значение «было/стало» в истории обращения для показа человеку: коды статуса, типа и приоритета —
 * русскими подписями из /dictionaries, даты (например, срок у deadline_set) — в UTC+5, остальное как есть.
 */
export function historyValue(field: string | null, value: string | null, labels: Labels): string | null {
  if (!value) return value;
  if (field === 'status') return labels.statusLabel(value);
  if (field === 'type') return labels.typeLabel(value);
  if (field === 'priority') return labels.priorityLabel(value);
  if (ISO_DATE_TIME.test(value) && !Number.isNaN(Date.parse(value))) return formatDateTime(value);
  return value;
}
