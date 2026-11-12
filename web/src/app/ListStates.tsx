/** Заглушка списка на время загрузки: несколько мерцающих строк вместо слова «Загружаем». */
export function RowsSkeleton({ rows = 4 }: { rows?: number }) {
  return (
    <div className="rows-skeleton" role="status">
      <span className="sr-only">Загружаем…</span>
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="skeleton skeleton--row" />
      ))}
    </div>
  );
}

/** Ошибка загрузки с кнопкой «Повторить». */
export function LoadError({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="card notice-card" role="alert">
      <p className="error-text">{message}</p>
      {onRetry && (
        <button type="button" className="btn btn--soft" onClick={onRetry}>
          Повторить
        </button>
      )}
    </div>
  );
}
