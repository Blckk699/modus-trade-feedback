import { useMemo, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Me, Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { useMe } from '../auth';
import { DueBadge, StatusBadge } from '../appeals/Badges';
import { timeLeftLabel } from '../appeals/timeLeft';
import { useAsync } from '../lib/useAsync';
import { Select } from '../app/Select';
import { useReloadOnCardClose } from '../app/cardClosed';

type Scope = Schemas['AppealScope'];
type Status = Schemas['AppealStatus'];
type DueFilter = Schemas['DueFilter'];
type Item = Schemas['AppealListItem'];

const PAGE_SIZE = 30;
const OPEN: Status[] = ['new', 'in_review', 'awaiting_info', 'in_progress'];

const SCOPE_LABEL: Record<Scope, string> = {
  assigned: 'Назначенные мне',
  department: 'Подразделение',
  all: 'Все обращения',
  unassigned: 'Нераспределённые',
  mine: 'Мои',
};

/** Охваты очереди только по Me.permissions; стартовый — самый широкий, с которым роль работает. */
export function queueScopes(me: Me): Scope[] {
  const p = me.permissions;
  const list: Scope[] = [];
  if (p.can_view_department) list.push('department');
  if (p.can_view_all_appeals) list.push('all');
  if (p.can_view_unassigned) list.push('unassigned');
  if (p.can_process_appeals) list.push('assigned');
  return list;
}

export function defaultScope(me: Me): Scope | undefined {
  const scopes = queueScopes(me);
  const preferred: Scope[] =
    me.role === 'owner' ? ['all'] : me.role === 'head' ? ['department'] : me.role === 'admin' ? ['unassigned'] : ['assigned'];
  return preferred.find((s) => scopes.includes(s)) ?? scopes[0];
}

interface Filters {
  scope: Scope;
  status: 'open' | 'any' | Status;
  categoryId: string;
  departmentId: string;
  due: '' | DueFilter;
}

function fetchQueue(f: Filters, page: number) {
  const status = f.status === 'open' ? OPEN : f.status === 'any' ? undefined : [f.status];
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

export function QueuePage() {
  const me = useMe();
  const dict = useDictionaries();
  const scopes = queueScopes(me);
  const [filters, setFilters] = useState<Filters>(() => ({
    scope: defaultScope(me) ?? 'assigned',
    status: 'open',
    categoryId: '',
    departmentId: '',
    due: '',
  }));
  const set = (patch: Partial<Filters>) => setFilters((f) => ({ ...f, ...patch }));

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

  const now = useMemo(() => new Date(), [first.state]);
  const s = first.state;

  return (
    <section className="page page--wide">
      <h1 className="page__title">Обработка</h1>

      {scopes.length > 1 && (
        <div className="segmented" role="tablist" aria-label="Какие обращения показать">
          {scopes.map((sc) => (
            <label key={sc} className="segmented__item">
              <input type="radio" name="scope" checked={filters.scope === sc} onChange={() => set({ scope: sc })} />
              <span>{SCOPE_LABEL[sc]}</span>
            </label>
          ))}
        </div>
      )}

      <div className="filters">
        <label className="field">
          <span className="field__label">Статус</span>
          <Select value={filters.status} onChange={(e) => set({ status: e.target.value as Filters['status'] })}>
            <option value="open">Все открытые</option>
            {(dict.data?.statuses ?? []).map((st) => (
              <option key={st.code} value={st.code}>
                {st.label}
              </option>
            ))}
            <option value="any">Любой</option>
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Срок</span>
          <Select value={filters.due} onChange={(e) => set({ due: e.target.value as Filters['due'] })}>
            <option value="">Любой</option>
            {(dict.data?.due_filters ?? []).map((d) => (
              <option key={d.code} value={d.code}>
                {d.label}
              </option>
            ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Категория</span>
          <Select value={filters.categoryId} onChange={(e) => set({ categoryId: e.target.value })}>
            <option value="">Все</option>
            {categories.state.status === 'ready' &&
              categories.state.data.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
          </Select>
        </label>
        {showDepartments && (
          <label className="field">
            <span className="field__label">Подразделение</span>
            <Select value={filters.departmentId} onChange={(e) => set({ departmentId: e.target.value })}>
              <option value="">Все</option>
              {departments.state.status === 'ready' &&
                departments.state.data.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
            </Select>
          </label>
        )}
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
          <p>Обращений нет.</p>
          <p className="muted">Измените фильтры или загляните позже.</p>
        </div>
      )}
      {s.status === 'ready' && s.data.total > 0 && (
        <>
          <p className="muted">Найдено: {s.data.total}</p>
          <ul className="appeal-list">
            {[...s.data.items, ...more.items].map((a) => (
              <QueueRow key={a.id} item={a} now={now} />
            ))}
          </ul>
          {s.data.items.length + more.items.length < s.data.total && (
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

function QueueRow({ item, now }: { item: Item; now: Date }) {
  const dict = useDictionaries();
  const location = useLocation();
  const overdue = item.due_state === 'overdue';
  const waitingAnswer = item.first_response_due_at && item.due_state !== 'answered' && item.due_state !== 'no_deadline';
  return (
    <li>
      <Link to={`/appeals/${item.id}`} state={{ from: '/queue', background: location }} className={`appeal-row${overdue ? ' appeal-row--overdue' : ''}`}>
        <div className="appeal-row__top">
          <span className="appeal-row__number">{item.number}</span>
          {item.has_unread && <span className="dot" aria-label="Есть новое" title="Есть новое" />}
          <span className="muted">
            {dict.typeLabel(item.type)} · {dict.priorityLabel(item.priority)}
          </span>
          {waitingAnswer && (
            <span className={`appeal-row__date${overdue ? ' error-text' : ''}`}>
              {timeLeftLabel(item.first_response_due_at!, now)}
            </span>
          )}
        </div>
        <div className="appeal-row__summary">{item.summary ?? 'Без краткой сути'}</div>
        <div className="appeal-row__meta">
          <StatusBadge status={item.status} />
          {item.status !== 'closed' && <DueBadge state={item.due_state} dueAt={item.first_response_due_at} />}
          {item.category && <span className="muted">{item.category.name}</span>}
          <span className="muted">· {item.assignee ? item.assignee.full_name : 'без ответственного'}</span>
          {item.participants_count > 1 && <span className="badge">Сообщили: {item.participants_count}</span>}
        </div>
      </Link>
    </li>
  );
}
