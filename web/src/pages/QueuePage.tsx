import { useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useReloadOnCardClose } from '../app/cardClosed';
import { useDictionaries } from '../app/dictionaries';
import { EmptyState } from '../app/EmptyState';
import { LoadError, RowsSkeleton } from '../app/ListStates';
import { PageHead } from '../app/PageHead';
import { Select } from '../app/Select';
import { AppealRow } from '../appeals/AppealRow';
import { defaultScope, OPEN_STATUSES, queueScopes, SCOPE_LABEL, type Scope, type Status } from '../appeals/scopes';
import { useMe } from '../auth';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';

type DueFilter = Schemas['DueFilter'];
type Item = Schemas['AppealListItem'];

const PAGE_SIZE = 30;
const DUE: DueFilter[] = ['overdue', 'due_today', 'due_week', 'no_deadline'];
const STATUSES: Status[] = ['new', 'in_review', 'awaiting_info', 'in_progress', 'implemented', 'rejected', 'closed'];

interface Filters {
  scope: Scope;
  status: 'open' | 'any' | Status;
  categoryId: string;
  departmentId: string;
  due: '' | DueFilter;
}

function fetchQueue(f: Filters, page: number) {
  const status = f.status === 'open' ? OPEN_STATUSES : f.status === 'any' ? undefined : [f.status];
  return unwrap(
    api.GET('/api/v1/appeals', {
      params: {
        query: {
          scope: f.scope,
          sort: 'due_asc',
          status,
          category_id: f.categoryId ? Number(f.categoryId) : undefined,
          department_id: f.departmentId ? Number(f.departmentId) : undefined,
          due: f.due || undefined,
          page,
          page_size: PAGE_SIZE,
        },
      },
    }),
  );
}

/**
 * Входящие: обращения, с которыми пользователь работает, по сроку ответа. Фильтры живут в адресе
 * (?scope=assigned&due=overdue), поэтому плитки «Сегодня» и сводки ведут прямо в нужный срез.
 */
export function QueuePage() {
  const me = useMe();
  const dict = useDictionaries();
  const scopes = queueScopes(me);
  const [params, setParams] = useSearchParams();
  const fallback = defaultScope(me) ?? 'assigned';

  const filters: Filters = {
    scope: scopes.includes(params.get('scope') as Scope) ? (params.get('scope') as Scope) : fallback,
    status: (['open', 'any', ...STATUSES] as string[]).includes(params.get('status') ?? '')
      ? (params.get('status') as Filters['status'])
      : 'open',
    categoryId: params.get('category') ?? '',
    departmentId: params.get('department') ?? '',
    due: DUE.includes(params.get('due') as DueFilter) ? (params.get('due') as DueFilter) : '',
  };

  function set(patch: Partial<Filters>) {
    const next = { ...filters, ...patch };
    const q: Record<string, string> = {};
    if (next.scope !== fallback) q.scope = next.scope;
    if (next.status !== 'open') q.status = next.status;
    if (next.due) q.due = next.due;
    if (next.categoryId) q.category = next.categoryId;
    if (next.departmentId) q.department = next.departmentId;
    setParams(q, { replace: true });
  }
  const narrowed = filters.status !== 'open' || filters.due !== '' || filters.categoryId !== '' || filters.departmentId !== '';

  const key = JSON.stringify(filters);
  const first = useAsync(() => fetchQueue(filters, 1), [key]);
  useReloadOnCardClose(first.reload);
  const [extra, setExtra] = useState<{ key: string; page: number; items: Item[] }>({ key, page: 1, items: [] });
  const more = extra.key === key ? extra : { key, page: 1, items: [] };
  const [loadingMore, setLoadingMore] = useState(false);
  const [moreError, setMoreError] = useState('');

  const categories = useAsync(() => unwrap(api.GET('/api/v1/categories')), []);
  const showDepartments = me.permissions.can_view_all_appeals;
  const departments = useAsync(
    () => (showDepartments ? unwrap(api.GET('/api/v1/departments')) : Promise.resolve([])),
    [showDepartments],
  );

  async function loadMore() {
    setLoadingMore(true);
    setMoreError('');
    try {
      const next = await fetchQueue(filters, more.page + 1);
      setExtra({ key, page: more.page + 1, items: [...more.items, ...next.items] });
    } catch (e) {
      setMoreError(errorMessage(e));
    } finally {
      setLoadingMore(false);
    }
  }

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const now = useMemo(() => new Date(), [first.state]);
  const s = first.state;
  const total = s.status === 'ready' ? s.data.total : null;

  return (
    <section className="page">
      <PageHead
        over={
          total === null ? 'Загружаем…' : `${total} ${plural(total, ['обращение', 'обращения', 'обращений'])} · по сроку ответа`
        }
        title="Входящие"
      />

      <div className="toolbar">
        {scopes.length > 1 && (
          <div className="segmented" role="group" aria-label="Чьи обращения показать">
            {scopes.map((sc) => (
              <label key={sc} className="segmented__item">
                <input type="radio" name="scope" checked={filters.scope === sc} onChange={() => set({ scope: sc })} />
                <span>{SCOPE_LABEL[sc]}</span>
              </label>
            ))}
          </div>
        )}
        <div className="filters" role="group" aria-label="Фильтры">
          <Select pill="Статус" active={filters.status !== 'open'} value={filters.status} onChange={(e) => set({ status: e.target.value as Filters['status'] })}>
            <option value="open">все открытые</option>
            {(dict.data?.statuses ?? []).map((st) => (
              <option key={st.code} value={st.code}>
                {st.label}
              </option>
            ))}
            <option value="any">любой</option>
          </Select>
          <Select pill="Срок" active={filters.due !== ''} value={filters.due} onChange={(e) => set({ due: e.target.value as Filters['due'] })}>
            <option value="">любой</option>
            {(dict.data?.due_filters ?? []).map((d) => (
              <option key={d.code} value={d.code}>
                {d.label}
              </option>
            ))}
          </Select>
          <Select pill="Категория" active={filters.categoryId !== ''} value={filters.categoryId} onChange={(e) => set({ categoryId: e.target.value })}>
            <option value="">все</option>
            {categories.state.status === 'ready' &&
              categories.state.data.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
          </Select>
          {showDepartments && (
            <Select
              pill="Подразделение"
              active={filters.departmentId !== ''}
              value={filters.departmentId}
              onChange={(e) => set({ departmentId: e.target.value })}
            >
              <option value="">все</option>
              {departments.state.status === 'ready' &&
                departments.state.data.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
            </Select>
          )}
          {narrowed && (
            <button type="button" className="link-btn" onClick={() => set({ status: 'open', due: '', categoryId: '', departmentId: '' })}>
              Сбросить
            </button>
          )}
        </div>
      </div>

      {s.status === 'loading' && <RowsSkeleton />}
      {s.status === 'error' && <LoadError message={s.message} onRetry={first.reload} />}
      {s.status === 'ready' && s.data.total === 0 && (
        <EmptyState icon={narrowed ? 'search' : 'done'} title={narrowed ? 'Под фильтры ничего не подошло' : 'Здесь пусто'}>
          {narrowed ? 'Попробуйте снять часть фильтров.' : 'Новые обращения появятся в этом списке.'}
        </EmptyState>
      )}
      {s.status === 'ready' && s.data.total > 0 && (
        <>
          <div className="card list-card">
            <ul className="rows">
              {[...s.data.items, ...more.items].map((a) => (
                <AppealRow key={a.id} item={a} view="queue" now={now} />
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
