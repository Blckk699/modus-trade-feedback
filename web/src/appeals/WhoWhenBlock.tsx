import { Link } from 'react-router-dom';
import type { Schemas } from '../api/types';
import { useMe } from '../auth';
import { dueExplanation, whoWhen } from './whoWhen';

/** «Что дальше» для автора: кто рассмотрит, ориентир по сроку, шаги и куда придёт ответ. */
export function WhoWhenBlock({ appeal }: { appeal: Schemas['Appeal'] }) {
  const me = useMe();
  const linked = me.telegram_linked;
  const w = whoWhen(appeal, linked);
  return (
    <section className="whowhen" aria-label="Что дальше">
      <dl className="whowhen__facts">
        <div>
          <dt>Кто рассмотрит</dt>
          <dd>{w.who}</dd>
        </div>
        <div>
          <dt>Когда</dt>
          <dd>{w.when}</dd>
        </div>
      </dl>
      {w.steps.length > 0 && (
        <ol className="whowhen__steps">
          {w.steps.map((s) => (
            <li key={s}>{s}</li>
          ))}
        </ol>
      )}
      <p className="whowhen__where">
        {w.where}
        {!linked && (
          <>
            {' '}
            <Link to="/profile">Открыть профиль</Link>
          </>
        )}
      </p>
    </section>
  );
}

/** Подсказка у срока первого ответа: что значит срок и что будет при просрочке. */
export function DueHint({ escalationLevel }: { escalationLevel: number }) {
  const d = dueExplanation(escalationLevel);
  return (
    <details className="due-hint">
      <summary>Что будет при просрочке</summary>
      <p>{d.rule}</p>
      {d.now && <p className="due-hint__now">{d.now}</p>}
    </details>
  );
}
