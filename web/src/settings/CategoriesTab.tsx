import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { useAsync } from '../lib/useAsync';
import { assignable, byName, changes, fieldErrors, idOrNull, type Category, type Department, type User } from './shared';

function loadAll() {
  return Promise.all([
    unwrap(api.GET('/api/v1/categories', { params: { query: { include_inactive: true } } })),
    unwrap(api.GET('/api/v1/departments')),
    unwrap(api.GET('/api/v1/users')),
  ]);
}

/** Категории с ответственным и заместителем: по ним обращения распределяются сами (история 67). */
export function CategoriesTab() {
  const data = useAsync(loadAll, []);
  const [adding, setAdding] = useState(false);
  const [editing, setEditing] = useState<number | null>(null);

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

  const [categories, departments, users] = s.data;
  const replace = (c: Category) =>
    data.set([categories.some((x) => x.id === c.id) ? categories.map((x) => (x.id === c.id ? c : x)) : [...categories, c], departments, users]);
  const sorted = [...categories].sort((a, b) => Number(b.is_active) - Number(a.is_active) || byName(a, b));

  return (
    <div className="settings-tab">
      <div className="settings-toolbar">
        <p className="muted">Новое обращение категории получает ответственный, а если он отсутствует — заместитель. Уже назначенные обращения при изменении не переназначаются.</p>
        {!adding && (
          <button type="button" className="btn" onClick={() => setAdding(true)}>
            Добавить категорию
          </button>
        )}
      </div>
      {adding && (
        <CategoryForm
          departments={departments}
          users={users}
          onCancel={() => setAdding(false)}
          onSaved={(c) => {
            replace(c);
            setAdding(false);
          }}
        />
      )}
      <ul className="settings-list">
        {sorted.map((c) =>
          editing === c.id ? (
            <li key={c.id}>
              <CategoryForm
                category={c}
                departments={departments}
                users={users}
                onCancel={() => setEditing(null)}
                onSaved={(saved) => {
                  replace(saved);
                  setEditing(null);
                }}
              />
            </li>
          ) : (
            <li key={c.id} className={`settings-row${c.is_active ? '' : ' settings-row--off'}`}>
              <div className="settings-row__main">
                <strong>{c.name}</strong>
                <span className="muted">{c.department.name}</span>
                <span className={c.responsible ? 'muted' : 'error-text'}>
                  Ответственный: {c.responsible?.full_name ?? 'не назначен — обращения уйдут в очередь администратора'}
                </span>
                <span className="muted">Заместитель: {c.deputy?.full_name ?? 'нет'}</span>
              </div>
              <div className="settings-row__badges">{!c.is_active && <span className="badge">Не используется</span>}</div>
              <button type="button" className="btn btn--ghost" onClick={() => setEditing(c.id)}>
                Изменить
              </button>
            </li>
          ),
        )}
      </ul>
    </div>
  );
}

interface CategoryFormProps {
  category?: Category;
  departments: Department[];
  users: User[];
  onSaved: (c: Category) => void;
  onCancel: () => void;
}

function CategoryForm({ category, departments, users, onSaved, onCancel }: CategoryFormProps) {
  const [name, setName] = useState(category?.name ?? '');
  const [departmentId, setDepartmentId] = useState(category ? String(category.department.id) : '');
  const [responsibleId, setResponsibleId] = useState(category?.responsible ? String(category.responsible.id) : '');
  const [deputyId, setDeputyId] = useState(category?.deputy ? String(category.deputy.id) : '');
  const [active, setActive] = useState(category?.is_active ?? true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const people = assignable(users).sort(byName);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError('');
    const local: Record<string, string> = {};
    if (!name.trim()) local.name = 'Укажите название.';
    if (!departmentId) local.department_id = 'Выберите подразделение.';
    if (responsibleId && responsibleId === deputyId) local.deputy_id = 'Заместитель должен отличаться от ответственного.';
    setErrors(local);
    if (Object.keys(local).length) return;
    setBusy(true);
    try {
      const fields = {
        name: name.trim(),
        department_id: Number(departmentId),
        responsible_id: idOrNull(responsibleId),
        deputy_id: idOrNull(deputyId),
      };
      let saved: Category;
      if (category) {
        const before = {
          name: category.name,
          department_id: category.department.id,
          responsible_id: category.responsible?.id ?? null,
          deputy_id: category.deputy?.id ?? null,
          is_active: category.is_active,
        };
        const body = changes(before, { ...fields, is_active: active });
        saved = Object.keys(body).length
          ? await unwrap(api.PATCH('/api/v1/admin/categories/{category_id}', { params: { path: { category_id: category.id } }, body }))
          : category;
      } else {
        saved = await unwrap(api.POST('/api/v1/admin/categories', { body: fields }));
      }
      onSaved(saved);
    } catch (err) {
      setErrors(fieldErrors(err));
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  const personSelect = (value: string, set: (v: string) => void, empty: string, field: string) => (
    <>
      <select className="input" value={value} onChange={(e) => set(e.target.value)} aria-invalid={!!errors[field]}>
        <option value="">{empty}</option>
        {people.map((u) => (
          <option key={u.id} value={u.id}>
            {u.full_name}
            {u.department ? ` — ${u.department.name}` : ''}
            {u.is_absent ? ' (отсутствует)' : ''}
          </option>
        ))}
      </select>
      {errors[field] && <span className="field__hint error-text">{errors[field]}</span>}
    </>
  );

  return (
    <form className="form settings-form" onSubmit={submit} noValidate>
      <div className="settings-grid">
        <label className="field">
          <span className="field__label">Название</span>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} aria-invalid={!!errors.name} />
          {errors.name && <span className="field__hint error-text">{errors.name}</span>}
        </label>
        <label className="field">
          <span className="field__label">Подразделение</span>
          <select className="input" value={departmentId} onChange={(e) => setDepartmentId(e.target.value)} aria-invalid={!!errors.department_id}>
            <option value="">Выберите…</option>
            {[...departments].sort(byName).map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </select>
          {errors.department_id && <span className="field__hint error-text">{errors.department_id}</span>}
        </label>
        <label className="field">
          <span className="field__label">Ответственный</span>
          {personSelect(responsibleId, setResponsibleId, 'Не назначен', 'responsible_id')}
        </label>
        <label className="field">
          <span className="field__label">Заместитель</span>
          {personSelect(deputyId, setDeputyId, 'Нет', 'deputy_id')}
        </label>
      </div>
      {category && (
        <div className="settings-checks">
          <label>
            <input type="checkbox" checked={active} onChange={(e) => setActive(e.target.checked)} /> Используется — категорию можно
            выбрать при подаче обращения
          </label>
        </div>
      )}
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Сохраняем…' : category ? 'Сохранить' : 'Добавить'}
        </button>
        <button type="button" className="btn btn--ghost" onClick={onCancel} disabled={busy}>
          Отмена
        </button>
        {error && <span className="error-text">{error}</span>}
      </div>
    </form>
  );
}
