import { RowsSkeleton } from '../app/ListStates';
import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { useAsync } from '../lib/useAsync';
import { assignable, byName, changes, fieldErrors, idOrNull, type Category, type Department, type User } from './shared';
import { Modal } from '../app/Modal';
import { Select } from '../app/Select';
import { useToast } from '../app/Toast';

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
  // Пока форма сохраняется, окно не закрывается: иначе ошибку сервера не увидеть.
  const [saving, setSaving] = useState(false);
  const [switching, setSwitching] = useState<number | null>(null);
  // Удаление — в два нажатия: первое спрашивает, второе удаляет.
  const [confirming, setConfirming] = useState<number | null>(null);
  const [removing, setRemoving] = useState<number | null>(null);
  const toast = useToast();

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

  const [categories, departments, users] = s.data;
  const replace = (c: Category) =>
    data.set([categories.some((x) => x.id === c.id) ? categories.map((x) => (x.id === c.id ? c : x)) : [...categories, c], departments, users]);
  // Выключенную категорию нельзя выбрать при подаче; поданные по ней обращения остаются у ответственного.
  async function setActive(c: Category, isActive: boolean) {
    setSwitching(c.id);
    try {
      replace(await unwrap(api.PATCH('/api/v1/admin/categories/{category_id}', { params: { path: { category_id: c.id } }, body: { is_active: isActive } })));
      toast(isActive ? `«${c.name}» снова можно выбрать при подаче` : `«${c.name}» выключена: при подаче её больше не выбрать`);
    } catch (e) {
      toast(errorMessage(e), 'error');
    } finally {
      setSwitching(null);
    }
  }
  // Удалить можно только категорию без обращений. Если обращения есть, сервер отвечает 409
  // и сам объясняет, что делать: показываем его текст.
  async function remove(c: Category) {
    setRemoving(c.id);
    try {
      await unwrap(api.DELETE('/api/v1/admin/categories/{category_id}', { params: { path: { category_id: c.id } } }));
      data.set([categories.filter((x) => x.id !== c.id), departments, users]);
      toast(`Категория «${c.name}» удалена`);
    } catch (e) {
      toast(errorMessage(e), 'error');
    } finally {
      setRemoving(null);
      setConfirming(null);
    }
  }
  const sorted = [...categories].sort((a, b) => Number(b.is_active) - Number(a.is_active) || byName(a, b));

  const edited = editing === null ? undefined : categories.find((c) => c.id === editing);
  const formOpen = adding || edited !== undefined;
  const closeForm = () => {
    setAdding(false);
    setEditing(null);
  };

  return (
    <div className="settings-tab">
      <div className="settings-toolbar">
        <p className="muted">Новое обращение получает ответственный за категорию, а когда его нет на месте, заместитель. Уже назначенные обращения остаются у прежнего ответственного.</p>
        <button type="button" className="btn" onClick={() => setAdding(true)}>
          Добавить категорию
        </button>
      </div>
      <ul className="settings-list">
        {sorted.map((c) => (
            <li key={c.id} className={`settings-row${c.is_active ? '' : ' settings-row--off'}`}>
              <div className="settings-row__main">
                <strong>{c.name}</strong>
                <span className="muted">{c.department.name}</span>
                <span className={c.responsible ? 'muted' : 'error-text'}>
                  Ответственный: {c.responsible?.full_name ?? 'не назначен, обращения уйдут администратору'}
                </span>
                <span className="muted">Заместитель: {c.deputy?.full_name ?? 'нет'}</span>
              </div>
              <div className="settings-row__badges">{!c.is_active && <span className="badge">Выключена</span>}</div>
              <div className="settings-row__actions">
                <button
                  type="button"
                  className="btn btn--text"
                  disabled={switching === c.id}
                  onClick={() => void setActive(c, !c.is_active)}
                  title={c.is_active ? 'Категорию нельзя будет выбрать при подаче обращения' : 'Категорию снова можно будет выбрать при подаче'}
                >
                  {switching === c.id ? '…' : c.is_active ? 'Выключить' : 'Включить'}
                </button>
                <button type="button" className="btn btn--ghost" onClick={() => setEditing(c.id)}>
                  Изменить
                </button>
                {confirming === c.id ? (
                  <>
                    <button type="button" className="btn btn--text btn--danger" disabled={removing === c.id} onClick={() => void remove(c)}>
                      {removing === c.id ? 'Удаляем…' : 'Да, удалить'}
                    </button>
                    <button type="button" className="btn btn--text" disabled={removing === c.id} onClick={() => setConfirming(null)}>
                      Отмена
                    </button>
                  </>
                ) : (
                  <button
                    type="button"
                    className="btn btn--text btn--danger"
                    onClick={() => setConfirming(c.id)}
                    title="Удалить можно категорию, в которой нет обращений. Остальные — только выключить"
                  >
                    Удалить
                  </button>
                )}
              </div>
            </li>
        ))}
      </ul>

      {/* Добавление и правка — в окне поверх списка, как у сотрудников. key сбрасывает поля при смене записи. */}
      <Modal open={formOpen} onClose={closeForm} labelledBy="category-form-title" locked={saving}>
        {formOpen && (
          <CategoryForm
            key={edited?.id ?? 'new'}
            category={edited}
            departments={departments}
            users={users}
            onBusy={setSaving}
            onCancel={closeForm}
            onSaved={(saved) => {
              replace(saved);
              closeForm();
            }}
          />
        )}
      </Modal>
    </div>
  );
}

interface CategoryFormProps {
  category?: Category;
  departments: Department[];
  users: User[];
  /** Сообщает родителю, что идёт сохранение: окно в это время не закрывается. */
  onBusy?: (busy: boolean) => void;
  onSaved: (c: Category) => void;
  onCancel: () => void;
}

function CategoryForm({ category, departments, users, onBusy, onSaved, onCancel }: CategoryFormProps) {
  const [name, setName] = useState(category?.name ?? '');
  const [departmentId, setDepartmentId] = useState(category ? String(category.department.id) : '');
  const [responsibleId, setResponsibleId] = useState(category?.responsible ? String(category.responsible.id) : '');
  const [deputyId, setDeputyId] = useState(category?.deputy ? String(category.deputy.id) : '');
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
    onBusy?.(true);
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
        };
        const body = changes(before, fields);
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
      onBusy?.(false);
    }
  }

  const personSelect = (value: string, set: (v: string) => void, empty: string, field: string) => (
    <>
      <Select value={value} onChange={(e) => set(e.target.value)} aria-invalid={!!errors[field]}>
        <option value="">{empty}</option>
        {people.map((u) => (
          <option key={u.id} value={u.id}>
            {u.full_name}
            {u.department ? ` — ${u.department.name}` : ''}
            {u.is_absent ? ' (отсутствует)' : ''}
          </option>
        ))}
      </Select>
      {errors[field] && <span className="field__hint error-text">{errors[field]}</span>}
    </>
  );

  return (
    <form className="dialog-form" onSubmit={submit} noValidate>
      <h2 id="category-form-title" className="dialog-form__title">
        {category ? 'Категория' : 'Новая категория'}
      </h2>
      <div className="settings-grid">
        <label className="field">
          <span className="field__label">Название</span>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} aria-invalid={!!errors.name} />
          {errors.name && <span className="field__hint error-text">{errors.name}</span>}
        </label>
        <label className="field">
          <span className="field__label">Подразделение</span>
          <Select value={departmentId} onChange={(e) => setDepartmentId(e.target.value)} aria-invalid={!!errors.department_id}>
            <option value="">Выберите…</option>
            {[...departments].sort(byName).map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </Select>
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
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
      <div className="dialog-form__actions">
        <button type="button" className="btn btn--soft" onClick={onCancel} disabled={busy}>
          Отмена
        </button>
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Сохраняем…' : category ? 'Сохранить' : 'Добавить'}
        </button>
      </div>
    </form>
  );
}
