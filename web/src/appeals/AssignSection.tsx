import { useState, type FormEvent } from 'react';
import { UserPlus } from 'lucide-react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { Select } from '../app/Select';
import { useToast } from '../app/Toast';
import { useAsync } from '../lib/useAsync';
import { assignable, byName } from '../settings/shared';

type Appeal = Schemas['Appeal'];

/**
 * Назначение ответственного прямо в карточке (история 70). Блок виден тому, кому бэкенд разрешил
 * `reassign`, пока у обращения нет ответственного: администратор открывает обращение из очереди
 * «Без ответственного» и назначает его здесь же. Причина при первом назначении необязательна.
 * Обращению без категории здесь же выбирают категорию — иначе оно не попадёт в разбивку сводки.
 */
export function AssignSection({ appeal, onUpdated }: { appeal: Appeal; onUpdated: (a: Appeal) => void }) {
  const toast = useToast();
  const users = useAsync(() => unwrap(api.GET('/api/v1/users')), []);
  const noCategory = appeal.category === null;
  const categories = useAsync(() => (noCategory ? unwrap(api.GET('/api/v1/categories')) : Promise.resolve([])), [noCategory]);
  const [categoryId, setCategoryId] = useState('');
  const [assigneeId, setAssigneeId] = useState('');
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const people = users.state.status === 'ready' ? assignable(users.state.data).sort(byName) : [];

  const pick = (id: string) => {
    setAssigneeId(id);
    setError('');
  };

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError('');
    if (!assigneeId) return setError('Выберите ответственного.');
    setBusy(true);
    try {
      const next = await unwrap(
        api.POST('/api/v1/appeals/{appeal_id}/reassign', {
          params: { path: { appeal_id: appeal.id } },
          body: {
            assignee_id: Number(assigneeId),
            reason: reason.trim() || null,
            ...(categoryId ? { category_id: Number(categoryId) } : {}),
          },
        }),
      );
      toast(`${next.number}: ответственный — ${next.assignee?.full_name ?? 'назначен'}`);
      onUpdated(next);
    } catch (err) {
      setError(errorMessage(err));
      setBusy(false);
    }
  }

  return (
    <section className="assign" aria-labelledby="assign-title">
      <div className="assign__head">
        <span className="assign__icon" aria-hidden="true">
          <UserPlus size={18} />
        </span>
        <div>
          <h2 id="assign-title" className="assign__title">
            Нет ответственного
          </h2>
          <p className="assign__why">
            {appeal.category ? `В категории «${appeal.category.name}» ответственный не задан.` : 'Категория не указана.'}{' '}
            Назначьте, кто ответит автору.
          </p>
        </div>
      </div>
      <form className="assign__form" onSubmit={submit} noValidate>
        <label className="field">
          <span className="field__label">Ответственный</span>
          <Select value={assigneeId} onChange={(e) => pick(e.target.value)} required disabled={busy}>
            <option value="">{users.state.status === 'loading' ? 'Загружаем сотрудников…' : 'Выберите сотрудника'}</option>
            {people.map((u) => (
              <option key={u.id} value={u.id}>
                {u.full_name}
                {u.department ? ` — ${u.department.name}` : ''}
                {u.is_absent ? ' (отсутствует)' : ''}
              </option>
            ))}
          </Select>
        </label>
        {noCategory && (
          <label className="field">
            <span className="field__label">
              Категория <span className="muted">· необязательно</span>
            </span>
            <Select value={categoryId} onChange={(e) => setCategoryId(e.target.value)} disabled={busy}>
              <option value="">{categories.state.status === 'loading' ? 'Загружаем категории…' : 'Оставить без категории'}</option>
              {(categories.state.status === 'ready' ? [...categories.state.data].sort(byName) : []).map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} — {c.department.name}
                </option>
              ))}
            </Select>
          </label>
        )}
        <label className="field">
          <span className="field__label">
            Причина <span className="muted">· необязательно</span>
          </span>
          <input
            className="input"
            value={reason}
            onChange={(e) => {
              setReason(e.target.value);
              setError('');
            }}
            placeholder="Например: вопрос в зоне IT"
            disabled={busy}
          />
        </label>
        <button type="submit" className="btn assign__submit" disabled={busy}>
          {busy ? 'Назначаем…' : 'Назначить'}
        </button>
      </form>
      {users.state.status === 'error' && (
        <p className="error-text" role="alert">
          Не удалось загрузить сотрудников: {users.state.message}
        </p>
      )}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
    </section>
  );
}
