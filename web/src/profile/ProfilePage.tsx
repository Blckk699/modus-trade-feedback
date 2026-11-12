import { useState, type FormEvent } from 'react';
import { KeyRound, Mail, Send } from 'lucide-react';
import { errorMessage } from '../api/errors';
import { Avatar } from '../app/Avatar';
import { useDictionaries } from '../app/dictionaries';
import { PageHead } from '../app/PageHead';
import { useToast } from '../app/Toast';
import { useMe } from '../auth';
import { emailAuth } from '../auth/email/emailAuth';
import {
  canUnlinkTelegram,
  changePasswordErrors,
  changePasswordProblem,
  credentialsErrors,
  linkTelegramProblem,
  registerProblem,
  type Account,
  type ChangePasswordForm,
  type CredentialsForm,
  type FieldErrors,
} from '../auth/email/forms';
import { PasswordField } from '../auth/email/PasswordField';
import { TelegramWidget } from '../auth/methods/telegramWidget';
import { config } from '../config';
import { useAsync } from '../lib/useAsync';
import { getWebApp } from '../telegram/webApp';

/**
 * Профиль (истории 75–76): способы входа сотрудника. Почта и пароль — основной вход в вебе,
 * Telegram — вход в один клик и уведомления бота. Отвязать Telegram можно, пока остаётся почта.
 */
export function ProfilePage() {
  const me = useMe();
  const dict = useDictionaries();
  const account = useAsync(() => emailAuth.account(), []);
  const s = account.state;

  return (
    <section className="page profile">
      <PageHead over="Способы входа" title="Профиль" />
      <div className="card profile__who">
        <Avatar name={me.full_name} size="lg" />
        <div>
          <h2 className="profile__name">{me.full_name}</h2>
          <p className="muted">
            {dict.roleLabel(me.role)}
            {me.department ? ` · ${me.department.name}` : ''}
          </p>
        </div>
      </div>

      {s.status === 'loading' && <p className="muted">Загружаем…</p>}
      {s.status === 'error' && (
        <div className="notice">
          <p className="error-text">{s.message}</p>
          <button type="button" className="btn btn--soft" onClick={account.reload}>
            Повторить
          </button>
        </div>
      )}
      {s.status === 'ready' && (
        <div className="profile__grid">
          <EmailCard account={s.data} onChange={account.set} />
          <TelegramCard account={s.data} onChange={account.set} />
        </div>
      )}
    </section>
  );
}

interface CardProps {
  account: Account;
  onChange: (a: Account) => void;
}

function EmailCard({ account, onChange }: CardProps) {
  return (
    <article className="card profile__card">
      <header className="profile__head">
        <span className="profile__icon" aria-hidden="true">
          <Mail size={18} />
        </span>
        <div>
          <h2 className="card__title">Почта и пароль</h2>
          <p className="card__sub">{account.email ?? 'Не заданы: вход только через Telegram'}</p>
        </div>
      </header>
      {account.email ? <ChangePassword email={account.email} /> : <SetCredentials onChange={onChange} />}
    </article>
  );
}

/** Пришедший через Telegram задаёт почту и пароль, чтобы входить с рабочего компьютера. */
function SetCredentials({ onChange }: { onChange: (a: Account) => void }) {
  const toast = useToast();
  const [form, setForm] = useState<CredentialsForm>({ email: '', password: '' });
  const [errors, setErrors] = useState<FieldErrors<keyof CredentialsForm>>({});
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const set = (p: Partial<CredentialsForm>) => {
    setForm((f) => ({ ...f, ...p }));
    setErrors({});
  };

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    const found = credentialsErrors(form);
    setErrors(found);
    if (Object.keys(found).length > 0) return;
    setBusy(true);
    setError('');
    try {
      onChange(await emailAuth.setEmailAndPassword(form.email.trim(), form.password));
      toast('Почта и пароль сохранены: теперь можно входить и по почте');
    } catch (err) {
      const p = registerProblem(err);
      if (p.field === 'email') setErrors({ email: 'Эта почта уже занята другим сотрудником.' });
      else setError(p.message);
      setBusy(false);
    }
  }

  return (
    <form className="form form--plain" onSubmit={submit} noValidate>
      <p className="muted">Задайте почту и пароль, чтобы входить с рабочего компьютера без Telegram.</p>
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
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Сохраняем…' : 'Сохранить'}
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

const PASSWORD_EMPTY: ChangePasswordForm = { current: '', next: '', repeat: '' };

function ChangePassword({ email }: { email: string }) {
  const toast = useToast();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<ChangePasswordForm>(PASSWORD_EMPTY);
  const [errors, setErrors] = useState<FieldErrors<keyof ChangePasswordForm>>({});
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const set = (p: Partial<ChangePasswordForm>) => {
    setForm((f) => ({ ...f, ...p }));
    setErrors({});
  };

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (busy) return;
    const found = changePasswordErrors(form);
    setErrors(found);
    if (Object.keys(found).length > 0) return;
    setBusy(true);
    setError('');
    try {
      await emailAuth.changePassword(form.current, form.next);
      setForm(PASSWORD_EMPTY);
      setOpen(false);
      toast('Пароль изменён');
    } catch (err) {
      const p = changePasswordProblem(err);
      if (p.field) setErrors({ [p.field]: p.message });
      else setError(p.message);
    } finally {
      setBusy(false);
    }
  }

  if (!open) {
    return (
      <div className="form__actions">
        <button type="button" className="btn btn--soft" onClick={() => setOpen(true)}>
          <KeyRound size={16} aria-hidden="true" /> Сменить пароль
        </button>
      </div>
    );
  }

  return (
    <form className="form form--plain" onSubmit={submit} noValidate>
      <input className="sr-only" type="email" autoComplete="username" value={email} readOnly tabIndex={-1} aria-hidden="true" />
      <PasswordField
        label="Текущий пароль"
        value={form.current}
        onChange={(current) => set({ current })}
        autoComplete="current-password"
        error={errors.current}
        autoFocus
      />
      <PasswordField
        label="Новый пароль"
        value={form.next}
        onChange={(next) => set({ next })}
        autoComplete="new-password"
        error={errors.next}
        hint="Не короче 8 символов."
      />
      <PasswordField label="Ещё раз" value={form.repeat} onChange={(repeat) => set({ repeat })} autoComplete="new-password" error={errors.repeat} />
      <div className="form__actions">
        <button type="submit" className="btn" disabled={busy}>
          {busy ? 'Сохраняем…' : 'Сменить пароль'}
        </button>
        <button type="button" className="btn btn--soft" onClick={() => setOpen(false)} disabled={busy}>
          Отмена
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

function TelegramCard({ account, onChange }: CardProps) {
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const inMiniApp = Boolean(getWebApp());

  async function run(action: () => Promise<Account>, done: string, problem: (e: unknown) => string) {
    setBusy(true);
    setError('');
    try {
      onChange(await action());
      toast(done);
    } catch (e) {
      setError(problem(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <article className="card profile__card">
      <header className="profile__head">
        <span className="profile__icon" aria-hidden="true">
          <Send size={18} />
        </span>
        <div>
          <h2 className="card__title">Telegram</h2>
          <p className="card__sub">{account.telegramLinked ? 'Привязан' : 'Не привязан'}</p>
        </div>
      </header>

      {account.telegramLinked ? (
        <>
          <p className="muted">Вход в один клик и уведомления бота работают.</p>
          {canUnlinkTelegram(account) ? (
            <div className="form__actions">
              <button
                type="button"
                className="btn btn--soft"
                disabled={busy}
                onClick={() => run(() => emailAuth.unlinkTelegram(), 'Telegram отвязан: уведомления бота больше не придут', errorMessage)}
              >
                {busy ? 'Отвязываем…' : 'Отвязать'}
              </button>
            </div>
          ) : (
            <p className="muted">Отвязать можно после того, как вы зададите почту и пароль: иначе войти будет нечем.</p>
          )}
        </>
      ) : (
        <>
          <p className="muted">Привяжите Telegram, чтобы входить в один клик и получать уведомления бота.</p>
          {inMiniApp ? (
            <p className="muted">Откройте профиль в браузере: привязка идёт через вход Telegram на сайте.</p>
          ) : config.telegramBotUsername ? (
            busy ? (
              <p className="muted">Привязываем…</p>
            ) : (
              <TelegramWidget
                onUser={(user) => run(() => emailAuth.linkTelegram(user), 'Telegram привязан: вход в один клик и уведомления включены', linkTelegramProblem)}
              />
            )
          ) : (
            <p className="error-text">Привязка не настроена: не указан бот для Telegram Login.</p>
          )}
        </>
      )}
      {error && (
        <p className="error-text" role="alert">
          {error}
        </p>
      )}
    </article>
  );
}
