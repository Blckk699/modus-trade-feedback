import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { MeetingStatusBadge } from './MeetingStatusBadge';

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
  const processing = meeting.state.status === 'ready' && meeting.state.data.status === 'processing';
  useEffect(() => {
    if (!processing) return;
    const t = window.setInterval(meeting.reload, POLL_MS);
    return () => window.clearInterval(t);
  }, [processing, meeting.reload]);

  const s = meeting.state;
  return (
    <section className="page">
      <Link to="/meetings" className="back-link">
        ← Совещания
      </Link>
      {s.status === 'loading' && <p className="muted">Загружаем…</p>}
      {s.status === 'error' && (
        <p className="error-text">
          {s.error instanceof ApiError && s.error.status === 404 ? 'Совещание не найдено.' : s.message}
        </p>
      )}
      {s.status === 'ready' && <MeetingView meeting={s.data} onChange={meeting.set} />}
    </section>
  );
}

function MeetingView({ meeting: m, onChange }: { meeting: Meeting; onChange: (m: Meeting) => void }) {
  const updateDraft = (d: Draft) => onChange({ ...m, drafts: m.drafts.map((x) => (x.id === d.id ? d : x)) });
  const pending = m.drafts.filter((d) => d.status === 'pending').length;

  return (
    <>
      <header className="appeal__head">
        <h1 className="page__title">{m.title}</h1>
        <div className="appeal-row__meta">
          <MeetingStatusBadge status={m.status} />
          <span className="muted">Загружено {formatDateTime(m.created_at)}</span>
        </div>
      </header>

      {m.status === 'processing' && (
        <div className="notice" role="status" aria-live="polite">
          <span className="spinner" aria-hidden="true" /> Расшифровываем запись и ищем вопросы. Это займёт пару минут —
          страница обновится сама.
        </div>
      )}
      {m.status === 'failed' && (
        <div className="notice notice--danger" role="alert">
          {m.error ?? 'Не удалось обработать запись.'} Попробуйте загрузить её ещё раз.
        </div>
      )}

      {m.status === 'ready' && (
        <>
          <p className="muted">
            {m.drafts.length === 0
              ? 'В записи не нашлось вопросов для обращений.'
              : pending > 0
                ? `Черновиков: ${m.drafts.length}. Ждут решения: ${pending}. Проверьте каждый: подтвердите, поправьте или отбросьте.`
                : `Все черновики разобраны (${m.drafts.length}).`}
          </p>
          <ul className="drafts">
            {m.drafts.map((d) => (
              <li key={d.id}>
                <DraftCard draft={d} onUpdated={updateDraft} />
              </li>
            ))}
          </ul>
          {m.transcript && (
            <details className="block">
              <summary className="block__title">Расшифровка</summary>
              <p className="prose transcript">{m.transcript}</p>
            </details>
          )}
        </>
      )}
    </>
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
    <article className={`block draft draft--${d.status}`}>
      <div className="appeal-row__top">
        <span className="badge">{dict.typeLabel(editing ? form.type : d.type)}</span>
        <span className="muted">
          {d.category?.name ?? 'Без категории'} · {dict.priorityLabel(d.priority)}
        </span>
        <span className="appeal-row__date">
          {d.status === 'confirmed' && <span className="badge badge--status-implemented">Подтверждён</span>}
          {d.status === 'discarded' && <span className="badge">Отброшен</span>}
        </span>
      </div>

      <blockquote className="quote">{d.quote}</blockquote>

      {!editing && (
        <>
          <h3 className="draft__summary">{d.summary}</h3>
          <p className="prose">{d.text}</p>
          {d.proposed_solution && <p className="muted">Предлагаемое решение: {d.proposed_solution}</p>}
          <p className="muted">Автор: {d.author?.full_name ?? 'вы (загрузивший запись)'}</p>
        </>
      )}

      {editing && d.status === 'pending' && <DraftForm form={form} set={set} />}

      {d.status === 'confirmed' && d.appeal && (
        <p>
          Создано обращение <Link to={`/appeals/${d.appeal.id}`}>{d.appeal.number}</Link>
        </p>
      )}

      {d.status === 'pending' && (
        <div className="form__actions">
          <button type="button" className="btn" disabled={busy || !valid} onClick={confirm}>
            Подтвердить
          </button>
          {editing ? (
            <>
              <button type="button" className="btn btn--ghost" disabled={busy || !valid} onClick={save}>
                Сохранить правки
              </button>
              <button
                type="button"
                className="btn btn--ghost"
                disabled={busy}
                onClick={() => {
                  setForm(toForm(d));
                  setEditing(false);
                }}
              >
                Отменить
              </button>
            </>
          ) : (
            <button type="button" className="btn btn--ghost" disabled={busy} onClick={() => setEditing(true)}>
              Поправить
            </button>
          )}
          <button type="button" className="btn btn--ghost btn--danger" disabled={busy} onClick={discard}>
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
      <div className="filters">
        <label className="field">
          <span className="field__label">Тип</span>
          <select className="input" value={form.type} onChange={(e) => set({ type: e.target.value as Form['type'] })}>
            {(dict.data?.appeal_types ?? []).map((t) => (
              <option key={t.code} value={t.code}>
                {t.label}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span className="field__label">Категория</span>
          <select className="input" value={form.categoryId} onChange={(e) => set({ categoryId: e.target.value })}>
            <option value="">Не указана</option>
            {categories.state.status === 'ready' &&
              categories.state.data
                .filter((c) => c.is_active)
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
          </select>
        </label>
        <label className="field">
          <span className="field__label">Приоритет</span>
          <select className="input" value={form.priority} onChange={(e) => set({ priority: e.target.value as Form['priority'] })}>
            {(dict.data?.priorities ?? []).map((p) => (
              <option key={p.code} value={p.code}>
                {p.label}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span className="field__label">Автор</span>
          <select className="input" value={form.authorId} onChange={(e) => set({ authorId: e.target.value })}>
            <option value="">Я (загрузивший)</option>
            {users.state.status === 'ready' &&
              users.state.data
                .filter((u) => !u.is_disabled)
                .map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.full_name}
                    {u.department ? ` — ${u.department.name}` : ''}
                  </option>
                ))}
          </select>
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
          Предлагаемое решение <span className="muted">— необязательно</span>
        </span>
        <textarea className="input" rows={2} value={form.proposedSolution} onChange={(e) => set({ proposedSolution: e.target.value })} />
      </label>
    </div>
  );
}
