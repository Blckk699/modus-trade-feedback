import { useMemo, useState, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, ArrowUpRight, Check, RefreshCw } from 'lucide-react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Me, Schemas } from '../api/types';
import { Avatar } from '../app/Avatar';
import { useBackground } from '../app/background';
import { useReloadOnCardClose } from '../app/cardClosed';
import { useDictionaries } from '../app/dictionaries';
import { DotNumber } from '../app/DotNumber';
import { PageHead } from '../app/PageHead';
import { useToast } from '../app/Toast';
import { AppealRow, isWaitingAnswer } from '../appeals/AppealRow';
import { defaultScope, OPEN_STATUSES, type Scope, type Status } from '../appeals/scopes';
import { timeLeftLabel } from '../appeals/timeLeft';
import { TypeIcon } from '../appeals/TypeIcon';
import { useMe } from '../auth';
import { formatDateTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';
import { buildTimeline } from './dueTimeline';
import { buildBrief, greeting } from './homeBrief';

type Item = Schemas['AppealListItem'];
type Summary = Schemas['AnalyticsSummary'];
type Discussion = Schemas['Discussion'];
type FeedItem = Schemas['FeedItem'];

interface HomeData {
  scope: Scope | undefined;
  /** Очередь в стартовом охвате роли, по сроку. */
  queue: Item[];
  /** Назначенные мне и открытые, по сроку. null — пользователь обращения не обрабатывает. */
  assigned: { items: Item[]; total: number } | null;
  mine: { items: Item[]; total: number; open: number; awaiting: Item[] };
  unassigned: { items: Item[]; total: number } | null;
  accessRequests: number | null;
  summary: Summary | null;
  discussions: { items: Discussion[]; total: number };
  implemented: { items: FeedItem[]; total: number };
  loadedAt: Date;
}

interface AppealsQuery {
  scope: Scope;
  status?: Status[];
  sort?: 'created_desc' | 'due_asc';
  page_size: number;
}

const appealsPage = (query: AppealsQuery) => unwrap(api.GET('/api/v1/appeals', { params: { query } }));

/** Всё для экрана одним заходом. Необязательные куски при сбое просто не показываются. */
async function loadHome(me: Me): Promise<HomeData> {
  const p = me.permissions;
  const scope = defaultScope(me);
  // Администратор стартует с очереди без ответственного. Для списка на главном берём все обращения:
  // нераспределённые и так видны в «Ждёт вас» и на плитке.
  const listScope = scope === 'unassigned' && p.can_view_all_appeals ? 'all' : scope;
  const soft = <T,>(call: Promise<T>): Promise<T | null> => call.catch(() => null);
  const open = { status: OPEN_STATUSES, sort: 'due_asc' as const };

  const [queue, assigned, mine, mineOpen, mineAwaiting, unassigned, requests, summary, discussions, implemented] = await Promise.all([
    listScope ? soft(appealsPage({ scope: listScope, ...open, page_size: 30 })) : null,
    p.can_process_appeals ? soft(appealsPage({ scope: 'assigned', ...open, page_size: 50 })) : null,
    appealsPage({ scope: 'mine', sort: 'created_desc', page_size: 5 }),
    soft(appealsPage({ scope: 'mine', status: OPEN_STATUSES, page_size: 1 })),
    soft(appealsPage({ scope: 'mine', status: ['awaiting_info'], page_size: 5 })),
    p.can_view_unassigned ? soft(appealsPage({ scope: 'unassigned', ...open, page_size: 5 })) : null,
    p.can_manage_access
      ? soft(unwrap(api.GET('/api/v1/admin/access-requests', { params: { query: { status: 'pending', page_size: 1 } } })))
      : null,
    p.analytics_scope !== 'none' ? soft(unwrap(api.GET('/api/v1/analytics/summary'))) : null,
    soft(unwrap(api.GET('/api/v1/discussions', { params: { query: { status: 'open', page_size: 4 } } }))),
    soft(unwrap(api.GET('/api/v1/feed/implemented', { params: { query: { page_size: 3 } } }))),
  ]);

  return {
    scope,
    queue: queue?.items ?? [],
    assigned: assigned ? { items: assigned.items, total: assigned.total } : null,
    mine: { items: mine.items, total: mine.total, open: mineOpen?.total ?? 0, awaiting: mineAwaiting?.items ?? [] },
    unassigned: unassigned ? { items: unassigned.items, total: unassigned.total } : null,
    accessRequests: requests ? requests.total : null,
    summary,
    discussions: { items: discussions?.items ?? [], total: discussions?.total ?? 0 },
    implemented: { items: implemented?.items ?? [], total: implemented?.total ?? 0 },
    loadedAt: new Date(),
  };
}

const today = new Intl.DateTimeFormat('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' });
const clock = new Intl.DateTimeFormat('ru-RU', { hour: '2-digit', minute: '2-digit' });
const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

/**
 * «Сегодня» — стартовый экран для всех ролей. Собирается из прав пользователя: что ждёт его самого,
 * как дела со сроками, что происходит вокруг. Отсюда же открываются карточки и разделы.
 */
export function HomePage() {
  const me = useMe();
  const home = useAsync(() => loadHome(me), [me.id]);
  useReloadOnCardClose(home.reload);
  const s = home.state;

  return (
    <section className="home">
      <PageHead over={capitalize(today.format(new Date()))} title={greeting(me.full_name)} />
      {s.status === 'loading' && <HomeSkeleton />}
      {s.status === 'error' && (
        <div className="card notice-card">
          <p className="error-text">{s.message}</p>
          <button type="button" className="btn btn--soft" onClick={home.reload}>
            Повторить
          </button>
        </div>
      )}
      {s.status === 'ready' && <HomeView me={me} data={s.data} reload={home.reload} />}
    </section>
  );
}

function HomeSkeleton() {
  return (
    <div className="bento" role="status">
      <span className="sr-only">Загружаем…</span>
      <div className="card skeleton bento__brief" />
      <div className="card skeleton bento__focus" />
      <div className="card skeleton bento__tile" />
      <div className="card skeleton bento__tile" />
      <div className="card skeleton bento__wide" />
      <div className="card skeleton bento__list" />
      <div className="card skeleton bento__side" />
    </div>
  );
}

function HomeView({ me, data: d, reload }: { me: Me; data: HomeData; reload: () => void }) {
  const p = me.permissions;
  const analytics = d.summary;
  const assignedOverdue = d.assigned?.items.filter((a) => a.due_state === 'overdue').length ?? 0;

  const brief = buildBrief({
    assignedOpen: d.assigned ? d.assigned.total : null,
    assignedOverdue,
    awaitingMe: d.mine.awaiting.length,
    unassigned: d.unassigned ? d.unassigned.total : null,
    accessRequests: d.accessRequests,
    newToday: analytics ? analytics.new_last_24h.length : null,
    overdueTotal: analytics ? analytics.overdue.length : null,
    scope: analytics ? analytics.scope : null,
    openDiscussions: d.discussions.total,
  });

  // Шкала сроков: открытые обращения, у которых идёт срок первого ответа. Свои назначенные — в первую очередь.
  const mineOnly = Boolean(d.assigned && d.assigned.items.some(isWaitingAnswer));
  const dueItems = useMemo(
    () => (mineOnly ? d.assigned!.items : d.queue).filter(isWaitingAnswer),
    [mineOnly, d.assigned, d.queue],
  );
  const showTimeline = dueItems.length > 0;
  // Сервер отдаёт очередь по дате срока; наверх поднимаем те, где первого ответа ещё ждут.
  const list = useMemo(() => {
    const items = d.queue.length > 0 ? d.queue : d.assigned?.items ?? [];
    return [...items.filter(isWaitingAnswer), ...items.filter((a) => !isWaitingAnswer(a))];
  }, [d.queue, d.assigned]);
  const showQueue = list.length > 0;

  return (
    <div className="bento">
      <article className="card brief bento__brief">
        <header className="brief__head">
          <div className="brief__who">
            <h2 className="card__title">Главное на сейчас</h2>
            <p className="card__sub">Данные на {clock.format(d.loadedAt)}</p>
          </div>
          <button type="button" className="chip chip--btn" onClick={reload}>
            <RefreshCw size={14} aria-hidden="true" /> Обновить
          </button>
        </header>
        <p className="brief__text">{brief.join(' ')}</p>
        <footer className="brief__foot">
          <div className="brief__chips">
            {assignedOverdue > 0 && (
              <Link to="/queue?scope=assigned&due=overdue" className="chip">
                Просроченные
              </Link>
            )}
            {d.unassigned && d.unassigned.total > 0 && (
              <Link to="/queue?scope=unassigned" className="chip">
                Без ответственного
              </Link>
            )}
            {d.accessRequests !== null && d.accessRequests > 0 && (
              <Link to="/settings?tab=requests" className="chip">
                Заявки на доступ
              </Link>
            )}
            {p.can_create_appeal && (
              <Link to="/my" className="chip">
                Мои обращения
              </Link>
            )}
            <Link to="/feed" className="chip">
              Обсуждения
            </Link>
          </div>
          {analytics ? (
            <Link to="/digest" className="more-link">
              Вся сводка <ArrowRight size={16} aria-hidden="true" />
            </Link>
          ) : (
            d.scope && (
              <Link to="/queue" className="more-link">
                Все входящие <ArrowRight size={16} aria-hidden="true" />
              </Link>
            )
          )}
        </footer>
      </article>

      <FocusCard me={me} data={d} reload={reload} />

      <Tiles data={d} assignedOverdue={assignedOverdue} />

      {showTimeline ? (
        <TimelineCard items={dueItems} now={d.loadedAt} mineOnly={mineOnly} />
      ) : (
        <DiscussionsCard className="bento__wide" data={d.discussions} />
      )}

      <article className="card bento__list">
        {showQueue ? (
          <>
            <CardHead title="Входящие" sub="Сначала те, где ждут первого ответа" to="/queue" action="Все входящие" />
            <ul className="rows">
              {list.slice(0, 5).map((a) => (
                <AppealRow key={a.id} item={a} view="queue" now={d.loadedAt} />
              ))}
            </ul>
          </>
        ) : (
          <>
            <CardHead title="Мои обращения" sub={d.mine.total > 0 ? 'Последние поданные' : undefined} to="/my" action="Все" />
            {d.mine.items.length > 0 ? (
              <ul className="rows">
                {d.mine.items.map((a) => (
                  <AppealRow key={a.id} item={a} view="mine" />
                ))}
              </ul>
            ) : (
              <Quiet title="Вы ещё ничего не подавали">Расскажите о проблеме, предложите улучшение или отметьте хорошую работу.</Quiet>
            )}
          </>
        )}
      </article>

      {analytics && analytics.assignee_load.length > 1 ? (
        <LoadCard summary={analytics} />
      ) : showTimeline ? (
        <DiscussionsCard className="bento__side" data={d.discussions} />
      ) : (
        <ImplementedCard data={d.implemented} />
      )}
    </div>
  );
}

function CardHead({ title, sub, to, action, count }: { title: string; sub?: string; to?: string; action?: string; count?: number }) {
  return (
    <header className="card__head">
      <div>
        <h2 className="card__title">
          {title}
          {count !== undefined && count > 0 && <span className="count">{count}</span>}
        </h2>
        {sub && <p className="card__sub">{sub}</p>}
      </div>
      {to && action && (
        <Link to={to} className="chip">
          {action}
        </Link>
      )}
    </header>
  );
}

function Quiet({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <div className="quiet">
      <span className="quiet__icon" aria-hidden="true">
        <Check size={18} strokeWidth={2.5} />
      </span>
      <p className="quiet__title">{title}</p>
      {children && <p className="quiet__text">{children}</p>}
    </div>
  );
}

/** «Ждёт вас»: одно самое срочное дело и действие по нему. */
function FocusCard({ me, data: d, reload }: { me: Me; data: HomeData; reload: () => void }) {
  const dict = useDictionaries();
  const background = useBackground();
  const toast = useToast();
  const [busy, setBusy] = useState(false);

  const assigned = d.assigned?.items ?? [];
  const awaiting = d.mine.awaiting;
  const unassigned = d.unassigned?.items ?? [];
  // Порядок: сначала то, где ответа ждут от меня как от ответственного, затем вопрос ко мне как к автору,
  // затем обращения без ответственного.
  const pool = [...assigned.filter((a) => a.status !== 'awaiting_info'), ...awaiting, ...unassigned];
  const seen = new Set<number>();
  const items = pool.filter((a) => (seen.has(a.id) ? false : (seen.add(a.id), true)));
  const top = items[0];
  const total = items.length;

  if (!top) {
    const requests = d.accessRequests ?? 0;
    return (
      <article className="card focus bento__focus">
        <CardHead title="Ждёт вас" />
        {requests > 0 ? (
          <div className="focus__item">
            <p className="focus__title">
              {requests} {plural(requests, ['заявка', 'заявки', 'заявок'])} на доступ
            </p>
            <p className="focus__meta">Люди не могут войти, пока вы не решите.</p>
            <div className="focus__actions">
              <Link to="/settings?tab=requests" className="btn">
                Открыть заявки
              </Link>
            </div>
          </div>
        ) : (
          <Quiet title="Всё разобрано">Новые дела появятся здесь.</Quiet>
        )}
      </article>
    );
  }

  const asAuthor = awaiting.some((a) => a.id === top.id) && !assigned.some((a) => a.id === top.id);
  const noAssignee = !top.assignee;
  const canTake = top.status === 'new' && top.assignee?.id === me.id;
  const waiting = isWaitingAnswer(top);

  async function take() {
    setBusy(true);
    try {
      await unwrap(api.POST('/api/v1/appeals/{appeal_id}/take', { params: { path: { appeal_id: top.id } }, body: { comment: null } }));
      toast(`${top.number} взято на рассмотрение`);
      reload();
    } catch (e) {
      toast(errorMessage(e), 'error');
    } finally {
      setBusy(false);
    }
  }

  const hint = asAuthor
    ? 'Ответственный задал вопрос. Пока нет ответа, работа стоит.'
    : noAssignee
      ? 'Ответственного нет: выберите, кто ответит.'
      : waiting
        ? `Первый ответ: ${timeLeftLabel(top.first_response_due_at!, d.loadedAt)}`
        : dict.statusLabel(top.status);

  return (
    <article className="card focus bento__focus">
      <CardHead title="Ждёт вас" count={total} to={asAuthor ? '/my' : '/queue'} action="Все" />
      <div className="focus__item">
        <div className="focus__top">
          <TypeIcon type={top.type} size="lg" />
          <div className="focus__text">
            <p className="focus__title">{top.summary ?? 'Без краткой сути'}</p>
            <p className="focus__meta">
              {top.number} · {dict.typeLabel(top.type)}
              {top.author && !asAuthor ? ` · ${top.author.full_name}` : ''}
            </p>
          </div>
        </div>
        <p className={`focus__hint${top.due_state === 'overdue' && !asAuthor ? ' focus__hint--danger' : ''}`}>{hint}</p>
        <div className="focus__actions">
          {canTake ? (
            <>
              <button type="button" className="btn" onClick={take} disabled={busy}>
                {busy ? 'Берём…' : 'Взять в работу'}
              </button>
              <Link to={`/appeals/${top.id}`} state={{ background }} className="btn btn--soft">
                Открыть
              </Link>
            </>
          ) : (
            <Link to={`/appeals/${top.id}`} state={{ background }} className="btn">
              {asAuthor ? 'Ответить' : noAssignee ? 'Назначить' : 'Открыть'}
            </Link>
          )}
        </div>
      </div>
      {total > 1 && (
        <Link to={asAuthor ? '/my' : '/queue'} className="focus__more">
          <span>
            Ещё {total - 1}:{' '}
            {items
              .slice(1, 4)
              .map((a) => a.number)
              .join(', ')}
          </span>
          <ArrowRight size={16} aria-hidden="true" />
        </Link>
      )}
    </article>
  );
}

interface TileDef {
  tone: 'navy' | 'alert' | 'calm';
  label: string;
  value: string;
  /** Что читает диктор вместо точечного числа. */
  spoken: string;
  pill: string;
  to: string;
  /** Доля от 0 до 1 для шкалы внизу плитки. */
  share: number;
}

function Tiles({ data: d, assignedOverdue }: { data: HomeData; assignedOverdue: number }) {
  const s = d.summary;
  let tiles: [TileDef, TileDef];

  if (s) {
    const pct = Math.round(s.closed_share * 100);
    const overdue = s.overdue.length;
    const open = Math.max(s.total - s.closed_count, 1);
    tiles = [
      { tone: 'navy', label: 'Закрыто', value: `${pct}%`, spoken: `Закрыто ${pct}%`, pill: `${s.closed_count} из ${s.total}`, to: '/digest', share: s.closed_share },
      {
        tone: overdue > 0 ? 'alert' : 'calm',
        label: 'Просрочено',
        value: String(overdue),
        spoken: `Просрочено: ${overdue}`,
        pill: overdue > 0 ? 'нужен ответ' : 'всё в срок',
        to: '/queue?due=overdue',
        share: overdue / open,
      },
    ];
  } else if (d.assigned && (d.assigned.total > 0 || d.unassigned)) {
    const second: TileDef = d.unassigned
      ? {
          tone: d.unassigned.total > 0 ? 'alert' : 'calm',
          label: 'Без ответственного',
          value: String(d.unassigned.total),
          spoken: `Без ответственного: ${d.unassigned.total}`,
          pill: d.unassigned.total > 0 ? 'нужно назначить' : 'все распределены',
          to: '/queue?scope=unassigned',
          share: d.unassigned.total > 0 ? 1 : 0,
        }
      : {
          tone: assignedOverdue > 0 ? 'alert' : 'calm',
          label: 'Просрочено',
          value: String(assignedOverdue),
          spoken: `Просрочено: ${assignedOverdue}`,
          pill: assignedOverdue > 0 ? 'нужен ответ' : 'всё в срок',
          to: '/queue?scope=assigned&due=overdue',
          share: assignedOverdue / Math.max(d.assigned.total, 1),
        };
    tiles = [
      {
        tone: 'navy',
        label: 'У вас в работе',
        value: String(d.assigned.total),
        spoken: `У вас в работе: ${d.assigned.total}`,
        pill: 'назначено вам',
        to: '/queue?scope=assigned',
        share: d.assigned.total > 0 ? 1 : 0,
      },
      second,
    ];
  } else if (d.unassigned) {
    // Администратор: сам обращения не обрабатывает, но распределяет их.
    tiles = [
      {
        tone: d.unassigned.total > 0 ? 'alert' : 'calm',
        label: 'Без ответственного',
        value: String(d.unassigned.total),
        spoken: `Без ответственного: ${d.unassigned.total}`,
        pill: d.unassigned.total > 0 ? 'нужно назначить' : 'все распределены',
        to: '/queue?scope=unassigned',
        share: d.unassigned.total > 0 ? 1 : 0,
      },
      {
        tone: 'navy',
        label: 'Заявки на доступ',
        value: String(d.accessRequests ?? 0),
        spoken: `Заявок на доступ: ${d.accessRequests ?? 0}`,
        pill: (d.accessRequests ?? 0) > 0 ? 'ждут решения' : 'новых нет',
        to: '/settings?tab=requests',
        share: (d.accessRequests ?? 0) > 0 ? 1 : 0,
      },
    ];
  } else {
    tiles = [
      {
        tone: 'navy',
        label: 'Мои в работе',
        value: String(d.mine.open),
        spoken: `Моих обращений в работе: ${d.mine.open}`,
        pill: `всего ${d.mine.total}`,
        to: '/my',
        share: d.mine.total > 0 ? d.mine.open / d.mine.total : 0,
      },
      {
        tone: 'calm',
        label: 'Сделано',
        value: String(d.implemented.total),
        spoken: `Сделано по предложениям сотрудников: ${d.implemented.total}`,
        pill: 'по предложениям',
        to: '/feed?tab=implemented',
        share: d.implemented.total > 0 ? 1 : 0,
      },
    ];
  }

  return (
    <>
      {tiles.map((t) => (
        <Tile key={t.label} {...t} />
      ))}
    </>
  );
}

const TICKS = 36;

function Tile({ tone, label, value, spoken, pill, to, share }: TileDef) {
  const lit = Math.round(Math.min(Math.max(share, 0), 1) * TICKS);
  return (
    <Link to={to} className={`tile tile--${tone} bento__tile`} aria-label={`${spoken}, ${pill}. Открыть`}>
      <span className="tile__top" aria-hidden="true">
        <span className="tile__label">{label}</span>
        <span className="tile__go">
          <ArrowUpRight size={16} />
        </span>
      </span>
      <DotNumber className="tile__value" value={value} label={spoken} />
      <span className="tile__pill" aria-hidden="true">
        {pill}
      </span>
      <span className="tile__ruler" aria-hidden="true">
        {Array.from({ length: TICKS }, (_, i) => (
          <i key={i} className={i < lit ? 'on' : undefined} data-edge={i === lit - 1 || undefined} />
        ))}
      </span>
    </Link>
  );
}

/** Шкала сроков первого ответа на неделю вперёд. Под шкалой — ближайший срок с переходом в карточку. */
function TimelineCard({ items, now, mineOnly }: { items: Item[]; now: Date; mineOnly: boolean }) {
  const background = useBackground();
  const timeline = useMemo(
    () => buildTimeline(items.map((a) => ({ id: a.id, number: a.number, dueAt: a.first_response_due_at!, a })), now),
    [items, now],
  );
  const overdue = items.filter((a) => a.due_state === 'overdue').length;
  const next = items.find((a) => a.due_state !== 'overdue') ?? items[0];

  return (
    <article className="card bento__wide timeline-card">
      <CardHead
        title="Сроки ответа"
        sub={`${mineOnly ? 'Назначенные вам' : 'Обращения в работе'} · ${items.length} со сроком${overdue > 0 ? ` · ${overdue} ${plural(overdue, ['просрочено', 'просрочены', 'просрочено'])}` : ''}`}
        to="/queue"
        action="Входящие"
      />
      <div className="tl-scroll">
        <div className="tl">
          <div className="tl__lanes">
            <span className="tl__zone" aria-hidden="true" />
            <span className="tl__now" style={{ left: `${timeline.nowX}%` }} aria-hidden="true">
              <b>Сейчас</b>
            </span>
            {timeline.chips.map(({ item, x, lane }) => (
              <Link
                key={item.id}
                to={`/appeals/${item.id}`}
                state={{ background }}
                className={`tl__chip tl__chip--${item.a.due_state}`}
                style={{ left: `${x}%`, top: `${lane * 34}px` }}
                title={`${item.a.summary ?? 'Без краткой сути'} · ${timeLeftLabel(item.dueAt, now)}`}
                aria-label={`${item.number}: ${item.a.summary ?? 'без краткой сути'}, ${timeLeftLabel(item.dueAt, now)}`}
              >
                {item.number}
              </Link>
            ))}
          </div>
          <div className="tl__axis" aria-hidden="true">
            <span className="tl__tick tl__tick--late" style={{ left: 0 }}>
              раньше
            </span>
            {timeline.days.map((day) => (
              <span key={day.label} className="tl__tick" style={{ left: `${day.x}%` }}>
                {day.label}
              </span>
            ))}
          </div>
        </div>
      </div>
      {next && (
        <Link to={`/appeals/${next.id}`} state={{ background }} className="next">
          <span className={`next__time next__time--${next.due_state}`}>{shortLeft(next.first_response_due_at!, now)}</span>
          <span className="next__text">
            <span className="next__title">
              {next.due_state === 'overdue' ? 'Просрочено' : 'Ближайший'}: {next.summary ?? next.number}
            </span>
            <span className="next__meta">
              {next.number} · до {formatDateTime(next.first_response_due_at)}
              {timeline.hidden > 0 ? ` · ещё ${timeline.hidden} за пределами шкалы` : ''}
            </span>
          </span>
          <span className="next__go" aria-hidden="true">
            <ArrowRight size={16} />
          </span>
        </Link>
      )}
    </article>
  );
}

/** Короткая запись остатка для плашки: «2 д», «5 ч», «40 мин». */
function shortLeft(dueAt: string, now: Date): string {
  const min = Math.abs(Math.round((new Date(dueAt).getTime() - now.getTime()) / 60_000));
  if (min >= 1440) return `${Math.floor(min / 1440)} д`;
  if (min >= 60) return `${Math.floor(min / 60)} ч`;
  return `${min} мин`;
}

function DiscussionsCard({ className, data }: { className: string; data: HomeData['discussions'] }) {
  const background = useBackground();
  return (
    <article className={`card ${className}`}>
      <CardHead
        title="Обсуждения"
        sub={data.total > 0 ? 'Идеи, по которым собирают мнения' : undefined}
        count={data.total}
        to="/feed"
        action="Все"
      />
      {data.items.length === 0 ? (
        <Quiet title="Открытых обсуждений нет">Когда идею вынесут на общее обсуждение, она появится здесь.</Quiet>
      ) : (
        <ul className="rows">
          {data.items.slice(0, 3).map((x) => (
            <li key={x.id}>
              <Link to={`/discussions/${x.id}`} state={{ background }} className="row row--plain">
                <span className="row__main">
                  <span className="row__title row__title--wrap">{x.public_text}</span>
                  <span className="row__meta">
                    за {x.votes_for} · против {x.votes_against} · до {formatDateTime(x.deadline)}
                  </span>
                </span>
                <span className={x.can_vote && !x.my_vote ? 'pill-action pill-action--primary' : 'pill-action'}>
                  {x.can_vote && !x.my_vote ? 'Голосовать' : 'Открыть'}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </article>
  );
}

function ImplementedCard({ data }: { data: HomeData['implemented'] }) {
  return (
    <article className="card bento__side">
      <CardHead title="Сделано" sub={data.total > 0 ? 'По предложениям сотрудников' : undefined} to="/feed?tab=implemented" action="Вся лента" />
      {data.items.length === 0 ? (
        <Quiet title="Пока пусто">Здесь появятся предложения, которые компания воплотила.</Quiet>
      ) : (
        <ul className="done-list">
          {data.items.slice(0, 2).map((f) => (
            <li key={f.appeal_id} className="done">
              <p className="done__ask">{f.public_summary}</p>
              <p className="done__result">
                <Check size={16} strokeWidth={2.5} aria-hidden="true" />
                <span>{f.result}</span>
              </p>
            </li>
          ))}
        </ul>
      )}
    </article>
  );
}

/** Нагрузка по ответственным: трое с самой большой просрочкой и очередью, остальное — в сводке. */
function LoadCard({ summary }: { summary: Summary }) {
  const load = [...summary.assignee_load].sort((a, b) => b.overdue_count - a.overdue_count || b.open_count - a.open_count);
  const late = load.filter((r) => r.overdue_count > 0).length;
  return (
    <article className="card bento__side">
      <CardHead
        title="Нагрузка"
        sub={`${load.length} ${plural(load.length, ['ответственный', 'ответственных', 'ответственных'])}${late > 0 ? ` · у ${late} есть просрочка` : ' · все в срок'}`}
        to="/digest"
        action="Сводка"
      />
      <ul className="people">
        {load.slice(0, 3).map((r) => (
          <li key={r.assignee.id} className="person">
            <span className="person__top">
              <Avatar name={r.assignee.full_name} />
              <span className={r.overdue_count > 0 ? 'badge badge--dot badge--status-rejected' : 'badge badge--dot badge--status-implemented'}>
                {r.overdue_count > 0 ? `просрочено ${r.overdue_count}` : 'в срок'}
              </span>
            </span>
            <span className="person__name">{r.assignee.full_name}</span>
            <span className="person__meta">
              {r.open_count} в работе{r.assignee.department ? ` · ${r.assignee.department.name}` : ''}
            </span>
          </li>
        ))}
      </ul>
    </article>
  );
}
