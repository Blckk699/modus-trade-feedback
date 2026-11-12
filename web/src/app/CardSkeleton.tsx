/**
 * Каркас карточки на время загрузки: те же блоки, что у обращения, обсуждения и совещания —
 * статусы, значок с заголовком, текст, блок фактов. Содержимое встаёт на свои места без скачка.
 */
export function CardSkeleton({ label }: { label: string }) {
  return (
    <div className="sheet card-skeleton" role="status">
      <span className="sr-only">{label}</span>
      <div className="sheet__head" aria-hidden="true">
        <span className="bone bone--pill" style={{ width: 96 }} />
        <span className="bone bone--pill" style={{ width: 148 }} />
      </div>
      <div className="sheet__scroll" aria-hidden="true">
        <div className="card-skeleton__lead">
          <span className="bone bone--round" />
          <div className="card-skeleton__title">
            <span className="bone bone--title" style={{ width: '88%' }} />
            <span className="bone bone--title" style={{ width: '56%' }} />
            <span className="bone" style={{ width: '44%' }} />
          </div>
        </div>
        <div className="card-skeleton__text">
          <span className="bone" style={{ width: '96%' }} />
          <span className="bone" style={{ width: '90%' }} />
          <span className="bone" style={{ width: '62%' }} />
        </div>
        <span className="bone bone--block" style={{ height: 118 }} />
        <span className="bone bone--block" style={{ height: 62 }} />
        <div className="card-skeleton__text">
          <span className="bone" style={{ width: '28%' }} />
          <span className="bone" style={{ width: '70%' }} />
        </div>
      </div>
    </div>
  );
}
