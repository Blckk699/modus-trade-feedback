import { useEffect, useState } from 'react';
import { ArrowLeft, ArrowRight } from 'lucide-react';
import { Link, useParams } from 'react-router-dom';
import { useBackground } from '../app/background';
import { PageHead } from '../app/PageHead';
import { TypeIcon } from '../appeals/TypeIcon';
import { useInCard } from '../pages/CardModal';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { MeetingStatusBadge } from './MeetingStatusBadge';
import { Select } from '../app/Select';

type Meeting = Schemas['Meeting'];
type Draft = Schemas['MeetingDraft'];
type DraftUpdate = Schemas['MeetingDraftUpdate'];

const POLL_MS = 3000;

/** Совещание: ход обработки, расшифровка, черновики с цитатами (истории 49–51). */
export function MeetingPage() {
  const id = Number(useParams().id);
  const meeting = useAsync(
    () => unwrap(api.GET('/api/v1/meetings/{meeting_id}', { params: { path: { meeting_id: id } } })),
    [id],
  );

  // Пока идёт обработка — опрашиваем GET /meetings/{id}, как велит контракт.
  // Сбой одного опроса не ломает экран: оставляем последние данные и пробуем снова на следующем тике.
  const processing = meeting.state.status === 'ready' && meeting.state.data.status === 'processing';
  const { set } = meeting;
  useEffect(() => {
    if (!processing) return;
    const t = window.setInterval(() => {
      unwrap(api.GET('/api/v1/meetings/{meeting_id}', { params: { path: { meeting_id: id } } }))
        .then(set)
        .catch(() => {});
    }, POLL_MS);
    return () => window.clearInterval(t);
  }, [processing, id, set]);

  const s = meeting.state;
  const inCard = useInCard();
  const body =
    s.status === 'loading' ? (
      <div className="sheet sheet--state" role="status">
        <span className="spinner" aria-hidden="true" /> Открываем совещание…
      </div>
    ) : s.status === 'error' ? (
      <div className="sheet sheet--state">
        <p className="error-text">{s.error instanceof ApiError && s.error.status === 404 ? 'Совещание не найдено.' : s.message}</p>
        {!(s.error instanceof ApiError && s.error.status === 404) && (
          <button type="button" className="btn btn--soft" onClick={meeting.reload}>
            Повторить
          </button>
        )}
      </div>
    ) : (
      <MeetingView meeting={s.data} onChange={meeting.set} />
    );

  if (inCard) return body;
  return (
    <section className="solo">
      <PageHead over="Совещания" title="Совещание" />
      <Link to="/meetings" className="back-link">
        <ArrowLeft size={16} aria-hidden="true" /> Совещания
      </Link>
      <div className="card solo__card">{body}</div>
    </section>
  );
}

function MeetingView({ meeting: m, onChange }: { meeting: Meeting; onChange: (m: Meeting) => void }) {
  const updateDraft = (d: Draft) => onChange({ ...m, drafts: m.drafts.map((x) => (x.id === d.id ? d : x)) });
  const pending = m.drafts.filter((d) => d.status === 'pending').length;

  return (
    <article className="sheet">
      <header className="sheet__head">
        <div className="sheet__state">
          <MeetingStatusBadge status={m.status} />
        </div>
      </header>
      <div className="sheet__scroll">
        <div>
          <h1 className="sheet__title">{m.title}</h1>
          <p className="sheet__sub">
            Загружено {formatDateTime(m.created_at)}
            {m.status === 'ready' &&
              (m.drafts.length === 0
                ? ''
                : pending > 0
                  ? ` · ${pending} из ${m.drafts.length} ждут решения`
                  : ` · все ${m.drafts.length} разобраны`)}
          </p>
        </div>

        {m.status === 'processing' && (
          <div className="notice" role="status" aria-live="polite">
            <p>
              <span className="spinner" aria-hidden="true" />
              Расшифровываем запись и ищем вопросы. Обычно это пара минут, экран обновится сам.
            </p>
          </div>
        )}
        {m.status === 'failed' && (
          <div className="notice notice--danger" role="alert">
            <p className="notice__title">Запись не обработалась</p>
            <p>{m.error ?? 'Причина неизвестна.'} Попробуйте загрузить её ещё раз.</p>
          </div>
        )}

        {m.status === 'ready' && (
          <>
            {m.drafts.length === 0 && <p className="muted">В записи не нашлось вопросов для обращений.</p>}
            <ul className="drafts">
              {m.drafts.map((d) => (
                <li key={d.id}>
                  <DraftCard draft={d} onUpdated={updateDraft} />
                </li>
              ))}
            </ul>
            {m.transcript && (
              <details className="transcript">
                <summary>Расшифровка целиком</summary>
                <p className="prose">{m.transcript}</p>
              </details>
            )}
          </>
        )}
      </div>
    </article>
  );
}

interface Form {
  type: Schemas['AppealType'];
  categoryId: string;
  priority: Schemas['Priority'];
  summary: string;
  text: string;
  proposedSolution: string;
  authorId: string;
}

function toForm(d: Draft): Form {
  return {
    type: d.type,
    categoryId: d.category ? String(d.category.id) : '',
    priority: d.priority,
    summary: d.summary,
    text: d.text,
    proposedSolution: d.proposed_solution ?? '',
    authorId: d.author ? String(d.author.id) : '',
  };
}

function toUpdate(f: Form): DraftUpdate {
  return {
    type: f.type,
    category_id: f.categoryId ? Number(f.categoryId) : null,
    priority: f.priority,
    summary: f.summary.trim(),
    text: f.text.trim(),
    proposed_solution: f.proposedSolution.trim() || null,
    author_id: f.authorId ? Number(f.authorId) : null,
  };
}

function DraftCard({ draft: d, onUpdated }: { draft: Draft; onUpdated: (d: Draft) => void }) {
  const dict = useDictionaries();
  const background = useBackground();
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<Form>(() => toForm(d));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const set = (patch: Partial<Form>) => setForm((f) => ({ ...f, ...patch }));
  const path = { params: { path: { meeting_id: d.meeting_id, draft_id: d.id } } };
  const valid = Boolean(form.summary.trim() && form.text.trim());

  async function run(action: () => Promise<void>) {
    setBusy(true);
    setError('');
    try {
      await action();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  const save = () =>
    run(async () => {
      const next = await unwrap(api.PATCH('/api/v1/meetings/{meeting_id}/drafts/{draft_id}', { ...path, body: toUpdate(form) }));
      onUpdated(next);
      setForm(toForm(next));
      setEditing(false);
    });

  // Подтверждение сразу передаёт текущие правки (контракт это разрешает) и создаёт обращение.
  const confirm = () =>
    run(async () => {
      const appeal = await unwrap(
        api.POST('/api/v1/meetings/{meeting_id}/drafts/{draft_id}/confirm', { ...path, body: toUpdate(form) }),
      );
      onUpdated({
        ...d,
        status: 'confirmed',
        summary: appeal.summary ?? d.summary,
        appeal: { id: appeal.id, number: appeal.number, summary: appeal.summary, status: appeal.status, type: appeal.type },
      });
      setEditing(false);
    });

  const discard = () =>
    run(async () => {
      onUpdated(await unwrap(api.POST('/api/v1/meetings/{meeting_id}/drafts/{draft_id}/discard', path)));
      setEditing(false);
    });

  return (
    <article className={`draft draft--${d.status}`}>
      <div className="draft__top">
        <TypeIcon type={editing ? form.type : d.type} />
        <span className="draft__meta">
          {dict.typeLabel(editing ? form.type : d.type)} · {d.category?.name ?? 'без категории'} · приоритет{' '}
          {dict.priorityLabel(d.priority).toLowerCase()}
        </span>
        {d.status === 'confirmed' && <span className="badge badge--dot badge--status-implemented">Подтверждён</span>}
        {d.status === 'discarded' && <span className="badge">Отброшен</span>}
      </div>

      {!editing && (
        <>
          <h3 className="draft__summary">{d.summary}</h3>
          <p className="prose">{d.text}</p>
          {d.proposed_solution && (
            <p className="muted">
              Как решить: {d.proposed_solution}
            </p>
          )}
        </>
      )}

      <blockquote className="quote">{d.quote}</blockquote>

      {!editing && <p className="draft__author">Автор: {d.author?.full_name ?? 'вы, как загрузивший запись'}</p>}

      {editing && d.status === 'pending' && <DraftForm form={form} set={set} />}

      {d.status === 'confirmed' && d.appeal && (
        <Link to={`/appeals/${d.appeal.id}`} state={{ background }} className="more-link">
          Обращение {d.appeal.number} <ArrowRight size={15} aria-hidden="true" />
        </Link>
      )}

      {d.status === 'pending' && (
        <div className="draft__actions">
          <button type="button" className="btn btn--sm" disabled={busy || !valid} onClick={confirm}>
            {editing ? 'Сохранить и подтвердить' : 'Подтвердить'}
          </button>
          {editing ? (
            <>
              <button type="button" className="btn btn--soft btn--sm" disabled={busy || !valid} onClick={save}>
                Сохранить
              </button>
              <button
                type="button"
                className="btn btn--text btn--sm"
                disabled={busy}
                onClick={() => {
                  setForm(toForm(d));
                  setEditing(false);
                }}
              >
                Отмена
              </button>
            </>
          ) : (
            <button type="button" className="btn btn--soft btn--sm" disabled={busy} onClick={() => setEditing(true)}>
              Поправить
            </button>
          )}
          <button type="button" className="btn btn--text btn--danger btn--sm draft__discard" disabled={busy} onClick={discard}>
            Отбросить
          </button>
          {error && (
            <span className="error-text" role="alert">
              {error}
            </span>
          )}
        </div>
      )}
    </article>
  );
}

function DraftForm({ form, set }: { form: Form; set: (p: Partial<Form>) => void }) {
  const dict = useDictionaries();
  const categories = useAsync(() => unwrap(api.GET('/api/v1/categories')), []);
  const users = useAsync(() => unwrap(api.GET('/api/v1/users')), []);

  return (
    <div className="draft__form">
      <div className="form__row">
        <label className="field">
          <span className="field__label">Тип</span>
          <Select value={form.type} onChange={(e) => set({ type: e.target.value as Form['type'] })}>
            {(dict.data?.appeal_types ?? []).map((t) => (
              <option key={t.code} value={t.code}>
                {t.label}
              </option>
            ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Категория</span>
          <Select value={form.categoryId} onChange={(e) => set({ categoryId: e.target.value })}>
            <option value="">Не указана</option>
            {categories.state.status === 'ready' &&
              categories.state.data
                .filter((c) => c.is_active)
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Приоритет</span>
          <Select value={form.priority} onChange={(e) => set({ priority: e.target.value as Form['priority'] })}>
            {(dict.data?.priorities ?? []).map((p) => (
              <option key={p.code} value={p.code}>
                {p.label}
              </option>
            ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Автор</span>
          <Select value={form.authorId} onChange={(e) => set({ authorId: e.target.value })}>
            <option value="">Я, как загрузивший запись</option>
            {users.state.status === 'ready' &&
              users.state.data
                .filter((u) => !u.is_disabled)
                .map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.full_name}
                    {u.department ? ` — ${u.department.name}` : ''}
                  </option>
                ))}
          </Select>
        </label>
      </div>
      <label className="field">
        <span className="field__label">Краткая суть</span>
        <input className="input" value={form.summary} onChange={(e) => set({ summary: e.target.value })} required />
      </label>
      <label className="field">
        <span className="field__label">Описание</span>
        <textarea className="input" rows={4} value={form.text} onChange={(e) => set({ text: e.target.value })} required />
      </label>
      <label className="field">
        <span className="field__label">
          Как это можно решить <span className="muted">· необязательно</span>
        </span>
        <textarea className="input" rows={2} value={form.proposedSolution} onChange={(e) => set({ proposedSolution: e.target.value })} />
      </label>
    </div>
  );
}
