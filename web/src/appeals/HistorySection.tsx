import { useId, useState } from 'react';
import { ChevronDown } from 'lucide-react';
import { api, unwrap } from '../api/client';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatChatDay, formatDateTime, formatTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { historyDays, readHistoryOpen, writeHistoryOpen } from './history';
import { historyValue } from './historyValue';
import { historyKindLabel } from './labels';

type HistoryEvent = Schemas['HistoryEvent'];

const storage = () => (typeof window === 'undefined' ? null : window.localStorage);

/**
 * История событий — раскрывающийся блок. В свёрнутом виде видно, сколько событий и какое последнее;
 * в раскрытом — лента по дням в порядке времени. Выбор «раскрыто или свёрнуто» запоминается.
 * version — перечитать после изменения обращения.
 */
export function HistorySection({ appealId, version }: { appealId: number; version: string }) {
  const history = useAsync(
    () => unwrap(api.GET('/api/v1/appeals/{appeal_id}/history', { params: { path: { appeal_id: appealId } } })),
    [appealId, version],
  );
  const [open, setOpen] = useState(() => readHistoryOpen(storage()));
  const listId = useId();
  const events = history.state.status === 'ready' ? history.state.data : [];
  const last = events[events.length - 1];

  const toggle = () => {
    writeHistoryOpen(storage(), !open);
    setOpen(!open);
  };

  return (
    <section className="section history">
      <h2 className="history__heading">
        <button type="button" className="history__toggle" aria-expanded={open} aria-controls={listId} onClick={toggle}>
          <span className="history__title">
            История
            {events.length > 0 && <span className="section__count">{events.length}</span>}
          </span>
          {!open && last && (
            <span className="history__last">
              {historyKindLabel[last.kind] ?? last.kind} · {formatDateTime(last.created_at)}
            </span>
          )}
          {history.state.status === 'loading' && <span className="history__last">Загружаем…</span>}
          <ChevronDown size={18} className="history__chevron" aria-hidden="true" />
        </button>
      </h2>
      {history.state.status === 'error' && <p className="error-text">{history.state.message}</p>}
      {open && history.state.status === 'ready' && (
        <ol id={listId} className="timeline" aria-label="История">
          {historyDays(events).map((day) => (
            <li key={day.key} className="timeline__day">
              <span className="timeline__date">{formatChatDay(day.events[0].created_at)}</span>
              <ol className="timeline__events">
                {day.events.map((ev) => (
                  <HistoryItem key={ev.id} ev={ev} />
                ))}
              </ol>
            </li>
          ))}
        </ol>
      )}
    </section>
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
        <span className="timeline__time">
          {ev.actor ? ev.actor.full_name : 'Система'} · <time dateTime={ev.created_at}>{formatTime(ev.created_at)}</time>
        </span>
      </div>
      {change && <div className="timeline__change">{change}</div>}
      {ev.comment && <div className="timeline__comment">{ev.comment}</div>}
    </li>
  );
}
