import { api, unwrap } from '../../api/client';
import { ApiError } from '../../api/errors';
import type { Session } from '../../api/types';
import type { WidgetUser } from '../methods/telegramWidget';
import { CODES, LOCK_MINUTES, normalizeEmail, type Account } from './forms';

export interface RegisterInput {
  fullName: string;
  email: string;
  password: string;
  departmentId: number | null;
  comment: string;
  /** Действующее приглашение: регистрация сразу пускает внутрь, без заявки. */
  inviteToken?: string;
}

export type RegisterResult = { kind: 'pending' } | { kind: 'session'; session: Session };

/**
 * Вход и регистрация по почте, привязка Telegram, сброс пароля (B-20, истории 75–77).
 * Экраны знают только этот интерфейс. Ошибки — ApiError с кодами из forms.ts (CODES).
 */
export interface EmailAuthApi {
  login(email: string, password: string): Promise<Session>;
  /** Вход с временным паролем: задать новый и войти. */
  replaceTemporaryPassword(email: string, temporary: string, next: string): Promise<Session>;
  register(input: RegisterInput): Promise<RegisterResult>;
  account(): Promise<Account>;
  /** Для пришедших через Telegram: задать почту и пароль. */
  setEmailAndPassword(email: string, password: string): Promise<Account>;
  changePassword(current: string, next: string): Promise<void>;
  linkTelegram(user: WidgetUser): Promise<Account>;
  unlinkTelegram(): Promise<Account>;
  /** Администратор: временный пароль показывается один раз. */
  resetPassword(userId: number): Promise<{ temporaryPassword: string }>;
}

/* ───────── мок до контракта B-20 ─────────
   Живёт в памяти вкладки. Удачный вход берёт настоящую сессию через dev-вход локального бэкенда,
   чтобы после него открывалось приложение. Удаляется, когда контракт появится в main. */

interface MockUser {
  password: string;
  state: 'active' | 'pending' | 'disabled' | 'temporary';
  devUserId: number;
  telegramLinked: boolean;
  fails: number;
  lockedUntil: number;
}

const fail = (status: number, code: string, message: string, details: Record<string, unknown> | null = null) =>
  new ApiError(status, code as never, message, details);

const mockUser = (password: string, state: MockUser['state'], devUserId = 4): MockUser => ({
  password,
  state,
  devUserId,
  telegramLinked: false,
  fails: 0,
  lockedUntil: 0,
});

export function createMockEmailAuth(now: () => number = Date.now): EmailAuthApi {
  const users = new Map<string, MockUser>([
    ['aigerim@modus.kz', mockUser('demo12345', 'active', 4)],
    ['marat@modus.kz', mockUser('demo12345', 'active', 3)],
    ['new@modus.kz', mockUser('demo12345', 'pending')],
    ['off@modus.kz', mockUser('demo12345', 'disabled')],
    ['temp@modus.kz', mockUser('temp12345', 'temporary', 4)],
  ]);
  let current: string | null = null;

  const session = async (email: string, u: MockUser): Promise<Session> => {
    current = email;
    return unwrap(api.POST('/api/v1/auth/dev/login', { body: { user_id: u.devUserId } }));
  };

  const account = (): Account => {
    const u = current ? users.get(current) : undefined;
    return { email: u ? current : null, telegramLinked: u ? u.telegramLinked : true };
  };

  const check = (emailRaw: string, password: string): MockUser => {
    const email = normalizeEmail(emailRaw);
    const u = users.get(email);
    if (u && u.lockedUntil > now()) {
      throw fail(429, CODES.locked, 'Слишком много попыток.', { retry_after_seconds: (u.lockedUntil - now()) / 1000 });
    }
    if (!u || u.password !== password) {
      if (u && ++u.fails >= 5) {
        u.fails = 0;
        u.lockedUntil = now() + LOCK_MINUTES * 60_000;
        throw fail(429, CODES.locked, 'Слишком много попыток.', { retry_after_seconds: LOCK_MINUTES * 60 });
      }
      throw fail(401, CODES.invalidCredentials, 'Неверная почта или пароль.');
    }
    u.fails = 0;
    if (u.state === 'pending') throw fail(403, CODES.pending, 'Заявка на рассмотрении.');
    if (u.state === 'disabled') throw fail(403, CODES.disabled, 'Доступ отключён.');
    return u;
  };

  return {
    async login(email, password) {
      const u = check(email, password);
      if (u.state === 'temporary') throw fail(403, CODES.passwordChangeRequired, 'Задайте новый пароль.');
      return session(normalizeEmail(email), u);
    },
    async replaceTemporaryPassword(email, temporary, next) {
      const u = check(email, temporary);
      u.password = next;
      u.state = 'active';
      return session(normalizeEmail(email), u);
    },
    async register(input) {
      const email = normalizeEmail(input.email);
      if (users.has(email)) throw fail(409, CODES.emailTaken, 'Почта уже зарегистрирована.');
      const u = mockUser(input.password, input.inviteToken ? 'active' : 'pending');
      users.set(email, u);
      return input.inviteToken ? { kind: 'session', session: await session(email, u) } : { kind: 'pending' };
    },
    async account() {
      return account();
    },
    async setEmailAndPassword(emailRaw, password) {
      const email = normalizeEmail(emailRaw);
      if (users.has(email)) throw fail(409, CODES.emailTaken, 'Почта уже зарегистрирована.');
      users.set(email, { ...mockUser(password, 'active'), telegramLinked: true });
      current = email;
      return account();
    },
    async changePassword(currentPassword, next) {
      const u = current ? users.get(current) : undefined;
      if (!u || u.password !== currentPassword) throw fail(422, CODES.wrongPassword, 'Текущий пароль не подходит.');
      u.password = next;
    },
    async linkTelegram() {
      const u = current ? users.get(current) : undefined;
      if (u) u.telegramLinked = true;
      return account();
    },
    async unlinkTelegram() {
      const u = current ? users.get(current) : undefined;
      if (u) u.telegramLinked = false;
      return account();
    },
    async resetPassword() {
      return { temporaryPassword: `tmp-${Math.random().toString(36).slice(2, 8)}` };
    },
  };
}

/** Рабочий экземпляр. До контракта B-20 — мок; затем на его место встанет клиент API. */
export const emailAuth: EmailAuthApi = createMockEmailAuth();
