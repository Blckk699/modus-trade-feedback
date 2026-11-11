import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { Select } from '../app/Select';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import {
  ASSIGNABLE_ROLES,
  INVITE_DEFAULTS,
  INVITE_STATE_LABEL,
  inviteBody,
  inviteFormError,
  type InviteForm,
} from './accessForms';

type Invite = Schemas['Invite'];
type Created = Schemas['InviteCreated'];

/** Ссылки-приглашения: создать с ролью и подразделением, увидеть ссылку один раз, отозвать (истории 73, 74). */
export function InvitesTab() {
  const list = useAsync(() => unwrap(api.GET('/api/v1/admin/invites', { params: { query: { include_inactive: true } } })), []);
  const departments = useAsync(() => unwrap(api.GET('/api/v1/departments')), []);
  const [created, setCreated] = useState<Created | null>(null);

  const deps = departments.state.status === 'ready' ? departments.state.data : [];
  const upsert = (inv: Invite) => {
    if (list.state.status !== 'ready') return;
    const rest = list.state.data.filter((x) => x.id !== inv.id);
    list.set([inv, ...rest].sort((a, b) => b.created_at.localeCompare(a.created_at)));
  };

  const s = list.state;
  return (
    <div className="settings-tab">
      <CreateInvite
        departments={deps}
        onCreated={(c) => {
          setCreated(c);
          upsert(c);
        }}
      />
      {created && <CreatedLinks invite={created} onClose={() => setCreated(null)} />}

      <h2 className="block__title">Приглашения</h2>
      {s.status === 'loading' && <p className="muted">Загружаем…</p>}
      {s.status === 'error' && <p className="error-text">{s.message}</p>}
      {s.status === 'ready' && s.data.length === 0 && <p className="muted">Приглашений пока нет.</p>}
      {s.status === 'ready' && s.data.length > 0 && (
        <ul className="settings-list">
          {s.data.map((inv) => (
            <InviteRow key={inv.id} invite={inv} onChanged={upsert} />
          ))}
        </ul>
      )}
    </div>
  );
}

function CreateInvite({ departments, onCreated }: { departments: Schemas['Department'][]; onCreated: (c: Created) => void }) {
  const dict = useDictionaries();
  const [form, setForm] = useState<InviteForm>(INVITE_DEFAULTS);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const set = (p: Partial<InviteForm>) => setForm((f) => ({ ...f, ...p }));

  async function submit(e: FormEvent) {
    e.preventDefault();
    const invalid = inviteFormError(form);
    if (invalid) return setError(invalid);
    setBusy(true);
    setError('');
    try {
      onCreated(await unwrap(api.POST('/api/v1/admin/invites', { body: inviteBody(form) })));
      setForm(INVITE_DEFAULTS);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="block settings-form" onSubmit={submit} noValidate>
      <h2 className="block__title">Новое приглашение</h2>
      <p className="muted field__hint">
        По ссылке человек сразу получает доступ с заданной ролью и подразделением, без заявки.
      </p>
      <div className="settings-grid">
        <label className="field">
          <span className="field__label">Роль</span>
          <Select value={form.role} onChange={(e) => set({ role: e.target.value as InviteForm['role'] })}>
            {ASSIGNABLE_ROLES.map((r) => (
              <option key={r} value={r}>
                {dict.roleLabel(r)}
              </option>
            ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">Подразделение</span>
          <Select value={form.departmentId} onChange={(e) => set({ departmentId: e.target.value })}>
            <option value="">Без подразделения</option>
            {departments.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </Select>
        </label>
        <label className="field">
          <span className="field__label">
            Имя <span className="muted">— необязательно</span>
          </span>
          <input className="input" value={form.fullName} onChange={(e) => set({ fullName: e.target.value })} />
        </label>
        <label className="field">
          <span className="field__label">Действует, дней</span>
          <input className="input" type="number" min={1} max={30} value={form.days} onChange={(e) => set({ days: e.target.value })} />
        </label>
        <label className="field">
          <span className="field__label">Использований</span>
          <input className="input" type="number" min={1} max={100} value={form.uses} onChange={(e) => set({ uses: e.target.value })} />
        </label>
      </div>
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Создаём…' : 'Создать приглашение'}
        </button>
        {error && (
          <span className="error-text" role="alert">
            {error}
          </span>
        )}
      </div>
    </form>
  );
}

/** Ссылки показываются один раз: токен хранится на сервере хешем. */
function CreatedLinks({ invite, onClose }: { invite: Created; onClose: () => void }) {
  return (
    <div className="notice notice--success invite-links" role="status">
      <strong>Приглашение создано. Скопируйте ссылку сейчас — потом её не показать.</strong>
      <CopyLink label="Через бота в Telegram" value={invite.bot_link} />
      <CopyLink label="Через браузер" value={invite.web_link} />
      <button type="button" className="link-btn" onClick={onClose}>
        Я скопировал, скрыть
      </button>
    </div>
  );
}

function CopyLink({ label, value }: { label: string; value: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className="invite-links__row">
      <span className="muted">{label}</span>
      <input className="input" value={value} readOnly onFocus={(e) => e.currentTarget.select()} aria-label={label} />
      <button
        type="button"
        className="btn btn--ghost"
        onClick={() => {
          navigator.clipboard
            ?.writeText(value)
            .then(() => {
              setCopied(true);
              setTimeout(() => setCopied(false), 2000);
            })
            .catch(() => {});
        }}
      >
        {copied ? 'Скопировано' : 'Копировать'}
      </button>
    </div>
  );
}

function InviteRow({ invite: inv, onChanged }: { invite: Invite; onChanged: (i: Invite) => void }) {
  const dict = useDictionaries();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const active = inv.state === 'active';

  async function revoke() {
    setBusy(true);
    setError('');
    try {
      onChanged(
        await unwrap(api.POST('/api/v1/admin/invites/{invite_id}/revoke', { params: { path: { invite_id: inv.id } } })),
      );
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <li className={`settings-row${active ? '' : ' settings-row--off'}`}>
      <div className="settings-row__main">
        <strong>
          {dict.roleLabel(inv.role)}
          {inv.department ? ` · ${inv.department.name}` : ''}
          {inv.full_name ? ` · ${inv.full_name}` : ''}
        </strong>
        <span className="muted">
          Создал {inv.created_by.full_name} {formatDateTime(inv.created_at)} · до {formatDateTime(inv.expires_at)} · использовано{' '}
          {inv.used_count} из {inv.max_uses}
        </span>
      </div>
      <div className="settings-row__badges">
        <span className={`badge${active ? ' badge--status-implemented' : ''}`}>{INVITE_STATE_LABEL[inv.state]}</span>
        {active && (
          <button type="button" className="btn btn--ghost btn--danger" disabled={busy} onClick={revoke}>
            Отозвать
          </button>
        )}
        {error && <span className="error-text">{error}</span>}
      </div>
    </li>
  );
}
