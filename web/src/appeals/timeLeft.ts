/**
 * Сколько осталось до срока первого ответа — подпись для очереди.
 * Сам срок и его состояние (due_state) считает бэкенд в рабочих днях; здесь только разница во времени для показа.
 */
export function timeLeftLabel(dueAt: string, now: Date = new Date()): string {
  const diffMin = Math.round((new Date(dueAt).getTime() - now.getTime()) / 60_000);
  const abs = Math.abs(diffMin);
  const days = Math.floor(abs / 1440);
  const hours = Math.floor((abs % 1440) / 60);
  const mins = abs % 60;
  const span = days > 0 ? `${days} д ${hours} ч` : hours > 0 ? `${hours} ч ${mins} мин` : `${mins} мин`;
  return diffMin >= 0 ? `осталось ${span}` : `просрочено на ${span}`;
}
