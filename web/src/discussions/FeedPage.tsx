import { ArrowRight, Check, MessageSquare, ThumbsDown, ThumbsUp } from 'lucide-react';
import { Link, useSearchParams } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { useBackground } from '../app/background';
import { useReloadOnCardClose } from '../app/cardClosed';
import { useDictionaries } from '../app/dictionaries';
import { EmptyState } from '../app/EmptyState';
import { LoadError, RowsSkeleton } from '../app/ListStates';
import { PageHead } from '../app/PageHead';
import { formatDate, formatDateTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';
import { storage } from '../storage';

type Tab = 'open' | 'closed' | 'implemented';
const TAB_KEY = 'modus.feed.tab';
const isTab = (v: string | null): v is Tab => v === 'open' || v === 'closed' || v === 'implemented';

const TABS: { id: Tab; label: string }[] = [
  { id: 'open', label: 'Обсуждения' },
  { id: 'implemented', label: 'Сделано' },
  { id: 'closed', label: 'Завершённые' },
];

/** Общая лента для всех: открытые обсуждения, реализованные улучшения, завершённые обсуждения (истории 20–22). */
export function FeedPage() {
  const [params, setParams] = useSearchParams();
  const fromUrl = params.get('tab');
  const saved = storage.get(TAB_KEY);
  const tab: Tab = isTab(fromUrl) ? fromUrl : isTab(saved) ? saved : 'open';
  const choose = (t: Tab) => {
    storage.set(TAB_KEY, t);
    setParams(t === 'open' ? {} : { tab: t }, { replace: true });
  };

  return (
    <section className="page">
      <PageHead over="Что обсуждают и что уже сделали" title="Лента" />
      <div className="toolbar">
        <div className="segmented" role="group" aria-label="Раздел ленты">
          {TABS.map((t) => (
            <label key={t.id} className="segmented__item">
              <input type="radio" name="feed-tab" checked={tab === t.id} onChange={() => choose(t.id)} />
              <span>{t.label}</span>
            </label>
          ))}
        </div>
      </div>
      {tab === 'implemented' ? <ImplementedList /> : <DiscussionList status={tab} />}
    </section>
  );
}

function DiscussionList({ status }: { status: 'open' | 'closed' }) {
  const dict = useDictionaries();
  const list = useAsync(
    () => unwrap(api.GET('/api/v1/discussions', { params: { query: { status, page_size: 50 } } })),
    [status],
  );
  useReloadOnCardClose(list.reload);
  const background = useBackground();
  const s = list.state;
  if (s.status === 'loading') return <RowsSkeleton rows={3} />;
  if (s.status === 'error') return <LoadError message={s.message} onRetry={list.reload} />;
  if (s.data.items.length === 0) {
    return (
      <EmptyState icon="chat" title={status === 'open' ? 'Открытых обсуждений нет' : 'Завершённых обсуждений пока нет'}>
        {status === 'open'
          ? 'Когда ответственный вынесет предложение на общее обсуждение, оно появится здесь.'
          : 'Здесь будут обсуждения, по которым подвели итог.'}
      </EmptyState>
    );
  }
  return (
    <ul className="cards">
      {s.data.items.map((d) => {
        const total = d.votes_for + d.votes_against;
        const needVote = d.status === 'open' && d.can_vote && !d.my_vote;
        return (
          <li key={d.id}>
            <Link to={`/discussions/${d.id}`} state={{ background }} className="card talk">
              <span className="talk__meta">
                {dict.typeLabel(d.appeal.type)} · {d.author_display}
              </span>
              <span className="talk__text">{d.public_text}</span>
              {d.status === 'closed' && d.outcome && (
                <span className="talk__outcome">
                  <Check size={16} strokeWidth={2.5} aria-hidden="true" />
                  <span>{d.outcome}</span>
                </span>
              )}
              <span className="talk__bar" aria-hidden="true">
                {total > 0 ? (
                  <>
                    {d.votes_for > 0 && <i className="for" style={{ flexGrow: d.votes_for }} />}
                    {d.votes_against > 0 && <i className="against" style={{ flexGrow: d.votes_against }} />}
                  </>
                ) : (
                  <i />
                )}
              </span>
              <span className="talk__foot">
                <span className="talk__stat">
                  <ThumbsUp size={15} aria-hidden="true" />
                  <span className="sr-only">За: </span>
                  {d.votes_for}
                </span>
                <span className="talk__stat">
                  <ThumbsDown size={15} aria-hidden="true" />
                  <span className="sr-only">Против: </span>
                  {d.votes_against}
                </span>
                <span className="talk__stat">
                  <MessageSquare size={15} aria-hidden="true" />
                  {d.comments_count}
                  <span className="sr-only"> {plural(d.comments_count, ['комментарий', 'комментария', 'комментариев'])}</span>
                </span>
                <span className="talk__when">
                  {d.status === 'open' ? `до ${formatDateTime(d.deadline)}` : `завершено ${formatDate(d.closed_at)}`}
                </span>
                <span className={needVote ? 'pill-action pill-action--primary' : 'pill-action'}>
                  {needVote ? 'Голосовать' : d.my_vote ? `Вы ${d.my_vote === 'for' ? 'за' : 'против'}` : 'Открыть'}
                </span>
              </span>
            </Link>
          </li>
        );
      })}
    </ul>
  );
}

/** Лента реализованного: что предложили и что сделали (история 20). */
function ImplementedList() {
  const dict = useDictionaries();
  const background = useBackground();
  const list = useAsync(() => unwrap(api.GET('/api/v1/feed/implemented', { params: { query: { page_size: 50 } } })), []);
  const s = list.state;
  if (s.status === 'loading') return <RowsSkeleton rows={3} />;
  if (s.status === 'error') return <LoadError message={s.message} onRetry={list.reload} />;
  if (s.data.items.length === 0) {
    return (
      <EmptyState icon="done" title="Пока ничего не сделано">
        Сюда попадают предложения сотрудников, которые компания воплотила.
      </EmptyState>
    );
  }
  return (
    <ul className="cards">
      {s.data.items.map((f) => (
        <li key={f.appeal_id} className="card shipped">
          <span className="talk__meta">
            {dict.typeLabel(f.type)}
            {f.category ? ` · ${f.category.name}` : ''} · {formatDate(f.implemented_at)}
          </span>
          <p className="shipped__ask">{f.public_summary}</p>
          <div className="shipped__result">
            <span className="shipped__mark" aria-hidden="true">
              <Check size={14} strokeWidth={3} />
            </span>
            <p>
              <span className="sr-only">Что сделали: </span>
              {f.result}
            </p>
          </div>
          <span className="shipped__foot">
            <span>{f.author_display}</span>
            {f.discussion_id && (
              <Link to={`/discussions/${f.discussion_id}`} state={{ background }} className="more-link">
                Обсуждение <ArrowRight size={15} aria-hidden="true" />
              </Link>
            )}
          </span>
        </li>
      ))}
    </ul>
  );
}
