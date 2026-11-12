import { useState } from 'react';
import { Link } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useBackground } from '../app/background';
import { useAsync } from '../lib/useAsync';
import { StatusBadge } from './Badges';

type Appeal = Schemas['Appeal'];
type Suggestion = Schemas['DuplicateSuggestion'];

interface Props {
  appeal: Appeal;
  /** После склейки — перечитать карточку: повтор становится «Закрыто» со ссылкой на основное. */
  onMerged: (main: Appeal) => void;
}

/**
 * Подсказки о похожих обращениях (истории 34–36). Бэкенд сам решает, кому их показывать
 * (автору — пустой список), и можно ли склеить сейчас (can_merge).
 */
export function DuplicatesSection({ appeal, onMerged }: Props) {
  const list = useAsync(
    () => unwrap(api.GET('/api/v1/appeals/{appeal_id}/similar', { params: { path: { appeal_id: appeal.id } } })),
    [appeal.id, appeal.updated_at],
  );
  const background = useBackground();
  const [busy, setBusy] = useState<number | null>(null);
  const [error, setError] = useState('');

  if (list.state.status === 'error' && list.state.error instanceof ApiError && list.state.error.status === 403) return null;
  if (list.state.status !== 'ready' && list.state.status !== 'error') return null;
  if (list.state.status === 'ready' && list.state.data.length === 0) return null;

  const canMerge = appeal.allowed_actions.includes('merge');

  async function merge(s: Suggestion) {
    setBusy(s.id);
    setError('');
    try {
      const main = await unwrap(
        api.POST('/api/v1/appeals/{appeal_id}/merge', {
          params: { path: { appeal_id: appeal.id } },
          body: { main_appeal_id: s.similar_appeal.id },
        }),
      );
      onMerged(main);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(null);
    }
  }

  async function dismiss(s: Suggestion) {
    setBusy(s.id);
    setError('');
    try {
      await unwrap(
        api.POST('/api/v1/duplicate-suggestions/{suggestion_id}/dismiss', { params: { path: { suggestion_id: s.id } } }),
      );
      if (list.state.status === 'ready') list.set(list.state.data.filter((x) => x.id !== s.id));
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(null);
    }
  }

  return (
    <section className="section">
      <h2 className="section__title">Похожие обращения</h2>
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {list.state.status === 'ready' && (
        <ul className="suggestions">
          {list.state.data.map((s) => (
            <li key={s.id} className="suggestion">
              <div className="suggestion__head">
                <Link to={`/appeals/${s.similar_appeal.id}`} state={{ background }} className="suggestion__link">
                  <span className="muted">{s.similar_appeal.number}</span> {s.similar_appeal.summary ?? 'Без краткой сути'}
                </Link>
                <StatusBadge status={s.similar_appeal.status} />
              </div>
              <p className="muted suggestion__why">{s.explanation}</p>
              <div className="form__actions">
                {canMerge && s.can_merge && (
                  <button type="button" className="btn btn--sm" disabled={busy !== null} onClick={() => merge(s)}>
                    Присоединить к {s.similar_appeal.number}
                  </button>
                )}
                <button type="button" className="btn btn--soft btn--sm" disabled={busy !== null} onClick={() => dismiss(s)}>
                  Это другое
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
    </section>
  );
}
