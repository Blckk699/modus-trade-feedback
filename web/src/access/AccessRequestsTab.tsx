import { useState } from 'react';
import { api, unwrap } from '../api/client';
import { errorMessage } from '../api/errors';
import type { Schemas } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { EmptyState } from '../app/EmptyState';
import { Select } from '../app/Select';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { approveBody, approveDefaults, ASSIGNABLE_ROLES, type ApproveForm } from './accessForms';

type Req = Schemas['AccessRequest'];
type Status = Schemas['AccessRequestStatus'];

const STATUS_LABEL: Record<Status, string> = { pending: 'На рассмотрении', approved: 'Одобрены', rejected: 'Отклонены' };

/** Заявки на доступ: администратор и собственник назначают роль и подразделение, одобряют или отклоняют (история 72). */
export function AccessRequestsTab() {
  const [status, setStatus] = useState<Status>('pending');
  const list = useAsync(
    () => unwrap(api.GET('/api/v1/admin/access-requests', { params: { query: { status, page_size: 50 } } })),
    [status],
  );
  const departments = useAsync(() => unwrap(api.GET('/api/v1/departments')), []);
  const deps = departments.state.status === 'ready' ? departments.state.data : [];

  const replace = (r: Req) => {
    if (list.state.status !== 'ready') return;
    const page = list.state.data;
    // Решённая заявка уходит из вкладки «На рассмотрении», в остальных обновляется на месте.
    const items = status === 'pending' ? page.items.filter((x) => x.id !== r.id) : page.items.map((x) => (x.id === r.id ? r : x));
    list.set({ ...page, items, total: status === 'pending' ? page.total - 1 : page.total });
  };

  const s = list.state;
  return (
    <div className="settings-tab">
      <div className="segmented" role="tablist" aria-label="Статус заявок">
        {(Object.keys(STATUS_LABEL) as Status[]).map((st) => (
          <label key={st} className="segmented__item">
            <input type="radio" name="request-status" checked={status === st} onChange={() => setStatus(st)} />
            <span>{STATUS_LABEL[st]}</span>
          </label>
        ))}
      </div>
      {s.status === 'loading' && <p className="muted">Загружаем…</p>}
      {s.status === 'error' && (
        <div className="notice">
          <p className="error-text">{s.message}</p>
          <button type="button" className="btn btn--ghost" onClick={list.reload}>
            Повторить
          </button>
        </div>
      )}
      {s.status === 'ready' && s.data.items.length === 0 && (
        <EmptyState icon="inbox" title={status === 'pending' ? 'Новых заявок нет' : 'Заявок нет'}>
          {status === 'pending' ? 'Бот сообщит, когда кто-то подаст заявку на доступ.' : undefined}
        </EmptyState>
      )}
      {s.status === 'ready' && s.data.items.length > 0 && (
        <ul className="settings-list">
          {s.data.items.map((r) => (
            <RequestRow key={r.id} request={r} departments={deps} onDecided={replace} />
          ))}
        </ul>
      )}
    </div>
  );
}

function RequestRow({
  request: r,
  departments,
  onDecided,
}: {
  request: Req;
  departments: Schemas['Department'][];
  onDecided: (r: Req) => void;
}) {
  const dict = useDictionaries();
  const [form, setForm] = useState<ApproveForm>(() => approveDefaults(r));
  const [rejecting, setRejecting] = useState(false);
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const path = { params: { path: { request_id: r.id } } };

  async function run(call: () => Promise<Req>) {
    setBusy(true);
    setError('');
    try {
      onDecided(await call());
    } catch (e) {
      setError(errorMessage(e));
      setBusy(false);
    }
  }

  return (
    <li className="settings-row">
      <div className="settings-row__main">
        <strong>{r.full_name}</strong>
        <span className="muted">
          {r.email ? `${r.email} · ` : ''}
          {r.telegram_username ? `@${r.telegram_username} · ` : ''}
          {r.department?.name ?? 'подразделение не указано'} · {formatDateTime(r.updated_at)}
        </span>
        {r.comment && <span>{r.comment}</span>}
        {r.status === 'approved' && (
          <span className="muted">
            Одобрена: {r.assigned_role ? dict.roleLabel(r.assigned_role) : '—'}
            {r.assigned_department ? `, ${r.assigned_department.name}` : ''} · {r.decided_by?.full_name}{' '}
            {formatDateTime(r.decided_at)}
          </span>
        )}
        {r.status === 'rejected' && (
          <span className="muted">
            Отклонена{r.reject_reason ? `: ${r.reject_reason}` : ''} · {r.decided_by?.full_name} {formatDateTime(r.decided_at)}
          </span>
        )}
      </div>

      {r.status === 'pending' && (
        <div className="settings-form">
          <div className="settings-grid">
            <label className="field">
              <span className="field__label">Роль</span>
              <Select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value as ApproveForm['role'] })}>
                {ASSIGNABLE_ROLES.map((role) => (
                  <option key={role} value={role}>
                    {dict.roleLabel(role)}
                  </option>
                ))}
              </Select>
            </label>
            <label className="field">
              <span className="field__label">Подразделение</span>
              <Select value={form.departmentId} onChange={(e) => setForm({ ...form, departmentId: e.target.value })}>
                <option value="">Без подразделения</option>
                {departments.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
              </Select>
            </label>
          </div>
          {rejecting && (
            <label className="field">
              <span className="field__label">
                Причина отказа <span className="muted">· необязательно, придёт заявителю в Telegram</span>
              </span>
              <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} />
            </label>
          )}
          <div className="form__actions">
            {!rejecting ? (
              <>
                <button
                  type="button"
                  className="btn"
                  disabled={busy}
                  onClick={() =>
                    run(() =>
                      unwrap(api.POST('/api/v1/admin/access-requests/{request_id}/approve', { ...path, body: approveBody(form) })),
                    )
                  }
                >
                  Одобрить
                </button>
                <button type="button" className="btn btn--ghost btn--danger" disabled={busy} onClick={() => setRejecting(true)}>
                  Отклонить
                </button>
              </>
            ) : (
              <>
                <button
                  type="button"
                  className="btn btn--danger"
                  disabled={busy}
                  onClick={() =>
                    run(() =>
                      unwrap(
                        api.POST('/api/v1/admin/access-requests/{request_id}/reject', {
                          ...path,
                          body: { reason: reason.trim() || null },
                        }),
                      ),
                    )
                  }
                >
                  Отклонить заявку
                </button>
                <button type="button" className="btn btn--ghost" disabled={busy} onClick={() => setRejecting(false)}>
                  Отмена
                </button>
              </>
            )}
            {error && (
              <span className="error-text" role="alert">
                {error}
              </span>
            )}
          </div>
        </div>
      )}
    </li>
  );
}
