import { useState } from 'react';
import { Link } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { useDictionaries } from '../app/dictionaries';
import { formatDate, formatDateTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';
import { storage } from '../storage';

type Tab = 'open' | 'closed' | 'implemented';
const TAB_KEY = 'modus.feed.tab';

const TABS: { id: Tab; label: string }[] = [
  { id: 'open', label: 'Обсуждения' },
  { id: 'implemented', label: 'Реализовано' },
  { id: 'closed', label: 'Завершённые' },
];

/** Общая лента для всех: открытые обсуждения, реализованные улучшения, завершённые обсуждения (истории 20–22). */
export function FeedPage() {
  const [tab, setTab] = useState<Tab>(() => {
    const saved = storage.get(TAB_KEY);
    return saved === 'implemented' || saved === 'closed' ? saved : 'open';
  });
  const choose = (t: Tab) => {
    setTab(t);
    storage.set(TAB_KEY, t);
  };

  return (
    <section className="page">
      <h1 className="page__title">Общая лента</h1>
      <div className="segmented" role="tablist" aria-label="Раздел ленты">
        {TABS.map((t) => (
          <label key={t.id} className="segmented__item">
            <input type="radio" name="feed-tab" checked={tab === t.id} onChange={() => choose(t.id)} />
            <span>{t.label}</span>
          </label>
        ))}
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
  const s = list.state;
  if (s.status === 'loading') return <p className="muted">Загружаем…</p>;
  if (s.status === 'error') return <p className="error-text">{s.message}</p>;
  if (s.data.items.length === 0) {
    return (
      <div className="notice">
        {status === 'open' ? 'Сейчас нет открытых обсуждений.' : 'Завершённых обсуждений пока нет.'}
      </div>
    );
  }
  return (
    <ul className="appeal-list">
      {s.data.items.map((d) => (
        <li key={d.id}>
          <Link to={`/discussions/${d.id}`} className="appeal-row">
            <div className="appeal-row__top">
              <span className="muted">
                {dict.typeLabel(d.appeal.type)} · {d.author_display}
              </span>
              <span className="muted appeal-row__date">
                {d.status === 'open' ? `до ${formatDateTime(d.deadline)}` : `завершено ${formatDate(d.closed_at)}`}
              </span>
            </div>
            <div className="appeal-row__summary">{d.public_text}</div>
            <div className="appeal-row__meta">
              <span className="badge">За {d.votes_for}</span>
              <span className="badge">Против {d.votes_against}</span>
              <span className="muted">
                {d.comments_count} {plural(d.comments_count, ['комментарий', 'комментария', 'комментариев'])}
              </span>
              {d.my_vote && <span className="muted">· вы проголосовали «{d.my_vote === 'for' ? 'за' : 'против'}»</span>}
            </div>
            {d.status === 'closed' && d.outcome && <div className="muted">Итог: {d.outcome}</div>}
          </Link>
        </li>
      ))}
    </ul>
  );
}

/** Лента реализованного: что предложили и что сделали (история 20). */
function ImplementedList() {
  const dict = useDictionaries();
  const list = useAsync(() => unwrap(api.GET('/api/v1/feed/implemented', { params: { query: { page_size: 50 } } })), []);
  const s = list.state;
  if (s.status === 'loading') return <p className="muted">Загружаем…</p>;
  if (s.status === 'error') return <p className="error-text">{s.message}</p>;
  if (s.data.items.length === 0) return <div className="notice">Реализованных улучшений пока нет.</div>;
  return (
    <ul className="feed">
      {s.data.items.map((f) => (
        <li key={f.appeal_id} className="feed__item">
          <div className="appeal-row__top">
            <span className="muted">
              {dict.typeLabel(f.type)}
              {f.category ? ` · ${f.category.name}` : ''}
            </span>
            <span className="muted appeal-row__date">{formatDate(f.implemented_at)}</span>
          </div>
          <dl className="feed__pair">
            <dt>Что предложили</dt>
            <dd>{f.public_summary}</dd>
            <dt>Что сделали</dt>
            <dd>{f.result}</dd>
          </dl>
          <div className="muted">
            {f.author_display}
            {f.discussion_id && (
              <>
                {' · '}
                <Link to={`/discussions/${f.discussion_id}`}>обсуждение</Link>
              </>
            )}
          </div>
        </li>
      ))}
    </ul>
  );
}
