import { useState, type FormEvent } from 'react';
import { accessRequestBody, accessView, draftFrom, type Draft } from '../access/accessView';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import { fieldErrors } from '../api/fieldErrors';
import { BrandLogo } from '../app/BrandLogo';
import { Select } from '../app/Select';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { useAuth } from './AuthProvider';
import type { Unregistered } from './types';

/**
 * Незнакомый аккаунт Telegram (история 71): вместо «вас нет в списке» — заявка на доступ и её статус.
 * Опознание без сессии — теми же подписанными данными Telegram, что пришли при входе.
 */
export function AccessRequestScreen({ who }: { who: Unregistered }) {
  const { loginAs, logout } = useAuth();
  const status = useAsync(() => unwrap(api.POST('/api/v1/access-requests/mine', { body: who.identity })), [who]);
  const [editing, setEditing] = useState(false);

  const s = status.state;
  const view = s.status === 'ready' ? accessView(s.data) : null;

  return (
    <main className="login">
      <BrandLogo className="login__logo" />
      <div className="login__card">
        <h1 className="login__title">Доступ к системе обращений</h1>
        {s.status === 'loading' && <p className="muted">Проверяем заявку…</p>}
        {s.status === 'error' && (
          <>
            <p className="error-text">{s.message}</p>
            <button type="button" className="btn btn--ghost" onClick={status.reload}>
              Повторить
            </button>
          </>
        )}

        {view?.kind === 'form' && (
          <>
            <p className="muted">
              Вашего аккаунта Telegram пока нет среди сотрудников. Подайте заявку — администратор или собственник
              назначит роль и подразделение.
            </p>
            {view.rejectReason !== null && (
              <div className="notice notice--danger">
                Прошлая заявка отклонена{view.rejectReason ? `: ${view.rejectReason}` : '.'} Можно подать снова.
              </div>
            )}
            <RequestForm who={who} initial={view.draft} onDone={status.reload} />
          </>
        )}

        {view?.kind === 'pending' && !editing && (
          <>
            <div className="notice notice--warn" role="status">
              Заявка отправлена {formatDateTime(view.request.updated_at)} и ждёт решения. Бот пришлёт ответ в Telegram.
            </div>
            <dl className="facts">
              <dt>Имя</dt>
              <dd>{view.request.full_name}</dd>
              <dt>Подразделение</dt>
              <dd>{view.request.department?.name ?? 'Не указано'}</dd>
              {view.request.comment && (
                <>
                  <dt>Комментарий</dt>
                  <dd>{view.request.comment}</dd>
                </>
              )}
            </dl>
            <div className="form__actions">
              <button type="button" className="btn" onClick={status.reload}>
                Проверить статус
              </button>
              <button type="button" className="btn btn--ghost" onClick={() => setEditing(true)}>
                Изменить заявку
              </button>
            </div>
          </>
        )}
        {view?.kind === 'pending' && editing && (
          <RequestForm
            who={who}
            initial={draftFrom(view.request)}
            onDone={() => {
              setEditing(false);
              status.reload();
            }}
          />
        )}

        {view?.kind === 'registered' && <RegisteredBlock who={who} loginAs={loginAs} />}

        {view?.kind === 'disabled' && (
          <div className="notice notice--danger">Доступ отключён, обратитесь к администратору.</div>
        )}

        <button type="button" className="link-btn" onClick={logout}>
          Войти другим аккаунтом
        </button>
      </div>
    </main>
  );
}

function RegisteredBlock({ who, loginAs }: { who: Unregistered; loginAs: (w: Unregistered) => Promise<void> }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  return (
    <>
      <div className="notice notice--success">Доступ открыт. Можно входить.</div>
      <div className="form__actions">
        <button
          type="button"
          className="btn"
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError('');
            loginAs(who).catch((e) => {
              setError(errorMessage(e));
              setBusy(false);
            });
          }}
        >
          {busy ? 'Входим…' : 'Войти'}
        </button>
        {error && <span className="error-text">{error}</span>}
      </div>
    </>
  );
}

function RequestForm({ who, initial, onDone }: { who: Unregistered; initial: Draft | null; onDone: () => void }) {
  const departments = useAsync(() => unwrap(api.GET('/api/v1/access-requests/departments')), []);
  const [draft, setDraft] = useState<Draft>(initial ?? { fullName: who.suggestedName, departmentId: '', comment: '' });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const set = (p: Partial<Draft>) => setDraft((d) => ({ ...d, ...p }));

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!draft.fullName.trim()) {
      setErrors({ full_name: 'Укажите имя и фамилию.' });
      return;
    }
    setBusy(true);
    setError('');
    setErrors({});
    try {
      await unwrap(api.POST('/api/v1/access-requests', { body: accessRequestBody(who.identity, draft, who.username) }));
      onDone();
    } catch (err) {
      setErrors(fieldErrors(err));
      setError(err instanceof ApiError && err.status === 429 ? 'Слишком часто. Попробуйте через час.' : errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="form form--plain" onSubmit={submit} noValidate>
      <label className="field">
        <span className="field__label">Имя и фамилия</span>
        <input
          className="input"
          value={draft.fullName}
          onChange={(e) => set({ fullName: e.target.value })}
          aria-invalid={Boolean(errors.full_name)}
          required
        />
        {errors.full_name && <span className="error-text field__hint">{errors.full_name}</span>}
      </label>
      <label className="field">
        <span className="field__label">Подразделение</span>
        <Select value={draft.departmentId} onChange={(e) => set({ departmentId: e.target.value })}>
          <option value="">Не знаю</option>
          {departments.state.status === 'ready' &&
            departments.state.data.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
        </Select>
      </label>
      <label className="field">
        <span className="field__label">
          Должность или комментарий <span className="muted">— необязательно</span>
        </span>
        <textarea className="input" rows={2} value={draft.comment} onChange={(e) => set({ comment: e.target.value })} />
      </label>
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Отправляем…' : initial ? 'Отправить заявку' : 'Подать заявку'}
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
