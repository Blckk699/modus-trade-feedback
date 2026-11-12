import type { Schemas } from '../api/types';

type Status = Schemas['AppealStatus'];

/** Склеивать можно, пока оба обращения «Новое» или «На рассмотрении» (SPEC, «Повторы»). */
export const MERGEABLE: Status[] = ['new', 'in_review'];

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
 * разрешено или нет; причину выводим из правил SPEC: статусы обоих обращений и зона ответственного.
 * null — склеить можно.
 */
export function mergeBlockReason(i: Input): string | null {
  if (i.canMergeHere && i.canMergeSuggestion) return null;
  if (!MERGEABLE.includes(i.status)) {
    return `Склеить можно, пока обращение «Новое» или «На рассмотрении». Это сейчас «${i.statusLabel(i.status)}».`;
  }
  if (!MERGEABLE.includes(i.main.status)) {
    return `${i.main.number} сейчас «${i.statusLabel(i.main.status)}». Склеить можно, когда оба обращения «Новое» или «На рассмотрении».`;
  }
  if (!i.canMergeHere) return 'Склеивает ответственный за это обращение, руководитель подразделения или собственник.';
  return `${i.main.number} у другого ответственного: такие повторы склеивает руководитель подразделения или собственник.`;
}
