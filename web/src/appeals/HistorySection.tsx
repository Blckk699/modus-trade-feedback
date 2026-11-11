import { api, unwrap } from '../api/client';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { historyValue } from './historyValue';
import { historyKindLabel } from './labels';

type HistoryEvent = Schemas['HistoryEvent'];

/** История событий по возрастанию времени. version — перечитать после изменения обращения. */
export function HistorySection({ appealId, version }: { appealId: number; version: string }) {
  const history = useAsync(
    () => unwrap(api.GET('/api/v1/appeals/{appeal_id}/history', { params: { path: { appeal_id: appealId } } })),
    [appealId, version],
  );

  return (
    <div className="block">
      <h2 className="block__title">История</h2>
      {history.state.status === 'loading' && <p className="muted">Загружаем…</p>}
      {history.state.status === 'error' && <p className="error-text">{history.state.message}</p>}
      {history.state.status === 'ready' && (
        <ol className="timeline" aria-label="История">
          {history.state.data.map((ev) => (
            <HistoryItem key={ev.id} ev={ev} />
          ))}
        </ol>
      )}
    </div>
  );
}

function HistoryItem({ ev }: { ev: HistoryEvent }) {
  const dict = useDictionaries();
  const value = (v: string | null) => historyValue(ev.field, v, dict);
  const change =
    ev.old_value || ev.new_value
      ? [value(ev.old_value), value(ev.new_value)].filter(Boolean).join(' → ')
      : null;

  return (
    <li className="timeline__item">
      <div className="timeline__head">
        <span className="timeline__title">{historyKindLabel[ev.kind] ?? ev.kind}</span>
        <span className="muted">{formatDateTime(ev.created_at)}</span>
      </div>
      {change && <div>{change}</div>}
      {ev.comment && <div className="muted">{ev.comment}</div>}
      <div className="muted timeline__actor">{ev.actor ? ev.actor.full_name : 'Система'}</div>
    </li>
  );
}
