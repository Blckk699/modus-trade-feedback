import { ApiError, errorMessage } from '../../api/errors';
import { fieldErrors } from '../../api/fieldErrors';
import type { ErrorCode, Me } from '../../api/types';

/**
 * Коды ошибок входа по почте из контракта (B-20). Собраны в одном месте: экраны ветвятся
 * по смыслу (`LoginProblem`), а не по строкам.
 */
export const CODES = {
  invalidCredentials: 'invalid_credentials',
  pending: 'access_request_pending',
  rejected: 'access_request_rejected',
  disabled: 'user_disabled',
  locked: 'too_many_requests',
  passwordChangeRequired: 'password_change_required',
  emailTaken: 'email_taken',
  telegramTaken: 'telegram_taken',
  lastLoginMethod: 'last_login_method',
  inviteInvalid: 'invite_invalid',
  conflict: 'conflict',
} as const satisfies Record<string, ErrorCode>;

/**
 * Сервер ещё не знает вход по почте (старая версия API): честно говорим об этом, а не «не найдено».
 * Сервер отвечает на незнакомый маршрут тем же `404 not_found`, что и на контрактное «не найдено»,
 * поэтому проверка стоит только там, где контракт 404 не возвращает: вход, регистрация, /me/credentials, /me/telegram.
 */
const NOT_DEPLOYED = 'Вход по почте на этом сервере ещё не включён. Войдите через Telegram или попробуйте позже.';
const notDeployed = (e: unknown) => e instanceof ApiError && (e.status === 404 || e.status === 405);

export const MIN_PASSWORD = 8;
/** Блокировка после пяти неудачных попыток (SPEC, «Пароль»). */
export const LOCK_MINUTES = 5;

/** Что случилось при входе — в терминах экрана. */
export type LoginProblem =
  | { kind: 'invalid' }
  | { kind: 'pending' }
  | { kind: 'rejected'; reason: string | null }
  | { kind: 'disabled' }
  | { kind: 'locked'; retryAfterSec: number | null }
  | { kind: 'new_password' }
  | { kind: 'other'; message: string };

const codeOf = (e: unknown): string | null => (e instanceof ApiError ? e.code : null);

export function loginProblem(e: unknown): LoginProblem {
  switch (codeOf(e)) {
    case CODES.invalidCredentials:
      return { kind: 'invalid' };
    case CODES.pending:
      return { kind: 'pending' };
    case CODES.rejected: {
      const reason = e instanceof ApiError ? e.details?.reason : null;
      return { kind: 'rejected', reason: typeof reason === 'string' && reason.trim() ? reason.trim() : null };
    }
    case CODES.disabled:
      return { kind: 'disabled' };
    case CODES.passwordChangeRequired:
      return { kind: 'new_password' };
    case CODES.locked: {
      const sec = e instanceof ApiError ? Number(e.details?.retry_after_seconds) : NaN;
      return { kind: 'locked', retryAfterSec: Number.isFinite(sec) && sec > 0 ? Math.ceil(sec) : null };
    }
    default:
      return { kind: 'other', message: notDeployed(e) ? NOT_DEPLOYED : errorMessage(e) };
  }
}

/** «через 4 мин 12 с», «через 40 с»; без точного времени — «через 5 минут». */
export function lockWait(retryAfterSec: number | null): string {
  if (retryAfterSec === null) return `через ${LOCK_MINUTES} минут`;
  const min = Math.floor(retryAfterSec / 60);
  const sec = retryAfterSec % 60;
  if (min === 0) return `через ${sec} с`;
  return sec === 0 ? `через ${min} мин` : `через ${min} мин ${sec} с`;
}

export type FieldErrors<K extends string> = Partial<Record<K, string>>;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function emailError(email: string): string | null {
  const v = email.trim();
  if (!v) return 'Укажите рабочую почту.';
  return EMAIL_RE.test(v) ? null : 'Проверьте адрес: в нём должны быть @ и домен.';
}

export function passwordError(password: string): string | null {
  if (!password) return 'Придумайте пароль.';
  return password.length < MIN_PASSWORD ? `Пароль короче ${MIN_PASSWORD} символов.` : null;
}

export interface LoginForm {
  email: string;
  password: string;
}

export function loginFormErrors(f: LoginForm): FieldErrors<keyof LoginForm> {
  const out: FieldErrors<keyof LoginForm> = {};
  const email = emailError(f.email);
  if (email) out.email = email;
  if (!f.password) out.password = 'Введите пароль.';
  return out;
}

export interface RegisterForm {
  fullName: string;
  email: string;
  password: string;
  departmentId: string;
  comment: string;
}

export const REGISTER_EMPTY: RegisterForm = { fullName: '', email: '', password: '', departmentId: '', comment: '' };

export function registerFormErrors(f: RegisterForm): FieldErrors<'fullName' | 'email' | 'password'> {
  const out: FieldErrors<'fullName' | 'email' | 'password'> = {};
  if (!f.fullName.trim()) out.fullName = 'Укажите имя и фамилию.';
  const email = emailError(f.email);
  if (email) out.email = email;
  const password = passwordError(f.password);
  if (password) out.password = password;
  return out;
}

export interface NewPasswordForm {
  next: string;
  repeat: string;
}

export function newPasswordErrors(f: NewPasswordForm, previous?: string): FieldErrors<keyof NewPasswordForm> {
  const out: FieldErrors<keyof NewPasswordForm> = {};
  const next = passwordError(f.next);
  if (next) out.next = next;
  else if (previous !== undefined && f.next === previous) out.next = 'Новый пароль должен отличаться от прежнего.';
  if (!out.next && f.repeat !== f.next) out.repeat = 'Пароли не совпадают.';
  return out;
}

/** Почту сравниваем без учёта регистра и пробелов по краям (SPEC: уникальна без учёта регистра). */
export const normalizeEmail = (email: string) => email.trim().toLowerCase();

/** Ошибка регистрации, привязанная к полю: занятая почта — под полем почты. */
export function registerProblem(e: unknown): { field: 'email' | 'password' | 'fullName' | null; message: string } {
  if (codeOf(e) === CODES.emailTaken) {
    return { field: 'email', message: 'Эта почта уже зарегистрирована. Войдите или попросите администратора сбросить пароль.' };
  }
  if (codeOf(e) === CODES.inviteInvalid) {
    return { field: null, message: 'Приглашение не действует: срок истёк, его отозвали или им уже воспользовались.' };
  }
  const fields = fieldErrors(e);
  if (fields.email) return { field: 'email', message: fields.email };
  if (fields.password) return { field: 'password', message: fields.password };
  if (fields.full_name) return { field: 'fullName', message: fields.full_name };
  return { field: null, message: notDeployed(e) ? NOT_DEPLOYED : errorMessage(e) };
}

/** Способы входа сотрудника — для экрана профиля. */
export interface Account {
  email: string | null;
  hasPassword: boolean;
  telegramLinked: boolean;
}

/** Берём из Me. Старый сервер этих полей не присылает: тогда Telegram считаем привязанным по telegram_id. */
export function accountOf(me: Pick<Me, 'telegram_id'> & Partial<Pick<Me, 'email' | 'has_password' | 'telegram_linked'>>): Account {
  return {
    email: me.email ?? null,
    hasPassword: Boolean(me.has_password),
    telegramLinked: me.telegram_linked ?? me.telegram_id !== null,
  };
}

/** Отвязать Telegram можно, только если останется вход по почте и паролю (SPEC, «Вход и уведомления»). */
export const canUnlinkTelegram = (a: Account) => a.telegramLinked && Boolean(a.email) && a.hasPassword;

export interface ChangePasswordForm {
  current: string;
  next: string;
  repeat: string;
}

export function changePasswordErrors(f: ChangePasswordForm): FieldErrors<keyof ChangePasswordForm> {
  const out: FieldErrors<keyof ChangePasswordForm> = {};
  if (!f.current) out.current = 'Введите текущий пароль.';
  return { ...out, ...newPasswordErrors({ next: f.next, repeat: f.repeat }, f.current || undefined) };
}

/** Ошибка смены пароля: неверный текущий приходит как 422 с полем current_password — показываем под ним. */
export function changePasswordProblem(e: unknown): { field: 'current' | 'next' | null; message: string } {
  const fields = fieldErrors(e);
  if (fields.current_password) return { field: 'current', message: 'Текущий пароль не подходит.' };
  if (fields.new_password) return { field: 'next', message: fields.new_password };
  return { field: null, message: notDeployed(e) ? NOT_DEPLOYED : errorMessage(e) };
}

export interface CredentialsForm {
  email: string;
  password: string;
}

/** Пришедший через Telegram задаёт почту и пароль. */
export function credentialsErrors(f: CredentialsForm): FieldErrors<keyof CredentialsForm> {
  const out: FieldErrors<keyof CredentialsForm> = {};
  const email = emailError(f.email);
  if (email) out.email = email;
  const password = passwordError(f.password);
  if (password) out.password = password;
  return out;
}

/** Ошибка привязки Telegram: занятый аккаунт объясняем своими словами. */
export function linkTelegramProblem(e: unknown): string {
  if (codeOf(e) === CODES.telegramTaken) return 'Этот Telegram уже привязан к другому сотруднику. Войдите в нужный аккаунт Telegram и попробуйте снова.';
  if (codeOf(e) === 'invalid_telegram_auth') return 'Telegram не подтвердил вход. Попробуйте ещё раз.';
  return notDeployed(e) ? NOT_DEPLOYED : errorMessage(e);
}

/** Ошибка отвязки: единственный способ входа отвязать нельзя. */
export function unlinkTelegramProblem(e: unknown): string {
  if (codeOf(e) === CODES.lastLoginMethod) return 'Telegram — единственный способ входа. Сначала задайте почту и пароль.';
  return notDeployed(e) ? NOT_DEPLOYED : errorMessage(e);
}

/** Ошибка сброса пароля администратором: у сотрудника без почты сбрасывать нечего. */
export function resetPasswordProblem(e: unknown): string {
  if (codeOf(e) === CODES.conflict) return 'У сотрудника нет почты для входа: сбрасывать нечего.';
  // 404 здесь контрактный (сотрудника уже нет) — показываем текст сервера.
  return errorMessage(e);
}
