import { useState, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { useMe } from '../auth';
import { StatusBadge } from '../appeals/Badges';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { Select } from '../app/Select';

type Summary = Schemas['AnalyticsSummary'];
type AppealRef = Schemas['AppealRef'];
type Stuck = Schemas['StuckAppeal'];
type Status = Schemas['AppealStatus'];
type DueFilter = Schemas['DueFilter'];

interface Filters {
  departmentId: string;
  categoryId: string;
  status: '' | Status;
  due: '' | DueFilter;
}

/** Сводка: собственник — по компании с фильтром подразделения, руководитель — своё подразделение (решает бэкенд). */
export function DigestPage() {
  const me = useMe();
  const dict = useDictionaries();
  const company = me.permissions.analytics_scope === 'company';
  const [f, setF] = useState<Filters>({ departmentId: '', categoryId: '', status: '', due: '' });
  const set = (patch: Partial<Filters>) => setF((x) => ({ ...x, ...patch }));

  const summary = useAsync(
    () =>
      unwrap(
        api.GET('/api/v1/analytics/summary', {
          params: {
            query: {
              department_id: f.departmentId ? Number(f.departmentId) : undefined,
              category_id: f.categoryId ? Number(f.categoryId) : undefined,
              status: f.status ? [f.status] : undefined,
              due: f.due || undefined,
            },
          },
        }),
      ),
    [JSON.stringify(f)],
  );
  const departments = useAsync(() => (company ? unwrap(api.GET('/api/v1/departments')) : Promise.resolve([])), [company]);
  const categories = useAsync(() => unwrap(api.GET('/api/v1/categories')), []);

  const s = summary.state;
  const title =
    s.status === 'ready' && s.data.department
      ? `Сводка · ${s.data.department.name}`
      : 'Сводка по компании';

  return (
    <section className="page page--wide">
      <div className="page__head">
        <h1 className="page__title sr-only">{title}</h1>
        {s.status === 'ready' && <span className="muted">Обновлено {formatDateTime(s.data.generated_at)}</span>}
      </div>

      <div className="filters">
        {company && (
          <label className="field">
            <span className="field__label">Подразделение</span>
            <Select value={f.departmentId} onChange={(e) => set({ departmentId: e.target.value })}>
              <option value="">Вся компания</option>
              {departments.state.status === 'ready' &&
                departments.state.data.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
            </Select>
          </label>
        )}
        <label className="field">
          <span className="field__label">Категория</span>
          <Select value={f.categoryId} onChange={(e) => set({ categoryId: e.target.value })}>
            <option value="">Все</option>
            {categories.state.status === 'ready' &&
              categories.state.data.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Статус</span>
          <Select value={f.status} onChange={(e) => set({ status: e.target.value as Filters['status'] })}>
            <option value="">Любой</option>
            {(dict.data?.statuses ?? []).map((st) => (
              <option key={st.code} value={st.code}>
                {st.label}
              </option>
            ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Срок</span>
          <Select value={f.due} onChange={(e) => set({ due: e.target.value as Filters['due'] })}>
            <option value="">Любой</option>
            {(dict.data?.due_filters ?? []).map((d) => (
              <option key={d.code} value={d.code}>
                {d.label}
              </option>
            ))}
          </Select>
        </label>
      </div>

      {s.status === 'loading' && <p className="muted">Загружаем…</p>}
      {s.status === 'error' && (
        <div className="notice">
          <p className="error-text">{s.message}</p>
          <button type="button" className="btn btn--ghost" onClick={summary.reload}>
            Повторить
          </button>
        </div>
      )}
      {s.status === 'ready' && <SummaryView data={s.data} />}
    </section>
  );
}

function SummaryView({ data: d }: { data: Summary }) {
  const dict = useDictionaries();
  const pct = Math.round(d.closed_share * 100);
  return (
    <>
      <div className="tiles">
        <Tile label="Всего обращений" value={String(d.total)} />
        <Tile label="Доля закрытых" value={`${pct}%`} hint={`${d.closed_count} из ${d.total}`} />
        <Tile
          label="Среднее время первого ответа"
          value={d.avg_first_response_hours === null ? '—' : formatHours(d.avg_first_response_hours)}
          hint={d.avg_first_response_hours === null ? 'Ещё нет ответов' : undefined}
        />
        <Tile label="Просрочено" value={String(d.overdue.length)} danger={d.overdue.length > 0} />
      </div>

      <div className="digest-grid">
        <Block title="Новое за сутки" count={d.new_last_24h.length}>
          <RefList items={d.new_last_24h} empty="Новых обращений нет." />
        </Block>
        <Block title="Зависло" count={d.stuck.length} danger={d.stuck.length > 0}>
          <StuckList items={d.stuck} empty="Зависших обращений нет." />
        </Block>
        <Block title="Закрыто за неделю" count={d.closed_last_week.length}>
          <RefList items={d.closed_last_week} empty="За неделю ничего не закрыто." showStatus />
        </Block>
        <Block title="Повторяющиеся темы" count={d.repeated_topics.length}>
          {d.repeated_topics.length === 0 ? (
            <p className="muted">Повторов нет.</p>
          ) : (
            <ul className="ref-list">
              {d.repeated_topics.map((t) => (
                <li key={t.appeal.id}>
                  <AppealLink a={t.appeal} />
                  <span className="badge">Сообщили: {t.participants_count}</span>
                </li>
              ))}
            </ul>
          )}
        </Block>
      </div>

      <div className="digest-grid">
        <Block title="По типам">
          <Bars rows={d.by_type.map((r) => ({ key: r.type, label: dict.typeLabel(r.type), count: r.count }))} />
        </Block>
        <Block title="По статусам">
          <Bars rows={d.by_status.map((r) => ({ key: r.status, label: dict.statusLabel(r.status), count: r.count }))} />
        </Block>
        <Block title="По категориям">
          <Bars
            rows={d.by_category.map((r) => ({
              key: String(r.category?.id ?? 'none'),
              label: r.category?.name ?? 'Без категории',
              count: r.count,
            }))}
          />
        </Block>
      </div>

      <Block title="Просроченные" count={d.overdue.length} danger={d.overdue.length > 0}>
        <StuckList items={d.overdue} empty="Просроченных нет." />
      </Block>

      {d.assignee_load.length > 0 && (
        <Block title="Нагрузка по ответственным">
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Ответственный</th>
                  <th className="num">Открыто</th>
                  <th className="num">Просрочено</th>
                  <th className="num">Первый ответ, в среднем</th>
                </tr>
              </thead>
              <tbody>
                {d.assignee_load.map((r) => (
                  <tr key={r.assignee.id}>
                    <td>
                      {r.assignee.full_name}
                      {r.assignee.department && <span className="muted"> · {r.assignee.department.name}</span>}
                    </td>
                    <td className="num">{r.open_count}</td>
                    <td className={`num${r.overdue_count > 0 ? ' error-text' : ''}`}>{r.overdue_count}</td>
                    <td className="num">{r.avg_first_response_hours === null ? '—' : formatHours(r.avg_first_response_hours)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Block>
      )}
    </>
  );
}

export function formatHours(h: number): string {
  if (h < 24) return `${h.toFixed(1).replace('.0', '').replace('.', ',')} ч`;
  const days = h / 24;
  return `${days.toFixed(1).replace('.0', '').replace('.', ',')} д`;
}

function Tile({ label, value, hint, danger }: { label: string; value: string; hint?: string; danger?: boolean }) {
  return (
    <div className="tile">
      <span className="tile__label">{label}</span>
      <span className={`tile__value${danger ? ' error-text' : ''}`}>{value}</span>
      {hint && <span className="muted tile__hint">{hint}</span>}
    </div>
  );
}

function Block({ title, count, danger, children }: { title: string; count?: number; danger?: boolean; children: ReactNode }) {
  return (
    <div className="block">
      <h2 className="block__title">
        {title}
        {count !== undefined && <span className={`block__count${danger ? ' error-text' : ''}`}> {count}</span>}
      </h2>
      {children}
    </div>
  );
}

function AppealLink({ a }: { a: AppealRef }) {
  return (
    <Link to={`/appeals/${a.id}`} state={{ from: '/digest' }} className="ref-link">
      <span className="appeal-row__number">{a.number}</span> {a.summary ?? 'Без краткой сути'}
    </Link>
  );
}

function RefList({ items, empty, showStatus }: { items: AppealRef[]; empty: string; showStatus?: boolean }) {
  if (items.length === 0) return <p className="muted">{empty}</p>;
  return (
    <ul className="ref-list">
      {items.map((a) => (
        <li key={a.id}>
          <AppealLink a={a} />
          {showStatus && <StatusBadge status={a.status} />}
        </li>
      ))}
    </ul>
  );
}

function StuckList({ items, empty }: { items: Stuck[]; empty: string }) {
  if (items.length === 0) return <p className="muted">{empty}</p>;
  return (
    <ul className="ref-list">
      {items.map((s) => (
        <li key={s.appeal.id}>
          <AppealLink a={s.appeal} />
          <span className="muted">
            {s.assignee ? s.assignee.full_name : 'без ответственного'} ·{' '}
            <span className="error-text">просрочено {s.days_overdue} раб. дн.</span>
          </span>
        </li>
      ))}
    </ul>
  );
}

/** Горизонтальные полосы одной серии: длина — количество, подписи и числа текстом (читаются и без цвета). */
function Bars({ rows }: { rows: { key: string; label: string; count: number }[] }) {
  if (rows.length === 0) return <p className="muted">Нет данных.</p>;
  const max = Math.max(...rows.map((r) => r.count), 1);
  return (
    <ul className="bars">
      {rows.map((r) => (
        <li key={r.key} className="bars__row" title={`${r.label}: ${r.count}`}>
          <span className="bars__label">{r.label}</span>
          <span className="bars__track" aria-hidden="true">
            <span className="bars__fill" style={{ width: `${(r.count / max) * 100}%` }} />
          </span>
          <span className="bars__value">{r.count}</span>
        </li>
      ))}
    </ul>
  );
}
