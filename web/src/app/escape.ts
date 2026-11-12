/**
 * Esc внутри окна может относиться к вложенной панели (чат переписки, меню «Ещё»), а не к самому окну.
 * Панель, которая закрылась по Esc, отмечает это здесь, и окно под ней пропускает своё закрытие.
 * Событие cancel у <dialog> приходит сразу после keydown, поэтому отметка живёт долю секунды.
 */
let claimedAt = -Infinity;

export function claimEscape(): void {
  claimedAt = performance.now();
}

export function escapeClaimed(): boolean {
  return performance.now() - claimedAt < 100;
}
