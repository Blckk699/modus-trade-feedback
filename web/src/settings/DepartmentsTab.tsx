import { RowsSkeleton } from '../app/ListStates';
import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { useAsync } from '../lib/useAsync';
import { assignable, byName, changes, fieldErrors, idOrNull, type Department, type User } from './shared';
import { Select } from '../app/Select';

function loadAll() {
  return Promise.all([unwrap(api.GET('/api/v1/departments')), unwrap(api.GET('/api/v1/users'))]);
}

/** Подразделения и их руководители: по ним идёт эскалация (история 66). */
export function DepartmentsTab() {
  const data = useAsync(loadAll, []);
  const [adding, setAdding] = useState(false);
  const [editing, setEditing] = useState<number | null>(null);

  const s = data.state;
  if (s.status === 'loading') return <RowsSkeleton />;
  if (s.status === 'error')
    return (
      <div className="notice">
        <p className="error-text">{s.message}</p>
        <button type="button" className="btn btn--ghost" onClick={data.reload}>
          Повторить
        </button>
      </div>
    );

  const [departments, users] = s.data;
  const replace = (d: Department) =>
    data.set([departments.some((x) => x.id === d.id) ? departments.map((x) => (x.id === d.id ? d : x)) : [...departments, d], users]);

  return (
    <div className="settings-tab">
      <div className="settings-toolbar">
        <p className="muted">Руководитель получает эскалацию, если ответственный не ответил в срок, и утреннюю сводку по подразделению.</p>
        {!adding && (
          <button type="button" className="btn" onClick={() => setAdding(true)}>
            Добавить подразделение
          </button>
        )}
      </div>
      {adding && (
        <DepartmentForm
          users={users}
          onCancel={() => setAdding(false)}
          onSaved={(d) => {
            replace(d);
            setAdding(false);
          }}
        />
      )}
      <ul className="settings-list">
        {[...departments].sort(byName).map((d) =>
          editing === d.id ? (
            <li key={d.id}>
              <DepartmentForm
                department={d}
                users={users}
                onCancel={() => setEditing(null)}
                onSaved={(saved) => {
                  replace(saved);
                  setEditing(null);
                }}
              />
            </li>
          ) : (
            <li key={d.id} className="settings-row">
              <div className="settings-row__main">
                <strong>{d.name}</strong>
                <span className={d.head ? 'muted' : 'error-text'}>{d.head ? `Руководитель: ${d.head.full_name}` : 'Руководитель не назначен'}</span>
              </div>
              <button type="button" className="btn btn--ghost" onClick={() => setEditing(d.id)}>
                Изменить
              </button>
            </li>
          ),
        )}
      </ul>
    </div>
  );
}

interface DepartmentFormProps {
  department?: Department;
  users: User[];
  onSaved: (d: Department) => void;
  onCancel: () => void;
}

function DepartmentForm({ department, users, onSaved, onCancel }: DepartmentFormProps) {
  const [name, setName] = useState(department?.name ?? '');
  const [headId, setHeadId] = useState(department?.head ? String(department.head.id) : '');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  // Действующие сотрудники, кроме администратора (иначе бэкенд ответит 422); роль «руководитель» — первой.
  const candidates = assignable(users).sort((a, b) => Number(b.role === 'head') - Number(a.role === 'head') || byName(a, b));

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setErrors({});
    if (!name.trim()) return setErrors({ name: 'Укажите название.' });
    setBusy(true);
    try {
      const fields = { name: name.trim(), head_id: idOrNull(headId) };
      let saved: Department;
      if (department) {
        const body = changes({ name: department.name, head_id: department.head?.id ?? null }, fields);
        saved = Object.keys(body).length
          ? await unwrap(
              api.PATCH('/api/v1/admin/departments/{department_id}', { params: { path: { department_id: department.id } }, body }),
            )
          : department;
      } else {
        saved = await unwrap(api.POST('/api/v1/admin/departments', { body: fields }));
      }
      onSaved(saved);
    } catch (err) {
      setErrors(fieldErrors(err));
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="form settings-form" onSubmit={submit} noValidate>
      <div className="settings-grid">
        <label className="field">
          <span className="field__label">Название</span>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} aria-invalid={!!errors.name} />
          {errors.name && <span className="field__hint error-text">{errors.name}</span>}
        </label>
        <label className="field">
          <span className="field__label">Руководитель</span>
          <Select value={headId} onChange={(e) => setHeadId(e.target.value)} aria-invalid={!!errors.head_id}>
            <option value="">Не назначен</option>
            {candidates.map((u) => (
              <option key={u.id} value={u.id}>
                {u.full_name}
                {u.department ? ` — ${u.department.name}` : ''}
              </option>
            ))}
          </Select>
          {errors.head_id && <span className="field__hint error-text">{errors.head_id}</span>}
        </label>
      </div>
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Сохраняем…' : department ? 'Сохранить' : 'Добавить'}
        </button>
        <button type="button" className="btn btn--ghost" onClick={onCancel} disabled={busy}>
          Отмена
        </button>
        {error && <span className="error-text">{error}</span>}
      </div>
    </form>
  );
}
