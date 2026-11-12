import { useState, type FormEvent } from 'react';
import { ArrowLeft, ArrowRight, ArrowUp, ThumbsDown, ThumbsUp } from 'lucide-react';
import { Link, useParams } from 'react-router-dom';
import { Avatar } from '../app/Avatar';
import { useBackground } from '../app/background';
import { PageHead } from '../app/PageHead';
import { useInCard } from '../pages/CardModal';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { useMe } from '../auth';
import { formatDateTime } from '../lib/format';
import { plural } from '../lib/plural';
import { useAsync } from '../lib/useAsync';

type Discussion = Schemas['Discussion'];
type Vote = Schemas['VoteValue'];

/** Обсуждение: из ленты открывается панелью справа, по прямой ссылке — отдельной страницей. */
export function DiscussionPage() {
  const id = Number(useParams().id);
  const inCard = useInCard();
  const d = useAsync(
    () => unwrap(api.GET('/api/v1/discussions/{discussion_id}', { params: { path: { discussion_id: id } } })),
    [id],
  );

  const s = d.state;
  const body =
    s.status === 'loading' ? (
      <div className="sheet sheet--state" role="status">
        <span className="spinner" aria-hidden="true" /> Открываем обсуждение…
      </div>
    ) : s.status === 'error' ? (
      <div className="sheet sheet--state">
        <p className="error-text">{s.error instanceof ApiError && s.error.status === 404 ? 'Обсуждение не найдено.' : s.message}</p>
      </div>
    ) : (
      <DiscussionView discussion={s.data} onUpdated={d.set} />
    );

  if (inCard) return body;
  return (
    <section className="solo">
      <PageHead over="Лента" title="Обсуждение" />
      <Link to="/feed" className="back-link">
        <ArrowLeft size={16} aria-hidden="true" /> Лента
      </Link>
      <div className="card solo__card">{body}</div>
    </section>
  );
}

function DiscussionView({ discussion: d, onUpdated }: { discussion: Discussion; onUpdated: (d: Discussion) => void }) {
  const dict = useDictionaries();
  const background = useBackground();
  // Решать про имя может только автор — значит, это его обращение.
  const isAuthorView = d.can_set_name_consent;
  const open = d.status === 'open';

  return (
    <article className="sheet">
      <header className="sheet__head">
        <div className="sheet__state">
          <span className={open ? 'badge badge--dot badge--status-new' : 'badge badge--dot badge--status-closed'}>
            {open ? 'Идёт обсуждение' : 'Обсуждение завершено'}
          </span>
          <span className="badge">{dict.typeLabel(d.appeal.type)}</span>
        </div>
      </header>

      <div className="sheet__scroll">
        <div>
          <h1 className="sheet__title">{d.public_text}</h1>
          <p className="sheet__sub">
            {d.author_display} · {open ? 'голосование до ' : 'срок был '}
            {formatDateTime(d.deadline)}
          </p>
          {isAuthorView && (
            <Link to={`/appeals/${d.appeal.id}`} state={{ background }} className="more-link sheet__own">
              Ваше обращение {d.appeal.number} <ArrowRight size={15} aria-hidden="true" />
            </Link>
          )}
        </div>

        {d.can_set_name_consent && <NameConsent discussion={d} onUpdated={onUpdated} />}

        {!open && d.outcome && (
          <div className="notice notice--success" role="region" aria-label="Итог">
            <h2 className="notice__title">Итог</h2>
            <p className="prose">{d.outcome}</p>
            {d.closed_at && <p className="muted">Подведён {formatDateTime(d.closed_at)}</p>}
          </div>
        )}

        <Votes discussion={d} onUpdated={onUpdated} />
        {d.can_close && open && <CloseForm discussion={d} onUpdated={onUpdated} />}
        <Comments discussion={d} />
      </div>
    </article>
  );
}

const CONSENT_TEXT: Record<Schemas['NameConsent'], string> = {
  pending: 'Ваше обращение вынесли на общее обсуждение. Показать ваше имя? Пока вы не решили, указано только подразделение.',
  shown: 'Ваше имя показано в обсуждении.',
  hidden: 'Ваше имя скрыто, в обсуждении указано только подразделение.',
};

/** Запрос автору на показ имени (история 18). Решение можно изменить. */
function NameConsent({ discussion: d, onUpdated }: { discussion: Discussion; onUpdated: (d: Discussion) => void }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function answer(show: boolean) {
    setBusy(true);
    setError('');
    try {
      onUpdated(
        await unwrap(
          api.POST('/api/v1/discussions/{discussion_id}/name-consent', {
            params: { path: { discussion_id: d.id } },
            body: { show_name: show },
          }),
        ),
      );
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  const c = d.author_name_consent;
  return (
    <div className={`notice${c === 'pending' ? ' notice--warn' : ''}`}>
      <p>{CONSENT_TEXT[c]}</p>
      <div className="form__actions">
        {c !== 'shown' && (
          <button type="button" className="btn btn--sm" disabled={busy} onClick={() => answer(true)}>
            Показать имя
          </button>
        )}
        {c !== 'hidden' && (
          <button type="button" className="btn btn--soft btn--sm" disabled={busy} onClick={() => answer(false)}>
            {c === 'pending' ? 'Не показывать' : 'Скрыть имя'}
          </button>
        )}
        {error && <span className="error-text">{error}</span>}
      </div>
    </div>
  );
}

/** Счёт голосов и голосование. Повторный клик по своему голосу — отозвать. */
function Votes({ discussion: d, onUpdated }: { discussion: Discussion; onUpdated: (d: Discussion) => void }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const total = d.votes_for + d.votes_against;
  const forPct = total ? Math.round((d.votes_for / total) * 100) : 0;

  async function vote(v: Vote) {
    setBusy(true);
    setError('');
    const path = { params: { path: { discussion_id: d.id } } };
    try {
      const next =
        d.my_vote === v
          ? await unwrap(api.DELETE('/api/v1/discussions/{discussion_id}/vote', path))
          : await unwrap(api.PUT('/api/v1/discussions/{discussion_id}/vote', { ...path, body: { value: v } }));
      onUpdated(next);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  const againstPct = total ? 100 - forPct : 0;
  const options = [
    { value: 'for' as const, label: 'За', count: d.votes_for, pct: forPct },
    { value: 'against' as const, label: 'Против', count: d.votes_against, pct: againstPct },
  ];

  return (
    <section className="section vote">
      <div className="section__head">
        <h2 className="section__title">Голосование</h2>
        <span className="muted">
          {total} {plural(total, ['голос', 'голоса', 'голосов'])}
        </span>
      </div>

      <div className="vote__options" role="group" aria-label={`За: ${d.votes_for}, против: ${d.votes_against}`}>
        {options.map((o) => {
          const mine = d.my_vote === o.value;
          const Icon = o.value === 'for' ? ThumbsUp : ThumbsDown;
          const body = (
            <>
              <span className="vote__icon" aria-hidden="true">
                <Icon size={20} />
              </span>
              <span className="vote__label">{o.label}</span>
              <span className="vote__count">{o.count}</span>
              <span className="vote__pct">{total ? `${o.pct}%` : '—'}</span>
            </>
          );
          return d.can_vote ? (
            <button
              key={o.value}
              type="button"
              className={`vote__option vote__option--${o.value}${mine ? ' vote__option--mine' : ''}`}
              aria-pressed={mine}
              disabled={busy}
              onClick={() => vote(o.value)}
            >
              {body}
            </button>
          ) : (
            <div key={o.value} className={`vote__option vote__option--${o.value} vote__option--static`}>
              {body}
            </div>
          );
        })}
      </div>

      <div className="vote__bar" aria-hidden="true">
        {total > 0 ? (
          <>
            {d.votes_for > 0 && <span className="vote__bar-for" style={{ flexGrow: d.votes_for }} />}
            {d.votes_against > 0 && <span className="vote__bar-against" style={{ flexGrow: d.votes_against }} />}
          </>
        ) : (
          <span className="vote__bar-empty" />
        )}
      </div>

      <p className="vote__note">
        {d.can_vote && d.my_vote
          ? 'Ваш голос учтён. Нажмите на него ещё раз, чтобы отозвать. '
          : !d.can_vote && d.status === 'open'
            ? 'Вы не можете голосовать в этом обсуждении. '
            : ''}
        Голосование совещательное: итог подводит руководитель.
      </p>
      {error && <p className="error-text">{error}</p>}
    </section>
  );
}

function CloseForm({ discussion: d, onUpdated }: { discussion: Discussion; onUpdated: (d: Discussion) => void }) {
  const [outcome, setOutcome] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!outcome.trim()) return;
    setBusy(true);
    setError('');
    try {
      onUpdated(
        await unwrap(
          api.POST('/api/v1/discussions/{discussion_id}/close', {
            params: { path: { discussion_id: d.id } },
            body: { outcome: outcome.trim() },
          }),
        ),
      );
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="section" onSubmit={submit}>
      <h2 className="section__title">Подвести итог</h2>
      <label className="field">
        <span className="field__label">Что решили</span>
        <textarea className="input" rows={3} value={outcome} onChange={(e) => setOutcome(e.target.value)} required />
        <span className="field__hint muted">Итог увидят все. После этого голосование и комментарии закроются.</span>
      </label>
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy || !outcome.trim()}>
          {busy ? 'Сохраняем…' : 'Подвести итог'}
        </button>
        {error && <span className="error-text">{error}</span>}
      </div>
    </form>
  );
}

function Comments({ discussion: d }: { discussion: Discussion }) {
  const list = useAsync(
    () =>
      unwrap(api.GET('/api/v1/discussions/{discussion_id}/comments', { params: { path: { discussion_id: d.id } } })),
    [d.id],
  );
  const me = useMe();
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function send(e: FormEvent) {
    e.preventDefault();
    if (!text.trim() || busy) return;
    setBusy(true);
    setError('');
    try {
      const c = await unwrap(
        api.POST('/api/v1/discussions/{discussion_id}/comments', {
          params: { path: { discussion_id: d.id } },
          body: { text: text.trim() },
        }),
      );
      setText('');
      if (list.state.status === 'ready') list.set([...list.state.data, c]);
      else list.reload();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  const count = list.state.status === 'ready' ? list.state.data.length : null;

  return (
    <section className="section comments">
      <h2 className="section__title">
        Комментарии
        {count !== null && count > 0 && <span className="section__count">{count}</span>}
      </h2>
      {list.state.status === 'loading' && <p className="muted section__empty">Загружаем…</p>}
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {count === 0 && (
        <p className="muted section__empty">{d.status === 'open' ? 'Комментариев пока нет. Напишите первым.' : 'Комментариев не было.'}</p>
      )}
      {list.state.status === 'ready' && list.state.data.length > 0 && (
        <ul className="comments__list">
          {list.state.data.map((c) => (
            <li key={c.id} className="comment">
              <Avatar name={c.author.full_name} />
              <div className="comment__body">
                <div className="comment__meta">
                  <span className="comment__author">{c.author.full_name}</span>
                  {c.author.department && <span className="muted">{c.author.department.name}</span>}
                  <span className="comment__time">{formatDateTime(c.created_at)}</span>
                </div>
                <p className="prose">{c.text}</p>
              </div>
            </li>
          ))}
        </ul>
      )}
      {d.status === 'open' && (
        <form className="composer composer--with-avatar" onSubmit={send}>
          <Avatar name={me.full_name} />
          <div className="composer__box">
            <textarea
              className="composer__input"
              rows={2}
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => {
                // Ctrl/⌘ + Enter отправляет комментарий.
                if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) e.currentTarget.form?.requestSubmit();
              }}
              placeholder="Что думаете об этой идее?"
              aria-label="Комментарий"
            />
            <div className="composer__foot">
              {error ? <span className="error-text">{error}</span> : <span className="composer__hint">Ctrl + Enter — отправить</span>}
              <button type="submit" className="btn btn--sm composer__send" disabled={busy || !text.trim()}>
                {busy ? 'Отправляем…' : 'Отправить'}
                <ArrowUp size={15} aria-hidden="true" />
              </button>
            </div>
          </div>
        </form>
      )}
    </section>
  );
}
