import { useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import type { Session } from '../api/types';
import { AuthFrame } from './AuthFrame';
import { useAuth } from './AuthProvider';
import { emailAuth } from './email/emailAuth';
import {
  lockWait,
  loginFormErrors,
  loginProblem,
  newPasswordErrors,
  type FieldErrors,
  type LoginForm,
  type LoginProblem,
  type NewPasswordForm,
} from './email/forms';
import { PasswordField } from './email/PasswordField';
import { authMethods } from './methods';

/**
 * Вход (SPEC, «Вход и уведомления»): почта и пароль — основной способ, ниже Telegram в один клик.
 * Ответ входа различает неверные данные, заявку на рассмотрении, отключённый доступ, блокировку
 * и временный пароль — после него экран просит задать новый.
 */
export function LoginScreen() {
  const { state, acceptSession, failLogin, needAccess } = useAuth();
  const notice = state.status === 'anonymous' ? state.notice : undefined;
  const methods = authMethods.filter((m) => m.LoginButton && m.isAvailable());
  /** Вошли с временным паролем: почта и он сам нужны, чтобы задать новый. */
  const [temporary, setTemporary] = useState<LoginForm | null>(null);

  if (temporary) {
    return <NewPasswordStep credentials={temporary} onSession={acceptSession} onBack={() => setTemporary(null)} />;
  }

  return (
    <AuthFrame title="Вход" lead="Обращения и предложения сотрудников Модус Трейд.">
      {notice && (
        <div className="notice notice--danger" role="alert">
          {notice}
        </div>
      )}
      <EmailLoginForm onSession={acceptSession} onTemporary={setTemporary} />
      <p className="auth__hint">Забыли пароль? Его сбросит администратор.</p>

      {methods.length > 0 && (
        <>
          <p className="auth__or" role="separator">
            или
          </p>
          <div className="auth__sso">
            {methods.map((m) => {
              const Button = m.LoginButton!;
              return <Button key={m.id} onSession={acceptSession} onError={failLogin} onUnregistered={needAccess} />;
            })}
          </div>
        </>
      )}

      <p className="auth__switch">
        Ещё нет доступа? <Link to="/register">Зарегистрироваться</Link>
      </p>
    </AuthFrame>
  );
}

function EmailLoginForm({ onSession, onTemporary }: { onSession: (s: Session) => void; onTemporary: (f: LoginForm) => void }) {
  const [form, setForm] = useState<LoginForm>({ email: '', password: '' });
  const [errors, setErrors] = useState<FieldErrors<keyof LoginForm>>({});
  const [problem, setProblem] = useState<LoginProblem | null>(null);
  const [busy, setBusy] = useState(false);
  const set = (p: Partial<LoginForm>) => {
    setForm((f) => ({ ...f, ...p }));
    setErrors({});
    if (problem?.kind === 'invalid') setProblem(null);
  };

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    const found = loginFormErrors(form);
    setErrors(found);
    if (Object.keys(found).length > 0) return;
    setBusy(true);
    setProblem(null);
    try {
      onSession(await emailAuth.login(form.email, form.password));
    } catch (err) {
      const p = loginProblem(err);
      if (p.kind === 'new_password') onTemporary(form);
      else setProblem(p);
      setBusy(false);
    }
  }

  return (
    <form className="form form--plain" onSubmit={submit} noValidate>
      {problem && <ProblemNotice problem={problem} />}
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
          aria-invalid={Boolean(errors.email) || problem?.kind === 'invalid'}
          required
        />
        {errors.email && <span className="error-text field__hint">{errors.email}</span>}
      </label>
      <PasswordField
        label="Пароль"
        value={form.password}
        onChange={(password) => set({ password })}
        autoComplete="current-password"
        error={errors.password ?? (problem?.kind === 'invalid' ? 'Неверная почта или пароль.' : undefined)}
      />
      <button type="submit" className="btn auth__submit" disabled={busy}>
        {busy ? 'Входим…' : 'Войти'}
      </button>
    </form>
  );
}

/** Отказы входа, которые не лечатся правкой полей: объясняем, что происходит и что делать. */
function ProblemNotice({ problem }: { problem: LoginProblem }) {
  if (problem.kind === 'invalid' || problem.kind === 'new_password') return null;
  if (problem.kind === 'pending') {
    return (
      <div className="notice notice--warn" role="alert">
        <p className="notice__title">Заявка на рассмотрении</p>
        <p>Войти получится после одобрения. Администратор уже получил заявку.</p>
      </div>
    );
  }
  if (problem.kind === 'rejected') {
    return (
      <div className="notice notice--danger" role="alert">
        <p className="notice__title">Заявка отклонена</p>
        <p>{problem.reason ? `Причина: ${problem.reason}` : 'Причину можно узнать у администратора.'}</p>
      </div>
    );
  }
  if (problem.kind === 'disabled') {
    return (
      <div className="notice notice--danger" role="alert">
        <p className="notice__title">Доступ отключён</p>
        <p>Обратитесь к администратору.</p>
      </div>
    );
  }
  if (problem.kind === 'locked') return <LockNotice seconds={problem.retryAfterSec} />;
  return (
    <div className="notice notice--danger" role="alert">
      {problem.message}
    </div>
  );
}

/** Блокировка после пяти неудач: отсчитываем оставшееся время, чтобы не гадать, когда пробовать снова. */
function LockNotice({ seconds }: { seconds: number | null }) {
  const [left, setLeft] = useState(seconds);
  useEffect(() => {
    setLeft(seconds);
    if (seconds === null) return;
    const until = Date.now() + seconds * 1000;
    const timer = window.setInterval(() => setLeft(Math.max(0, Math.ceil((until - Date.now()) / 1000))), 1000);
    return () => window.clearInterval(timer);
  }, [seconds]);

  return (
    <div className="notice notice--warn" role="alert">
      <p className="notice__title">Слишком много попыток</p>
      <p>
        {left === 0
          ? 'Можно пробовать снова. Если пароль не вспомнился, его сбросит администратор.'
          : `Вход по этой почте откроется ${lockWait(left)}. Если пароль не вспомнился, его сбросит администратор.`}
      </p>
    </div>
  );
}

/** Вход с временным паролем от администратора: задать свой и войти. */
function NewPasswordStep({ credentials, onSession, onBack }: { credentials: LoginForm; onSession: (s: Session) => void; onBack: () => void }) {
  const [form, setForm] = useState<NewPasswordForm>({ next: '', repeat: '' });
  const [errors, setErrors] = useState<FieldErrors<keyof NewPasswordForm>>({});
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const set = (p: Partial<NewPasswordForm>) => {
    setForm((f) => ({ ...f, ...p }));
    setErrors({});
  };

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    const found = newPasswordErrors(form, credentials.password);
    setErrors(found);
    if (Object.keys(found).length > 0) return;
    setBusy(true);
    setError('');
    try {
      onSession(await emailAuth.replaceTemporaryPassword(credentials.email, credentials.password, form.next));
    } catch (err) {
      const p = loginProblem(err);
      setError(p.kind === 'other' ? p.message : 'Временный пароль больше не действует. Вернитесь ко входу и попробуйте снова.');
      setBusy(false);
    }
  }

  return (
    <AuthFrame title="Новый пароль" lead={`Вы вошли с временным паролем. Задайте свой для ${credentials.email.trim()}.`}>
      <form className="form form--plain" onSubmit={submit} noValidate>
        {/* Менеджеру паролей нужна почта рядом с новым паролем, иначе он сохранит его без логина. */}
        <input className="sr-only" type="email" autoComplete="username" value={credentials.email.trim()} readOnly tabIndex={-1} aria-hidden="true" />
        <PasswordField
          label="Новый пароль"
          value={form.next}
          onChange={(next) => set({ next })}
          autoComplete="new-password"
          error={errors.next}
          hint="Не короче 8 символов."
          autoFocus
        />
        <PasswordField
          label="Ещё раз"
          value={form.repeat}
          onChange={(repeat) => set({ repeat })}
          autoComplete="new-password"
          error={errors.repeat}
        />
        {error && (
          <p className="error-text" role="alert">
            {error}
          </p>
        )}
        <button type="submit" className="btn auth__submit" disabled={busy}>
          {busy ? 'Сохраняем…' : 'Сохранить и войти'}
        </button>
      </form>
      <button type="button" className="link-btn" onClick={onBack}>
        Вернуться ко входу
      </button>
    </AuthFrame>
  );
}
