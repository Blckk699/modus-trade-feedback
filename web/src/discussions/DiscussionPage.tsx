import { useState, type FormEvent } from 'react';
import { Link, useParams } from 'react-router-dom';
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

export function DiscussionPage() {
  const id = Number(useParams().id);
  const d = useAsync(
    () => unwrap(api.GET('/api/v1/discussions/{discussion_id}', { params: { path: { discussion_id: id } } })),
    [id],
  );

  const s = d.state;
  return (
    <section className="page">
      <Link to="/feed" className="back-link">
        ← Обсуждения
      </Link>
      {s.status === 'loading' && <p className="muted">Загружаем…</p>}
      {s.status === 'error' && (
        <div className="notice">
          <p className="error-text">
            {s.error instanceof ApiError && s.error.status === 404 ? 'Обсуждение не найдено.' : s.message}
          </p>
        </div>
      )}
      {s.status === 'ready' && <DiscussionView discussion={s.data} onUpdated={d.set} />}
    </section>
  );
}

function DiscussionView({ discussion: d, onUpdated }: { discussion: Discussion; onUpdated: (d: Discussion) => void }) {
  const dict = useDictionaries();
  // Решать про имя может только автор — значит, это его обращение.
  const isAuthorView = d.can_set_name_consent;
  const open = d.status === 'open';

  return (
    <article className="discussion">
      <header className="discussion__head">
        <div className="appeal-row__meta">
          <span className={`badge${open ? ' badge--status-new' : ''}`}>{open ? 'Идёт обсуждение' : 'Обсуждение завершено'}</span>
          <span className="badge">{dict.typeLabel(d.appeal.type)}</span>
        </div>
        <h1 className="page__title">{d.public_text}</h1>
        <p className="discussion__meta">
          <span>{d.author_display}</span>
          <span aria-hidden="true">·</span>
          <span>
            {open ? 'голосование до ' : 'срок был '}
            {formatDateTime(d.deadline)}
          </span>
        </p>
        {isAuthorView && (
          <Link to={`/appeals/${d.appeal.id}`} className="muted">
            Ваше обращение {d.appeal.number}
          </Link>
        )}
      </header>

      {d.can_set_name_consent && <NameConsent discussion={d} onUpdated={onUpdated} />}

      {!open && d.outcome && (
        <div className="notice notice--success">
          <h2 className="block__title">Итог</h2>
          <p className="prose">{d.outcome}</p>
          {d.closed_at && <p className="muted">Зафиксирован {formatDateTime(d.closed_at)}</p>}
        </div>
      )}

      <Votes discussion={d} onUpdated={onUpdated} />
      {d.can_close && open && <CloseForm discussion={d} onUpdated={onUpdated} />}
      <Comments discussion={d} />
    </article>
  );
}

const CONSENT_TEXT: Record<Schemas['NameConsent'], string> = {
  pending: 'Ваше обращение вынесли на общее обсуждение. Показывать ваше имя? Пока вы не ответили, указано только подразделение.',
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
          <button type="button" className="btn" disabled={busy} onClick={() => answer(true)}>
            Показать имя
          </button>
        )}
        {c !== 'hidden' && (
          <button type="button" className="btn btn--ghost" disabled={busy} onClick={() => answer(false)}>
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
    <div className="block vote">
      <div className="vote__head">
        <h2 className="block__title">Голосование</h2>
        <span className="muted">
          {total} {plural(total, ['голос', 'голоса', 'голосов'])}
        </span>
      </div>

      <div className="vote__options" role="group" aria-label={`За: ${d.votes_for}, против: ${d.votes_against}`}>
        {options.map((o) => {
          const mine = d.my_vote === o.value;
          const body = (
            <>
              <span className="vote__icon" aria-hidden="true">
                <ThumbIcon down={o.value === 'against'} />
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
            ? 'Голосование для вас недоступно. '
            : ''}
        Голосование совещательное: итог фиксирует руководитель.
      </p>
      {error && <p className="error-text">{error}</p>}
    </div>
  );
}

function ThumbIcon({ down }: { down: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width="20"
      height="20"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      style={down ? { transform: 'scaleY(-1)' } : undefined}
    >
      <path d="M7 10.5v9H4.5a1 1 0 0 1-1-1v-7a1 1 0 0 1 1-1H7z" />
      <path d="M7 10.5l3.6-6.3a1.6 1.6 0 0 1 2.95 1.1L12.8 9h5.6a2 2 0 0 1 1.96 2.4l-1.3 6.5a2 2 0 0 1-1.96 1.6H7" />
    </svg>
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
    <form className="block" onSubmit={submit}>
      <h2 className="block__title">Зафиксировать итог</h2>
      <label className="field">
        <span className="field__label">Итог обсуждения — его увидят все</span>
        <textarea className="input" rows={3} value={outcome} onChange={(e) => setOutcome(e.target.value)} required />
      </label>
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy || !outcome.trim()}>
          {busy ? 'Сохраняем…' : 'Зафиксировать итог'}
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
    <div className="block comments">
      <div className="vote__head">
        <h2 className="block__title">Комментарии</h2>
        {count !== null && count > 0 && <span className="muted">{count}</span>}
      </div>
      {list.state.status === 'loading' && <p className="muted">Загружаем…</p>}
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {count === 0 && (
        <p className="comments__empty">{d.status === 'open' ? 'Комментариев пока нет. Напишите первым.' : 'Комментариев не было.'}</p>
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
        <form className="comment-form" onSubmit={send}>
          <Avatar name={me.full_name} />
          <div className="comment-form__box">
            <textarea
              className="comment-form__input"
              rows={2}
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => {
                // Ctrl/⌘ + Enter отправляет комментарий.
                if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) e.currentTarget.form?.requestSubmit();
              }}
              placeholder="Поделитесь опытом или мнением"
              aria-label="Комментарий"
            />
            <div className="comment-form__foot">
              {error ? <span className="error-text">{error}</span> : <span className="comment-form__hint">Ctrl + Enter — отправить</span>}
              <button type="submit" className="btn comment-form__send" disabled={busy || !text.trim()}>
                {busy ? 'Отправляем…' : 'Отправить'}
              </button>
            </div>
          </div>
        </form>
      )}
    </div>
  );
}

const AVATAR_TONES = ['new', 'in_progress', 'implemented', 'awaiting_info', 'in_review', 'closed'] as const;

/** Кружок с инициалами. Цвет — из палитры статусов, выбирается по имени, чтобы у человека он был всегда один. */
function Avatar({ name }: { name: string }) {
  const parts = name.trim().split(/\s+/);
  const initials = ((parts[0]?.[0] ?? '') + (parts[1]?.[0] ?? '')).toUpperCase() || '?';
  let hash = 0;
  for (const ch of name) hash = (hash * 31 + ch.charCodeAt(0)) >>> 0;
  const tone = AVATAR_TONES[hash % AVATAR_TONES.length];
  return (
    <span className="avatar" style={{ background: `var(--status-${tone}-bg)`, color: `var(--status-${tone})` }} aria-hidden="true">
      {initials}
    </span>
  );
}
