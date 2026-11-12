import type { Schemas } from '../api/types';

type Status = Schemas['AppealStatus'];

/** Повтор присоединяют, пока его ещё не начали разбирать. */
export const MERGEABLE: Status[] = ['new', 'in_review'];

/** Основное может быть в любом незавершённом статусе (B-25 п.2); к завершённому присоединить нельзя. */
export const FINISHED: Status[] = ['implemented', 'rejected', 'closed'];

interface Input {
  /** Номер и статус открытой карточки (повтор). */
  status: Status;
  /** Есть ли merge в allowed_actions открытой карточки. */
  canMergeHere: boolean;
  /** Подсказка: номер и статус основного, can_merge от сервера. */
  main: { number: string; status: Status };
  canMergeSuggestion: boolean;
  statusLabel: (s: string) => string;
}

/**
 * Почему склейка сейчас недоступна — вместо того чтобы прятать кнопку. Сервер отдаёт только
 * разрешено или нет; причину выводим из правил склейки: статус повтора, завершено ли основное, зона ответственного.
 * null — склеить можно.
 */
export function mergeBlockReason(i: Input): string | null {
  if (i.canMergeHere && i.canMergeSuggestion) return null;
  if (!MERGEABLE.includes(i.status)) {
    return `Склеить можно, пока обращение «Новое» или «На рассмотрении». Это сейчас «${i.statusLabel(i.status)}».`;
  }
  if (FINISHED.includes(i.main.status)) {
    return `${i.main.number} уже завершено («${i.statusLabel(i.main.status)}»): к нему повтор не присоединить.`;
  }
  if (!i.canMergeHere) return 'Склеивает ответственный за это обращение, руководитель подразделения или собственник.';
  return `${i.main.number} у другого ответственного: такие повторы склеивает руководитель подразделения или собственник.`;
}
