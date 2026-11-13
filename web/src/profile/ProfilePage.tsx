// Строка с выключателем (.toggle-row) описана в стилях настроек.
import '../settings/settings.css';
import { useEffect, useState, type FormEvent } from 'react';
import { useLocation } from 'react-router-dom';
import { KeyRound, Mail, Send, Volume2, VolumeX } from 'lucide-react';
import { playNotify, setSoundEnabled, soundEnabled } from '../live/sound';
import { Avatar } from '../app/Avatar';
import { useDictionaries } from '../app/dictionaries';
import { PageHead } from '../app/PageHead';
import { useToast } from '../app/Toast';
import type { Me } from '../api/types';
import { useAuth, useMe } from '../auth';
import { emailAuth } from '../auth/email/emailAuth';
import {
  accountOf,
  canUnlinkTelegram,
  changePasswordErrors,
  changePasswordProblem,
  credentialsErrors,
  linkTelegramProblem,
  registerProblem,
  unlinkTelegramProblem,
  type Account,
  type ChangePasswordForm,
  type CredentialsForm,
  type FieldErrors,
} from '../auth/email/forms';
import { PasswordField } from '../auth/email/PasswordField';
import { TelegramWidget, telegramLoginConfigured } from '../auth/methods/telegramWidget';
import { getWebApp } from '../telegram/webApp';

/**
 * Профиль (истории 75–76): способы входа сотрудника. Почта и пароль — основной вход в вебе,
 * Telegram — вход в один клик и уведомления бота. Отвязать Telegram можно, пока остаётся почта.
 */
export function ProfilePage() {
  // Переход из колокольчика (/profile#notifications): показываем блок уведомлений, а не верх страницы.
  // Зависим от hash, а не от монтирования: ссылка из колокольчика работает и когда профиль уже открыт.
  const { hash, key } = useLocation();
  useEffect(() => {
    if (hash === '#notifications') document.getElementById('notifications')?.scrollIntoView({ block: 'start' });
  }, [hash, key]);
  const me = useMe();
  const dict = useDictionaries();
  const { setMe } = useAuth();
  const account = accountOf(me);

  return (
    <section className="page profile">
      <PageHead over="Вход и уведомления" title="Профиль" />
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

      <div className="profile__grid">
        <EmailCard account={account} onChange={setMe} />
        <TelegramCard account={account} onChange={setMe} />
        <SoundCard />
      </div>
    </section>
  );
}

interface CardProps {
  account: Account;
  /** Сервер вернул свежего Me — обновляем его во всём приложении. */
  onChange: (me: Me) => void;
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
          <p className="card__sub">
            {account.email ? (account.hasPassword ? account.email : `${account.email} · пароль не задан`) : account.telegramLinked ? 'Не заданы: вход только через Telegram' : 'Не заданы'}
          </p>
        </div>
      </header>
      {account.hasPassword && account.email ? (
        <ChangePassword email={account.email} onChange={onChange} />
      ) : (
        <SetCredentials initialEmail={account.email ?? ''} onChange={onChange} />
      )}
    </article>
  );
}

/** Пришедший через Telegram задаёт почту и пароль, чтобы входить с рабочего компьютера. */
function SetCredentials({ initialEmail, onChange }: { initialEmail: string; onChange: (me: Me) => void }) {
  const toast = useToast();
  const [form, setForm] = useState<CredentialsForm>({ email: initialEmail, password: '' });
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
      else if (p.field === 'password') setErrors({ password: p.message });
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

function ChangePassword({ email, onChange }: { email: string; onChange: (me: Me) => void }) {
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
      onChange(await emailAuth.changePassword(form.current, form.next));
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

  async function run(action: () => Promise<Me>, done: string, problem: (e: unknown) => string) {
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
    <article id="notifications" className="card profile__card profile__card--anchor">
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
          <p className="muted">Ответы по обращениям, вопросы и напоминания о сроках приходят в Telegram. Вход — в один клик.</p>
          {canUnlinkTelegram(account) ? (
            <div className="form__actions">
              <button
                type="button"
                className="btn btn--soft"
                disabled={busy}
                onClick={() => run(() => emailAuth.unlinkTelegram(), 'Telegram отвязан: уведомления бота больше не придут', unlinkTelegramProblem)}
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
          <p className="muted">
            Привяжите Telegram: туда будут приходить ответы по вашим обращениям, уточняющие вопросы и напоминания о сроках, а
            входить можно будет в один клик. Сейчас уведомления видны только на сайте, под колокольчиком.
          </p>
          {inMiniApp ? (
            <p className="muted">Откройте профиль в браузере: привязка идёт через вход Telegram на сайте.</p>
          ) : telegramLoginConfigured() ? (
            busy ? (
              <p className="muted">Привязываем…</p>
            ) : (
              <TelegramWidget
                label="Привязать Telegram"
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

/** Звук уведомлений: короткий сигнал на новое сообщение и уведомление. Настройка хранится в браузере. */
function SoundCard() {
  const [on, setOn] = useState(soundEnabled);
  return (
    <article className="card profile__card">
      <header className="profile__head">
        <span className="profile__icon" aria-hidden="true">
          {on ? <Volume2 size={18} /> : <VolumeX size={18} />}
        </span>
        <div>
          <h2 className="card__title">Звук</h2>
          <p className="card__sub">{on ? 'Включён' : 'Выключен'}</p>
        </div>
      </header>
      <label className="toggle-row">
        <span className="toggle-row__text">
          <span className="toggle-row__title">Сигнал о новом</span>
          <span className="muted">Короткий звук, когда приходит сообщение или уведомление. На свои действия не звучит.</span>
        </span>
        <input
          className="switch"
          type="checkbox"
          role="switch"
          checked={on}
          onChange={(e) => {
            setSoundEnabled(e.target.checked);
            setOn(e.target.checked);
            if (e.target.checked) playNotify(true);
          }}
        />
      </label>
    </article>
  );
}
