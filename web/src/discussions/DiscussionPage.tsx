import { useState, type FormEvent } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatDateTime } from '../lib/format';
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
      <header className="appeal__head">
        <h1 className="page__title">{d.public_text}</h1>
        <div className="appeal-row__meta">
          <span className={`badge${open ? ' badge--status-in_review' : ''}`}>{open ? 'Идёт обсуждение' : 'Обсуждение завершено'}</span>
          <span className="muted">
            {dict.typeLabel(d.appeal.type)} · {d.author_display}
          </span>
          <span className="muted">
            {open ? 'Голосование до ' : 'Срок был '}
            {formatDateTime(d.deadline)}
          </span>
        </div>
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

  return (
    <div className="block">
      <h2 className="block__title">Голосование</h2>
      <div className="vote-score" aria-label={`За: ${d.votes_for}, против: ${d.votes_against}`}>
        <span>
          За <strong>{d.votes_for}</strong>
        </span>
        <span className="vote-score__bar" aria-hidden="true">
          {total > 0 && <span className="vote-score__for" style={{ width: `${forPct}%` }} />}
        </span>
        <span>
          Против <strong>{d.votes_against}</strong>
        </span>
      </div>
      {d.can_vote ? (
        <div className="form__actions">
          <button
            type="button"
            className={`btn${d.my_vote === 'for' ? '' : ' btn--ghost'}`}
            aria-pressed={d.my_vote === 'for'}
            disabled={busy}
            onClick={() => vote('for')}
          >
            👍 За
          </button>
          <button
            type="button"
            className={`btn${d.my_vote === 'against' ? '' : ' btn--ghost'}`}
            aria-pressed={d.my_vote === 'against'}
            disabled={busy}
            onClick={() => vote('against')}
          >
            👎 Против
          </button>
          {d.my_vote && <span className="muted">Нажмите на свой голос ещё раз, чтобы отозвать.</span>}
        </div>
      ) : (
        d.status === 'open' && <p className="muted">Голосование для вас недоступно.</p>
      )}
      <p className="muted field__hint">Голосование совещательное: итог фиксирует руководитель.</p>
      {error && <p className="error-text">{error}</p>}
    </div>
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
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function send(e: FormEvent) {
    e.preventDefault();
    if (!text.trim()) return;
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

  return (
    <div className="block">
      <h2 className="block__title">Комментарии</h2>
      {list.state.status === 'loading' && <p className="muted">Загружаем…</p>}
      {list.state.status === 'error' && <p className="error-text">{list.state.message}</p>}
      {list.state.status === 'ready' && list.state.data.length === 0 && <p className="muted">Комментариев пока нет.</p>}
      {list.state.status === 'ready' && list.state.data.length > 0 && (
        <ul className="thread">
          {list.state.data.map((c) => (
            <li key={c.id} className="thread__msg">
              <div className="thread__meta">
                <span>{c.author.full_name}</span>
                {c.author.department && <span className="muted">{c.author.department.name}</span>}
                <span className="muted">{formatDateTime(c.created_at)}</span>
              </div>
              <p className="prose">{c.text}</p>
            </li>
          ))}
        </ul>
      )}
      {d.status === 'open' && (
        <form className="composer" onSubmit={send}>
          <textarea
            className="input"
            rows={3}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Поделитесь опытом или мнением"
            aria-label="Комментарий"
          />
          <div className="form__actions">
            <button type="submit" className="btn" disabled={busy || !text.trim()}>
              {busy ? 'Отправляем…' : 'Комментировать'}
            </button>
            {error && <span className="error-text">{error}</span>}
          </div>
        </form>
      )}
    </div>
  );
}
