import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import type { Session } from '../api/types';
import { Select } from '../app/Select';
import { useAsync } from '../lib/useAsync';
import { AuthFrame } from './AuthFrame';
import { emailAuth } from './email/emailAuth';
import { REGISTER_EMPTY, registerFormErrors, registerProblem, type FieldErrors, type RegisterForm } from './email/forms';
import { PasswordField } from './email/PasswordField';

type Errors = FieldErrors<'fullName' | 'email' | 'password'>;

/**
 * Регистрация по рабочей почте (история 75). Без приглашения она создаёт заявку на доступ:
 * войти можно после одобрения, поэтому вместо входа показываем «Заявка на рассмотрении».
 */
export function RegisterScreen() {
  const [sentTo, setSentTo] = useState<string | null>(null);

  if (sentTo) {
    return (
      <AuthFrame title="Заявка на рассмотрении">
        <div className="notice notice--success" role="status">
          <p className="notice__title">Заявка отправлена</p>
          <p>Администратор получил уведомление. После одобрения войдите с почтой {sentTo} и паролем, который вы задали.</p>
        </div>
        <Link to="/" className="btn auth__submit">
          Ко входу
        </Link>
      </AuthFrame>
    );
  }

  return (
    <AuthFrame title="Регистрация" lead="Заявку рассмотрит администратор. Войти можно будет после одобрения.">
      <RegisterFields onPending={setSentTo} />
      <p className="auth__switch">
        Уже есть доступ? <Link to="/">Войти</Link>
      </p>
    </AuthFrame>
  );
}

interface FieldsProps {
  /** Регистрация по приглашению: подразделение задано приглашением, заявки нет — сразу сессия. */
  inviteToken?: string;
  suggestedName?: string;
  onPending?: (email: string) => void;
  onSession?: (session: Session) => void;
  submitLabel?: string;
}

/** Поля регистрации. Экран регистрации и страница приглашения используют одну форму. */
export function RegisterFields({ inviteToken, suggestedName, onPending, onSession, submitLabel }: FieldsProps) {
  const departments = useAsync(
    () => (inviteToken ? Promise.resolve([]) : unwrap(api.GET('/api/v1/access-requests/departments'))),
    [inviteToken],
  );
  const [form, setForm] = useState<RegisterForm>({ ...REGISTER_EMPTY, fullName: suggestedName ?? '' });
  const [errors, setErrors] = useState<Errors>({});
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const set = (p: Partial<RegisterForm>) => {
    setForm((f) => ({ ...f, ...p }));
    setErrors({});
  };

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    const found = registerFormErrors(form);
    setErrors(found);
    if (Object.keys(found).length > 0) return;
    setBusy(true);
    setError('');
    try {
      const res = await emailAuth.register({
        fullName: form.fullName.trim(),
        email: form.email.trim(),
        password: form.password,
        departmentId: form.departmentId ? Number(form.departmentId) : null,
        comment: form.comment.trim(),
        inviteToken,
      });
      if (res.kind === 'session') onSession?.(res.session);
      else onPending?.(form.email.trim());
    } catch (err) {
      const p = registerProblem(err);
      if (p.field) setErrors({ [p.field]: p.message });
      else setError(p.message);
      setBusy(false);
    }
  }

  return (
    <form className="form form--plain" onSubmit={submit} noValidate>
      <label className="field">
        <span className="field__label">Имя и фамилия</span>
        <input
          className="input"
          autoComplete="name"
          value={form.fullName}
          onChange={(e) => set({ fullName: e.target.value })}
          aria-invalid={Boolean(errors.fullName)}
          required
        />
        {errors.fullName && <span className="error-text field__hint">{errors.fullName}</span>}
      </label>
      <label className="field">
        <span className="field__label">Рабочая почта</span>
        <input
          className="input"
          type="email"
          inputMode="email"
          autoComplete="username"
          autoCapitalize="none"
          spellCheck={false}
          value={form.email}
          onChange={(e) => set({ email: e.target.value })}
          aria-invalid={Boolean(errors.email)}
          required
        />
        {errors.email && <span className="error-text field__hint">{errors.email}</span>}
      </label>
      <PasswordField
        label="Пароль"
        value={form.password}
        onChange={(password) => set({ password })}
        autoComplete="new-password"
        error={errors.password}
        hint="Не короче 8 символов."
      />
      {!inviteToken && (
        <>
          <label className="field">
            <span className="field__label">Подразделение</span>
            <Select value={form.departmentId} onChange={(e) => set({ departmentId: e.target.value })}>
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
              Должность или комментарий <span className="muted">· необязательно</span>
            </span>
            <textarea className="input" rows={2} value={form.comment} onChange={(e) => set({ comment: e.target.value })} />
          </label>
        </>
      )}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
      <button type="submit" className="btn auth__submit" disabled={busy}>
        {busy ? 'Отправляем…' : (submitLabel ?? 'Отправить заявку')}
      </button>
    </form>
  );
}
