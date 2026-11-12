import { useState, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { Avatar } from '../app/Avatar';
import { useBackground } from '../app/background';
import { DotNumber } from '../app/DotNumber';
import { LoadError } from '../app/ListStates';
import { PageHead } from '../app/PageHead';
import { api, unwrap } from '../api/client';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { useMe } from '../auth';
import { StatusBadge } from '../appeals/Badges';
import { formatDateTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';
import { Select } from '../app/Select';
import { countDelta, hoursDelta, type Delta } from './weekDelta';

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
  const title = s.status === 'ready' && s.data.department ? `Сводка · ${s.data.department.name}` : company ? 'Сводка по компании' : 'Сводка';
  const narrowed = Boolean(f.departmentId || f.categoryId || f.status || f.due);

  return (
    <section className="page">
      <PageHead over={s.status === 'ready' ? `Данные на ${formatDateTime(s.data.generated_at)}` : 'Считаем…'} title={title} />

      <div className="toolbar">
        <div className="filters" role="group" aria-label="Фильтры">
          {company && (
            <Select pill="Подразделение" active={f.departmentId !== ''} value={f.departmentId} onChange={(e) => set({ departmentId: e.target.value })}>
              <option value="">вся компания</option>
              {departments.state.status === 'ready' &&
                departments.state.data.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
            </Select>
          )}
          <Select pill="Категория" active={f.categoryId !== ''} value={f.categoryId} onChange={(e) => set({ categoryId: e.target.value })}>
            <option value="">все</option>
            {categories.state.status === 'ready' &&
              categories.state.data.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
          </Select>
          <Select pill="Статус" active={f.status !== ''} value={f.status} onChange={(e) => set({ status: e.target.value as Filters['status'] })}>
            <option value="">любой</option>
            {(dict.data?.statuses ?? []).map((st) => (
              <option key={st.code} value={st.code}>
                {st.label}
              </option>
            ))}
          </Select>
          <Select pill="Срок" active={f.due !== ''} value={f.due} onChange={(e) => set({ due: e.target.value as Filters['due'] })}>
            <option value="">любой</option>
            {(dict.data?.due_filters ?? []).map((d) => (
              <option key={d.code} value={d.code}>
                {d.label}
              </option>
            ))}
          </Select>
          {narrowed && (
            <button type="button" className="link-btn" onClick={() => setF({ departmentId: '', categoryId: '', status: '', due: '' })}>
              Сбросить
            </button>
          )}
        </div>
      </div>

      {s.status === 'loading' && (
        <div className="bento" role="status">
          <span className="sr-only">Считаем сводку…</span>
          <div className="card skeleton bento__tile" />
          <div className="card skeleton bento__tile" />
          <div className="card skeleton bento__tile" />
          <div className="card skeleton bento__tile" />
          <div className="card skeleton bento__half" />
          <div className="card skeleton bento__half" />
        </div>
      )}
      {s.status === 'error' && <LoadError message={s.message} onRetry={summary.reload} />}
      {s.status === 'ready' && <SummaryView data={s.data} narrowed={narrowed} />}
    </section>
  );
}

const TICKS = 36;

function SummaryView({ data: d, narrowed }: { data: Summary; narrowed: boolean }) {
  const dict = useDictionaries();
  const pct = Math.round(d.closed_share * 100);
  const overdue = d.overdue.length;
  const open = Math.max(d.total - d.closed_count, 1);
  return (
    <div className="bento">
      <ColorTile tone="navy" label="Закрыто" value={`${pct}%`} spoken={`Закрыто ${pct}%`} pill={`${d.closed_count} из ${d.total}`} share={d.closed_share} />
      <ColorTile
        tone={overdue > 0 ? 'alert' : 'calm'}
        label="Просрочено"
        value={String(overdue)}
        spoken={`Просрочено: ${overdue}`}
        pill={overdue > 0 ? 'нужен ответ' : 'всё в срок'}
        share={overdue / open}
      />
      <Stat label="Всего обращений" value={String(d.total)} hint={d.unassigned_count > 0 ? `${d.unassigned_count} без ответственного` : 'все с ответственным'} />
      <Stat
        label="Первый ответ, в среднем"
        value={d.avg_first_response_hours === null ? '—' : formatHours(d.avg_first_response_hours)}
        hint={d.avg_first_response_hours === null ? 'ответов ещё не было' : 'от подачи до ответа'}
      />

      {d.last_week && d.previous_week && <WeekBlock now={d.last_week} before={d.previous_week} narrowed={narrowed} />}

      <Block className="bento__half" title="Просрочен первый ответ" sub="Ответа нет дольше срока" count={d.overdue.length} danger>
        <More items={sortStuck(d.overdue)} limit={5}>
          {(items) => <StuckList items={items} empty="Просроченных нет — все отвечают в срок." />}
        </More>
      </Block>
      <Block className="bento__half" title="Зависло" sub="Дошло до третьего шага эскалации" count={d.stuck.length} danger>
        <More items={sortStuck(d.stuck)} limit={5}>
          {(items) => <StuckList items={items} empty="Зависших нет." />}
        </More>
      </Block>

      <Block className="bento__third" title="По статусам" sub={`${d.total} ${plural(d.total, ['обращение', 'обращения', 'обращений'])}`}>
        <StatusStrip rows={d.by_status} total={d.total} label={dict.statusLabel} />
        <Bars rows={d.by_status.map((r) => ({ key: r.status, label: dict.statusLabel(r.status), count: r.count, tone: r.status }))} />
      </Block>
      <Block className="bento__third" title="По типам">
        <TypeShares rows={d.by_type} total={d.total} label={dict.typeLabel} />
      </Block>
      <Block className="bento__third" title="По категориям" sub={d.by_category.length > 0 ? 'О чём пишут чаще всего' : undefined}>
        <More items={[...d.by_category].sort((a, b) => b.count - a.count)} limit={7}>
          {(items) => (
            <Bars
              rows={items.map((r) => ({
                key: String(r.category?.id ?? 'none'),
                label: r.category?.name ?? 'Без категории',
                count: r.count,
              }))}
              max={Math.max(...d.by_category.map((r) => r.count), 1)}
            />
          )}
        </More>
      </Block>

      <Block className="bento__third" title="Новое за сутки" count={d.new_last_24h.length}>
        <More items={d.new_last_24h} limit={5}>
          {(items) => <RefList items={items} empty="За сутки ничего не подавали." />}
        </More>
      </Block>
      <Block className="bento__third" title="Закрыто за неделю" count={d.closed_last_week.length}>
        <More items={d.closed_last_week} limit={5}>
          {(items) => <RefList items={items} empty="За неделю ничего не закрыли." showStatus />}
        </More>
      </Block>
      <Block className="bento__third" title="Об этом говорят несколько человек" sub="Повторы, склеенные с основным" count={d.repeated_topics.length}>
        {d.repeated_topics.length === 0 ? (
          <p className="muted">Повторов нет.</p>
        ) : (
          <More items={[...d.repeated_topics].sort((a, b) => b.participants_count - a.participants_count)} limit={5}>
            {(items) => (
              <ul className="rows rows--tight">
                {items.map((t) => (
                  <li key={t.appeal.id}>
                    <AppealLink a={t.appeal} side={<span className="badge badge--people">{t.participants_count} сообщили</span>} />
                  </li>
                ))}
              </ul>
            )}
          </More>
        )}
      </Block>

      {/* Одна строка повторяла бы плитки сверху: таблица нужна, когда подразделений несколько. */}
      {(d.by_department ?? []).length > 1 && (
        <Block className="bento__full" title="По подразделениям" sub="Считается по подразделению, которое отвечает за категорию обращения">
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Подразделение</th>
                  <th className="num">Всего</th>
                  <th className="num">Открыто</th>
                  <th className="num">Просрочено</th>
                  <th className="num">Первый ответ, в среднем</th>
                </tr>
              </thead>
              <tbody>
                {d.by_department.map((r) => (
                  <tr key={r.department?.id ?? 'none'}>
                    <td>{r.department?.name ?? <span className="muted">Без подразделения</span>}</td>
                    <td className="num">{r.total}</td>
                    <td className="num">{r.open_count}</td>
                    <td className="num">{r.overdue_count > 0 ? <span className="count count--danger">{r.overdue_count}</span> : '0'}</td>
                    <td className="num">{r.avg_first_response_hours === null ? '—' : formatHours(r.avg_first_response_hours)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Block>
      )}

      {d.assignee_load.length > 0 && (
        <Block className="bento__full" title="Нагрузка по ответственным">
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Ответственный</th>
                  <th className="num">В работе</th>
                  <th className="num">Просрочено</th>
                  <th className="num">Первый ответ, в среднем</th>
                </tr>
              </thead>
              <tbody>
                {[...d.assignee_load]
                  .sort((a, b) => b.overdue_count - a.overdue_count || b.open_count - a.open_count)
                  .map((r) => (
                  <tr key={r.assignee.id}>
                    <td>
                      <span className="table__person">
                        <Avatar name={r.assignee.full_name} size="sm" />
                        <span>
                          {r.assignee.full_name}
                          {r.assignee.department && <span className="muted"> · {r.assignee.department.name}</span>}
                        </span>
                      </span>
                    </td>
                    <td className="num">{r.open_count}</td>
                    <td className="num">{r.overdue_count > 0 ? <span className="count count--danger">{r.overdue_count}</span> : '0'}</td>
                    <td className="num">{r.avg_first_response_hours === null ? '—' : formatHours(r.avg_first_response_hours)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Block>
      )}
    </div>
  );
}

export function formatHours(h: number): string {
  if (h < 24) return `${h.toFixed(1).replace('.0', '').replace('.', ',')} ч`;
  const days = h / 24;
  return `${days.toFixed(1).replace('.0', '').replace('.', ',')} д`;
}

type Period = Schemas['PeriodStats'];

/**
 * Последние семь дней рядом с предыдущими семью: значение, изменение и что было неделей раньше.
 * Сервер считает недели по отфильтрованной выборке (при статусе «Новое» завершённых будет ноль) — при фильтрах пишем об этом.
 */
function WeekBlock({ now, before, narrowed }: { now: Period; before: Period; narrowed: boolean }) {
  const hours = (h: number | null) => (h === null ? '—' : formatHours(h));
  const cells: { label: string; value: string; was: string; delta: Delta }[] = [
    { label: 'Подано', value: String(now.created_count), was: String(before.created_count), delta: countDelta(now.created_count, before.created_count, 'neutral') },
    { label: 'Завершено', value: String(now.closed_count), was: String(before.closed_count), delta: countDelta(now.closed_count, before.closed_count, 'good') },
    {
      label: 'Из них реализовано',
      value: String(now.implemented_count),
      was: String(before.implemented_count),
      delta: countDelta(now.implemented_count, before.implemented_count, 'good'),
    },
    { label: 'Просрочено', value: String(now.overdue_count), was: String(before.overdue_count), delta: countDelta(now.overdue_count, before.overdue_count, 'bad') },
    {
      label: 'Первый ответ, в среднем',
      value: hours(now.avg_first_response_hours),
      was: before.avg_first_response_hours === null ? 'ответов не было' : hours(before.avg_first_response_hours),
      delta: hoursDelta(now.avg_first_response_hours, before.avg_first_response_hours, formatHours),
    },
  ];
  return (
    <Block className="bento__full" title="Неделя к неделе" sub={narrowed ? 'Последние 7 дней и 7 дней перед ними, только обращения под выбранные фильтры' : 'Последние 7 дней и 7 дней перед ними'}>
      <dl className="week">
        {cells.map((c) => (
          <div key={c.label} className="week__cell">
            <dt className="week__label">{c.label}</dt>
            <dd className="week__now">
              <span className="week__value">{c.value}</span>
              {c.delta.chip && <span className={`week__delta week__delta--${c.delta.tone}`}>{c.delta.chip}</span>}
            </dd>
            <dd className="week__was">неделей раньше: {c.was}</dd>
          </div>
        ))}
      </dl>
    </Block>
  );
}

function ColorTile(props: { tone: 'navy' | 'alert' | 'calm'; label: string; value: string; spoken: string; pill: string; share: number }) {
  const lit = Math.round(Math.min(Math.max(props.share, 0), 1) * TICKS);
  return (
    <div className={`tile tile--${props.tone} bento__tile`}>
      <span className="tile__top" aria-hidden="true">
        <span className="tile__label">{props.label}</span>
      </span>
      <DotNumber className="tile__value" value={props.value} label={`${props.spoken}, ${props.pill}`} />
      <span className="tile__pill" aria-hidden="true">
        {props.pill}
      </span>
      <span className="tile__ruler" aria-hidden="true">
        {Array.from({ length: TICKS }, (_, i) => (
          <i key={i} className={i < lit ? 'on' : undefined} data-edge={i === lit - 1 || undefined} />
        ))}
      </span>
    </div>
  );
}

function Stat({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <div className="card stat bento__tile">
      <span className="stat__label">{label}</span>
      <span className="stat__value">{value}</span>
      {hint && <span className="stat__hint">{hint}</span>}
    </div>
  );
}

function Block(props: { className: string; title: string; sub?: string; count?: number; danger?: boolean; children: ReactNode }) {
  return (
    <article className={`card ${props.className}`}>
      <header className="card__head">
        <div>
          <h2 className="card__title">
            {props.title}
            {props.count !== undefined && props.count > 0 && (
              <span className={props.danger ? 'count count--danger' : 'count'}>{props.count}</span>
            )}
          </h2>
          {props.sub && <p className="card__sub">{props.sub}</p>}
        </div>
      </header>
      {props.children}
    </article>
  );
}

function AppealLink({ a, meta, side }: { a: AppealRef; meta?: ReactNode; side?: ReactNode }) {
  const background = useBackground();
  return (
    <Link to={`/appeals/${a.id}`} state={{ background }} className="row row--plain">
      <span className="row__main">
        <span className="row__title row__title--wrap">{a.summary ?? 'Без краткой сути'}</span>
        <span className="row__meta">
          {a.number}
          {meta}
        </span>
      </span>
      {side}
    </Link>
  );
}

function RefList({ items, empty, showStatus }: { items: AppealRef[]; empty: string; showStatus?: boolean }) {
  if (items.length === 0) return <p className="muted">{empty}</p>;
  return (
    <ul className="rows rows--tight">
      {items.map((a) => (
        <li key={a.id}>
          <AppealLink a={a} side={showStatus ? <StatusBadge status={a.status} /> : undefined} />
        </li>
      ))}
    </ul>
  );
}

function StuckList({ items, empty }: { items: Stuck[]; empty: string }) {
  if (items.length === 0) return <p className="muted">{empty}</p>;
  return (
    <ul className="rows rows--tight">
      {items.map((s) => (
        <li key={s.appeal.id}>
          <AppealLink
            a={s.appeal}
            meta={` · ${s.assignee ? s.assignee.full_name : 'без ответственного'}`}
            side={<span className="row__due row__due--overdue">{s.days_overdue} раб. дн.</span>}
          />
        </li>
      ))}
    </ul>
  );
}

/** Горизонтальные полосы одной серии: длина — количество, подписи и числа текстом (читаются и без цвета). */
function Bars({ rows, max: maxOverride }: { rows: { key: string; label: string; count: number; tone?: string }[]; max?: number }) {
  if (rows.length === 0) return <p className="muted">Нет данных.</p>;
  // Свёрнутый список меряется по полному: иначе полосы прыгают при раскрытии.
  const max = maxOverride ?? Math.max(...rows.map((r) => r.count), 1);
  return (
    <ul className="bars">
      {rows.map((r) => (
        <li key={r.key} className="bars__row">
          <span className="bars__label">{r.label}</span>
          <span className="bars__value">{r.count}</span>
          <span className="bars__track" aria-hidden="true">
            <span
              className="bars__fill"
              style={{ width: `${(r.count / max) * 100}%`, background: r.tone ? `var(--status-${r.tone})` : undefined }}
            />
          </span>
        </li>
      ))}
    </ul>
  );
}

/** Самые запущенные — сверху: выше шаг эскалации, затем больше дней просрочки. */
function sortStuck(items: Stuck[]): Stuck[] {
  return [...items].sort((a, b) => b.escalation_level - a.escalation_level || b.days_overdue - a.days_overdue);
}

/**
 * Длинный список показывает первые строки и кнопку «Показать все N»: иначе одна карточка
 * растягивает весь ряд, а соседние стоят пустыми.
 */
function More<T>({ items, limit, children }: { items: T[]; limit: number; children: (items: T[]) => ReactNode }) {
  const [open, setOpen] = useState(false);
  const extra = items.length - limit;
  return (
    <>
      {children(open || extra <= 0 ? items : items.slice(0, limit))}
      {extra > 0 && (
        <button type="button" className="link-btn more-btn" aria-expanded={open} onClick={() => setOpen(!open)}>
          {open ? 'Свернуть' : `Показать все ${items.length}`}
        </button>
      )}
    </>
  );
}

/** Одна полоса на все обращения: доли статусов цветом, с подписью для экранного диктора. */
function StatusStrip({ rows, total, label }: { rows: Summary['by_status']; total: number; label: (s: string) => string }) {
  if (total === 0) return null;
  const spoken = rows.map((r) => `${label(r.status)}: ${r.count}`).join(', ');
  return (
    <div className="strip" role="img" aria-label={`Распределение по статусам. ${spoken}`}>
      {rows
        .filter((r) => r.count > 0)
        .map((r) => (
          <span
            key={r.status}
            className="strip__part"
            style={{ flexGrow: r.count, background: `var(--status-${r.status})` }}
            title={`${label(r.status)}: ${r.count}`}
          />
        ))}
    </div>
  );
}

/** Типы — крупными числами с долей: их всего три, тонкие полосы для них теряются. */
function TypeShares({ rows, total, label }: { rows: Summary['by_type']; total: number; label: (s: string) => string }) {
  if (rows.length === 0) return <p className="muted">Нет данных.</p>;
  return (
    <ul className="shares">
      {[...rows]
        .sort((a, b) => b.count - a.count)
        .map((r) => {
          const pct = total > 0 ? Math.round((r.count / total) * 100) : 0;
          return (
            <li key={r.type} className="shares__item">
              <span className="shares__value">{r.count}</span>
              <span className="shares__label">
                {label(r.type)}
                <span className="muted"> · {pct}%</span>
              </span>
              <span className="shares__track" aria-hidden="true">
                <span className={`shares__fill shares__fill--${r.type}`} style={{ width: `${pct}%` }} />
              </span>
            </li>
          );
        })}
    </ul>
  );
}
