import { useState } from 'react';
import { Link } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useBackground } from '../app/background';
import { useReloadOnCardClose } from '../app/cardClosed';
import { EmptyState } from '../app/EmptyState';
import { LoadError, RowsSkeleton } from '../app/ListStates';
import { PageHead } from '../app/PageHead';
import { AppealRow } from '../appeals/AppealRow';
import { OPEN_STATUSES, type Status } from '../appeals/scopes';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';

type Item = Schemas['AppealListItem'];
type Filter = 'all' | 'open' | 'done';
const PAGE_SIZE = 20;

const FILTERS: { id: Filter; label: string; status?: Status[] }[] = [
  { id: 'all', label: 'Все' },
  { id: 'open', label: 'В работе', status: OPEN_STATUSES },
  { id: 'done', label: 'Завершённые', status: ['implemented', 'rejected', 'closed'] },
];

function fetchPage(filter: Filter, page: number) {
  const status = FILTERS.find((f) => f.id === filter)?.status;
  return unwrap(
    api.GET('/api/v1/appeals', {
      params: { query: { scope: 'mine', sort: 'created_desc', status, page, page_size: PAGE_SIZE } },
    }),
  );
}

/** Обращения, которые подал пользователь: что с ними сейчас и чем закончились. */
export function MyAppealsPage() {
  const [filter, setFilter] = useState<Filter>('all');
  const first = useAsync(() => fetchPage(filter, 1), [filter]);
  const background = useBackground();
  useReloadOnCardClose(first.reload);
  const [extra, setExtra] = useState<{ filter: Filter; page: number; items: Item[] }>({ filter, page: 1, items: [] });
  const more = extra.filter === filter ? extra : { filter, page: 1, items: [] };
  const [loadingMore, setLoadingMore] = useState(false);
  const [moreError, setMoreError] = useState('');

  async function loadMore() {
    setLoadingMore(true);
    setMoreError('');
    try {
      const next = await fetchPage(filter, more.page + 1);
      setExtra({ filter, page: more.page + 1, items: [...more.items, ...next.items] });
    } catch (e) {
      setMoreError(errorMessage(e));
    } finally {
      setLoadingMore(false);
    }
  }

  const s = first.state;
  const total = s.status === 'ready' ? s.data.total : null;
  const newAppeal = (
    <Link to="/my/new" state={{ background }} className="btn">
      Подать обращение
    </Link>
  );

  return (
    <section className="page">
      <PageHead
        over={total === null ? 'Загружаем…' : `${total} ${plural(total, ['обращение', 'обращения', 'обращений'])}`}
        title="Мои обращения"
      />

      <div className="toolbar">
        <div className="segmented" role="radiogroup" aria-label="Какие обращения показать">
          {FILTERS.map((f) => (
            <label key={f.id} className="segmented__item">
              <input type="radio" name="my-filter" checked={filter === f.id} onChange={() => setFilter(f.id)} />
              <span>{f.label}</span>
            </label>
          ))}
        </div>
      </div>

      {s.status === 'loading' && <RowsSkeleton />}
      {s.status === 'error' && <LoadError message={s.message} onRetry={first.reload} />}
      {s.status === 'ready' && s.data.total === 0 && filter === 'all' && (
        <EmptyState icon="inbox" title="Вы ещё ничего не подавали" action={newAppeal}>
          Расскажите о проблеме, предложите улучшение или отметьте хорошую работу. Ответственный ответит в срок.
        </EmptyState>
      )}
      {s.status === 'ready' && s.data.total === 0 && filter !== 'all' && (
        <EmptyState icon="search" title={filter === 'open' ? 'В работе ничего нет' : 'Завершённых пока нет'} />
      )}
      {s.status === 'ready' && s.data.total > 0 && (
        <>
          <div className="card list-card">
            <ul className="rows">
              {[...s.data.items, ...more.items].map((a) => (
                <AppealRow key={a.id} item={a} view="mine" />
              ))}
            </ul>
          </div>
          {s.data.items.length + more.items.length < s.data.total && (
            <div className="list-foot">
              <button type="button" className="btn btn--soft" onClick={loadMore} disabled={loadingMore}>
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
