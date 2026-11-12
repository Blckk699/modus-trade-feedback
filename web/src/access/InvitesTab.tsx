import { RowsSkeleton } from '../app/ListStates';
import { useState, type FormEvent } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { EmptyState } from '../app/EmptyState';
import { Modal } from '../app/Modal';
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
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const close = () => {
    setOpen(false);
    setCreated(null);
  };

  const deps = departments.state.status === 'ready' ? departments.state.data : [];
  const upsert = (inv: Invite) => {
    if (list.state.status !== 'ready') return;
    const rest = list.state.data.filter((x) => x.id !== inv.id);
    list.set([inv, ...rest].sort((a, b) => b.created_at.localeCompare(a.created_at)));
  };

  const s = list.state;
  return (
    <div className="settings-tab">
      <div className="settings-toolbar">
        <p className="muted">По ссылке человек сразу получает доступ с заданной ролью и подразделением, без заявки.</p>
        <button type="button" className="btn" onClick={() => setOpen(true)}>
          Создать приглашение
        </button>
      </div>

      {/* Форма и готовые ссылки — в окне. Ссылки показываются один раз, поэтому окно не закрывается
          случайным кликом мимо, а во время создания не закрывается вовсе. */}
      <Modal open={open} onClose={close} labelledBy="invite-title" locked={busy || created !== null} closeOnBackdrop={false}>
        {open &&
          (created ? (
            <CreatedLinks invite={created} onClose={close} />
          ) : (
            <CreateInvite
              departments={deps}
              onBusy={setBusy}
              onCancel={close}
              onCreated={(c) => {
                setCreated(c);
                upsert(c);
              }}
            />
          ))}
      </Modal>

      {s.status === 'loading' && <RowsSkeleton />}
      {s.status === 'error' && <p className="error-text">{s.message}</p>}
      {s.status === 'ready' && s.data.length === 0 && (
        <EmptyState icon="inbox" title="Приглашений пока нет">
          Создайте первое и отправьте ссылку человеку.
        </EmptyState>
      )}
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

interface CreateInviteProps {
  departments: Schemas['Department'][];
  onCreated: (c: Created) => void;
  onCancel: () => void;
  onBusy: (busy: boolean) => void;
}

function CreateInvite({ departments, onCreated, onCancel, onBusy }: CreateInviteProps) {
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
    onBusy(true);
    setError('');
    try {
      onCreated(await unwrap(api.POST('/api/v1/admin/invites', { body: inviteBody(form) })));
      setForm(INVITE_DEFAULTS);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
      onBusy(false);
    }
  }

  return (
    <form className="user-form" onSubmit={submit} noValidate>
      <div className="user-form__head">
        <h2 id="invite-title" className="user-form__title">
          Новое приглашение
        </h2>
        <p className="muted">По ссылке человек сразу получает доступ с заданной ролью и подразделением.</p>
      </div>
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
            Имя <span className="muted">· необязательно</span>
          </span>
          <input className="input" value={form.fullName} onChange={(e) => set({ fullName: e.target.value })} data-autofocus />
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
          {busy ? 'Создаём…' : 'Создать ссылку'}
        </button>
      </div>
    </form>
  );
}

/** Ссылки показываются один раз: токен хранится на сервере хешем. */
function CreatedLinks({ invite, onClose }: { invite: Created; onClose: () => void }) {
  return (
    <div className="user-form invite-links" role="status">
      <div className="upload-modal__top">
        <span className="upload-modal__done" aria-hidden="true">
          <svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12.5l4.5 4.5L19 7.5" />
          </svg>
        </span>
        <div className="upload-modal__head">
          <h2 id="invite-title" className="upload-modal__title">
            Приглашение создано
          </h2>
          <p className="muted">Скопируйте ссылку сейчас. Позже её посмотреть нельзя.</p>
        </div>
      </div>
      <CopyLink label="Через бота в Telegram" value={invite.bot_link} />
      <CopyLink label="Через браузер" value={invite.web_link} />
      <div className="user-form__actions">
        <button type="button" className="btn" onClick={onClose}>
          Готово
        </button>
      </div>
    </div>
  );
}

function CopyLink({ label, value }: { label: string; value: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className="invite-links__row">
      <span className="field__label">{label}</span>
      <input className="input" value={value} readOnly onFocus={(e) => e.currentTarget.select()} aria-label={label} />
      <button
        type="button"
        className="btn btn--soft"
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
