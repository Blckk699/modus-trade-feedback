import { ResetPassword } from './ResetPassword';
import { Avatar } from '../app/Avatar';
import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import { useDictionaries } from '../app/dictionaries';
import { useAsync } from '../lib/useAsync';
import { byName, changes, fieldErrors, idOrNull, type Department, type Role, type User } from './shared';
import { Modal } from '../app/Modal';
import { Select } from '../app/Select';

const ROLES: Role[] = ['employee', 'head', 'owner', 'admin'];

function loadAll() {
  return Promise.all([
    unwrap(api.GET('/api/v1/users', { params: { query: { include_disabled: true } } })),
    unwrap(api.GET('/api/v1/departments')),
  ]);
}

/** Сотрудники: добавить по Telegram ID, роль, подразделение, отсутствие, отключение доступа (истории 64, 65, 68). */
export function UsersTab() {
  const data = useAsync(loadAll, []);
  const [q, setQ] = useState('');
  const [adding, setAdding] = useState(false);
  const [editing, setEditing] = useState<number | null>(null);
  // Пока форма сохраняется, окно не закрывается: иначе ошибку сервера не увидеть.
  const [saving, setSaving] = useState(false);

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

  const [users, departments] = s.data;
  const replace = (u: User) => data.set([users.some((x) => x.id === u.id) ? users.map((x) => (x.id === u.id ? u : x)) : [...users, u], departments]);
  const needle = q.trim().toLowerCase();
  const shown = users
    .filter((u) => !needle || `${u.full_name} ${u.position ?? ''} ${u.telegram_id ?? ''}`.toLowerCase().includes(needle))
    .sort(byName);

  const editedUser = editing === null ? undefined : users.find((u) => u.id === editing);
  const formOpen = adding || editedUser !== undefined;
  const closeForm = () => {
    setAdding(false);
    setEditing(null);
  };

  return (
    <div className="settings-tab">
      <div className="settings-toolbar">
        <input className="input" type="search" placeholder="Поиск по имени, должности, Telegram ID" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Поиск сотрудника" />
        <button type="button" className="btn" onClick={() => setAdding(true)}>
          Добавить сотрудника
        </button>
      </div>

      <ul className="settings-list">
        {shown.map((u) => (
          <UserRow key={u.id} user={u} onEdit={() => setEditing(u.id)} />
        ))}
        {shown.length === 0 && <li className="muted">Никого не нашли.</li>}
      </ul>

      {/* Добавление и правка сотрудника — в окне поверх списка. key сбрасывает поля при смене сотрудника. */}
      <Modal open={formOpen} onClose={closeForm} labelledBy="user-form-title" locked={saving}>
        {formOpen && (
          <UserForm
            key={editedUser?.id ?? 'new'}
            user={editedUser}
            departments={departments}
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

function UserRow({ user, onEdit }: { user: User; onEdit: () => void }) {
  const dict = useDictionaries();
  return (
    <li className={`settings-row${user.is_disabled ? ' settings-row--off' : ''}`}>
      <Avatar name={user.full_name} />
      <div className="settings-row__main">
        <strong>{user.full_name}</strong>
        <span className="muted">
          {[dict.roleLabel(user.role), user.department?.name, user.position].filter(Boolean).join(' · ')}
        </span>
        <span className="muted settings-row__fine">{user.telegram_id ? `Telegram ID: ${user.telegram_id}` : 'Telegram не привязан'}</span>
      </div>
      <div className="settings-row__badges">
        {user.is_absent && <span className="badge badge--dot badge--status-awaiting_info">Отсутствует</span>}
        {user.is_disabled && <span className="badge badge--dot badge--status-rejected">Доступ отключён</span>}
      </div>
      <button type="button" className="btn btn--ghost" onClick={onEdit}>
        Изменить
      </button>
    </li>
  );
}

interface UserFormProps {
  user?: User;
  departments: Department[];
  /** Сообщает родителю, что идёт сохранение. */
  onBusy?: (busy: boolean) => void;
  onSaved: (user: User) => void;
  onCancel: () => void;
}

function UserForm({ user, departments, onBusy, onSaved, onCancel }: UserFormProps) {
  const dict = useDictionaries();
  const [telegramId, setTelegramId] = useState('');
  const [fullName, setFullName] = useState(user?.full_name ?? '');
  const [position, setPosition] = useState(user?.position ?? '');
  const [role, setRole] = useState<Role>(user?.role ?? 'employee');
  const [departmentId, setDepartmentId] = useState(user?.department ? String(user.department.id) : '');
  const [absent, setAbsent] = useState(user?.is_absent ?? false);
  const [disabled, setDisabled] = useState(user?.is_disabled ?? false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  async function submit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setErrors({});
    const local: Record<string, string> = {};
    if (!user && !/^\d{1,15}$/.test(telegramId.trim())) local.telegram_id = 'Числовой Telegram ID, например 123456789.';
    if (!fullName.trim()) local.full_name = 'Укажите имя и фамилию.';
    if (Object.keys(local).length) return setErrors(local);

    setBusy(true);
    onBusy?.(true);
    try {
      const fields = {
        full_name: fullName.trim(),
        position: position.trim() || null,
        role,
        department_id: idOrNull(departmentId),
      };
      let saved: User;
      if (user) {
        const before = {
          full_name: user.full_name,
          position: user.position,
          role: user.role,
          department_id: user.department?.id ?? null,
          is_absent: user.is_absent,
          is_disabled: user.is_disabled,
        };
        const body = changes(before, { ...fields, is_absent: absent, is_disabled: disabled });
        saved = Object.keys(body).length
          ? await unwrap(api.PATCH('/api/v1/admin/users/{user_id}', { params: { path: { user_id: user.id } }, body }))
          : user;
      } else {
        saved = await unwrap(api.POST('/api/v1/admin/users', { body: { ...fields, telegram_id: Number(telegramId.trim()) } }));
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

  return (
    <form className="user-form" onSubmit={submit} noValidate>
      <div className="user-form__head">
        <h2 id="user-form-title" className="user-form__title">
          {user ? user.full_name : 'Новый сотрудник'}
        </h2>
        {user && <p className="muted">Telegram ID: {user.telegram_id ?? 'не указан'}</p>}
      </div>
      {!user && (
        <label className="field">
          <span className="field__label">Telegram ID</span>
          <input
            className="input"
            inputMode="numeric"
            value={telegramId}
            onChange={(e) => setTelegramId(e.target.value)}
            aria-invalid={!!errors.telegram_id}
            data-autofocus
          />
          <span className="field__hint muted">
            {errors.telegram_id ?? 'Числовой ID: сотрудник может узнать его у @userinfobot. По нему он войдёт в систему.'}
          </span>
        </label>
      )}
      <div className="settings-grid">
        <label className="field">
          <span className="field__label">Имя и фамилия</span>
          <input
            className="input"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            aria-invalid={!!errors.full_name}
            data-autofocus={user ? true : undefined}
          />
          {errors.full_name && <span className="field__hint error-text">{errors.full_name}</span>}
        </label>
        <label className="field">
          <span className="field__label">Должность</span>
          <input className="input" value={position} onChange={(e) => setPosition(e.target.value)} />
        </label>
        <label className="field">
          <span className="field__label">Роль</span>
          <Select value={role} onChange={(e) => setRole(e.target.value as Role)}>
            {ROLES.map((r) => (
              <option key={r} value={r}>
                {dict.roleLabel(r)}
              </option>
            ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Подразделение</span>
          <Select value={departmentId} onChange={(e) => setDepartmentId(e.target.value)} aria-invalid={!!errors.department_id}>
            <option value="">Без подразделения</option>
            {[...departments].sort(byName).map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </Select>
          {errors.department_id && <span className="field__hint error-text">{errors.department_id}</span>}
        </label>
      </div>
      {user && (
        <div className="user-form__toggles">
          <label className="toggle-row">
            <span className="toggle-row__text">
              <span className="toggle-row__title">Отсутствует</span>
              <span className="muted">Новые обращения его категорий получает заместитель</span>
            </span>
            <input className="switch" type="checkbox" role="switch" checked={absent} onChange={(e) => setAbsent(e.target.checked)} />
          </label>
          <label className="toggle-row">
            <span className="toggle-row__text">
              <span className="toggle-row__title">Отключить доступ</span>
              <span className="muted">Вход запрещён, текущие сессии сбрасываются</span>
            </span>
            <input className="switch" type="checkbox" role="switch" checked={disabled} onChange={(e) => setDisabled(e.target.checked)} />
          </label>
        </div>
      )}
      {user && <ResetPassword userId={user.id} name={user.full_name} />}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
      <div className="user-form__actions">
        <button type="button" className="btn btn--soft" onClick={onCancel} disabled={busy}>
          Отмена
        </button>
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Сохраняем…' : user ? 'Сохранить' : 'Добавить'}
        </button>
      </div>
    </form>
  );
}
