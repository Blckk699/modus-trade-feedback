import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { assignable, byName, type User } from './shared';

type Item = Schemas['AppealListItem'];

function loadAll() {
  return Promise.all([
    unwrap(api.GET('/api/v1/appeals', { params: { query: { scope: 'unassigned', sort: 'created_asc', page_size: 100 } } })),
    unwrap(api.GET('/api/v1/users')),
  ]);
}

/** Очередь нераспределённых: администратор назначает ответственного вручную (история 70). */
export function UnassignedTab() {
  const data = useAsync(loadAll, []);
  const [done, setDone] = useState<{ number: string; assignee: string }[]>([]);

  const s = data.state;
  if (s.status === 'loading') return <p className="muted">Загружаем…</p>;
  if (s.status === 'error')
    return (
      <div className="notice">
        <p className="error-text">{s.message}</p>
        <button type="button" className="btn btn--ghost" onClick={data.reload}>
          Повторить
        </button>
      </div>
    );

  const [page, users] = s.data;
  const people = assignable(users).sort(byName);
  const assigned = (item: Item, assignee: string) => {
    data.set([{ ...page, items: page.items.filter((i) => i.id !== item.id), total: page.total - 1 }, users]);
    setDone((d) => [{ number: item.number, assignee }, ...d]);
  };

  return (
    <div className="settings-tab">
      {done.map((d) => (
        <p key={d.number} className="notice notice--success">
          {d.number} назначено: {d.assignee}.
        </p>
      ))}
      {page.items.length === 0 ? (
        <div className="notice">
          <p>Нераспределённых обращений нет.</p>
          <p className="muted">Сюда попадают обращения без категории или из категории без ответственного.</p>
        </div>
      ) : (
        <ul className="settings-list">
          {page.items.map((item) => (
            <UnassignedRow key={item.id} item={item} people={people} onAssigned={assigned} />
          ))}
        </ul>
      )}
    </div>
  );
}

function UnassignedRow({ item, people, onAssigned }: { item: Item; people: User[]; onAssigned: (i: Item, name: string) => void }) {
  const dict = useDictionaries();
  const [assigneeId, setAssigneeId] = useState('');
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError('');
    if (!assigneeId) return setError('Выберите ответственного.');
    if (!reason.trim()) return setError('Укажите причину — она попадёт в историю обращения.');
    setBusy(true);
    try {
      const appeal = await unwrap(
        api.POST('/api/v1/appeals/{appeal_id}/reassign', {
          params: { path: { appeal_id: item.id } },
          body: { assignee_id: Number(assigneeId), reason: reason.trim() },
        }),
      );
      onAssigned(item, appeal.assignee?.full_name ?? people.find((p) => p.id === Number(assigneeId))?.full_name ?? '');
    } catch (err) {
      setError(errorMessage(err));
      setBusy(false);
    }
  }

  return (
    <li>
      <form className="form settings-form" onSubmit={submit} noValidate>
        <div className="settings-row__main">
          <span>
            <Link to={`/appeals/${item.id}`} className="appeal-row__number">
              {item.number}
            </Link>{' '}
            <span className="muted">
              {dict.typeLabel(item.type)} · {dict.priorityLabel(item.priority)} · {formatDateTime(item.created_at)}
            </span>
          </span>
          <strong>{item.summary ?? 'Без краткой сути'}</strong>
          <span className="muted">
            {item.category ? `Категория: ${item.category.name} — без ответственного` : 'Категория не указана'}
            {item.author ? ` · Автор: ${item.author.full_name}` : ''}
          </span>
        </div>
        <div className="settings-grid">
          <label className="field">
            <span className="field__label">Ответственный</span>
            <select className="input" value={assigneeId} onChange={(e) => setAssigneeId(e.target.value)}>
              <option value="">Выберите…</option>
              {people.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.full_name}
                  {u.department ? ` — ${u.department.name}` : ''}
                  {u.is_absent ? ' (отсутствует)' : ''}
                </option>
              ))}
            </select>
          </label>
          <label className="field">
            <span className="field__label">Причина</span>
            <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Например: вопрос в зоне IT" />
          </label>
        </div>
        <div className="form__actions">
          <button type="submit" className="btn" disabled={busy}>
            {busy ? 'Назначаем…' : 'Назначить'}
          </button>
          {error && <span className="error-text">{error}</span>}
        </div>
      </form>
    </li>
  );
}
