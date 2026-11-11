import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { DueBadge, StatusBadge } from '../appeals/Badges';
import { formatDate } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { useReloadOnCardClose } from '../app/cardClosed';

type Item = Schemas['AppealListItem'];
const PAGE_SIZE = 20;

function fetchPage(page: number) {
  return unwrap(
    api.GET('/api/v1/appeals', {
      params: { query: { scope: 'mine', sort: 'created_desc', page, page_size: PAGE_SIZE } },
    }),
  );
}

export function MyAppealsPage() {
  const first = useAsync(() => fetchPage(1), []);
  useReloadOnCardClose(first.reload);
  const [more, setMore] = useState<Item[]>([]);
  const [page, setPage] = useState(1);
  const [loadingMore, setLoadingMore] = useState(false);
  const [moreError, setMoreError] = useState('');

  async function loadMore() {
    setLoadingMore(true);
    setMoreError('');
    try {
      const next = await fetchPage(page + 1);
      setMore((m) => [...m, ...next.items]);
      setPage(page + 1);
    } catch (e) {
      setMoreError(errorMessage(e));
    } finally {
      setLoadingMore(false);
    }
  }

  const s = first.state;
  return (
    <section className="page">
      <div className="page__head">
        <h1 className="page__title sr-only">Мои обращения</h1>
        <Link to="/my/new" className="btn btn--accent">
          Подать обращение
        </Link>
      </div>

      {s.status === 'loading' && <p className="muted">Загружаем…</p>}
      {s.status === 'error' && (
        <div className="notice">
          <p className="error-text">{s.message}</p>
          <button type="button" className="btn btn--ghost" onClick={first.reload}>
            Повторить
          </button>
        </div>
      )}
      {s.status === 'ready' && s.data.total === 0 && (
        <div className="notice">
          <p>Вы ещё не подавали обращений.</p>
          <p className="muted">Расскажите о проблеме, предложите улучшение или отметьте то, что работает хорошо.</p>
        </div>
      )}
      {s.status === 'ready' && s.data.total > 0 && (
        <>
          <ul className="appeal-list">
            {[...s.data.items, ...more].map((a) => (
              <AppealRow key={a.id} item={a} />
            ))}
          </ul>
          {s.data.items.length + more.length < s.data.total && (
            <div className="form__actions">
              <button type="button" className="btn btn--ghost" onClick={loadMore} disabled={loadingMore}>
                {loadingMore ? 'Загружаем…' : 'Показать ещё'}
              </button>
              {moreError && <span className="error-text">{moreError}</span>}
            </div>
          )}
        </>
      )}
    </section>
  );
}

function AppealRow({ item }: { item: Item }) {
  const dict = useDictionaries();
  const location = useLocation();
  return (
    <li>
      <Link to={`/appeals/${item.id}`} state={{ from: '/my', background: location }} className="appeal-row">
        <div className="appeal-row__top">
          <span className="appeal-row__number">{item.number}</span>
          {item.has_unread && <span className="dot" aria-label="Есть новое" title="Есть новое" />}
          <span className="muted">{dict.typeLabel(item.type)}</span>
          <span className="muted appeal-row__date">{formatDate(item.created_at)}</span>
        </div>
        <div className="appeal-row__summary">{item.summary ?? 'Без краткой сути'}</div>
        <div className="appeal-row__meta">
          <StatusBadge status={item.status} />
          {item.status !== 'closed' && <DueBadge state={item.due_state} dueAt={item.first_response_due_at} />}
          {item.merged_into && <span className="muted">Присоединено к {item.merged_into.number}</span>}
        </div>
      </Link>
    </li>
  );
}
