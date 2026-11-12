import { api, unwrap } from '../../api/client';
import { ApiError } from '../../api/errors';
import type { ErrorCode, Me, Session } from '../../api/types';
import type { EmailAuthApi } from './emailAuth';
import { CODES, LOCK_MINUTES, normalizeEmail } from './forms';

/* Мок входа по почте в памяти вкладки — для локальной проверки экранов (VITE_EMAIL_AUTH_MOCK=true).
   Удачный вход берёт настоящую сессию через dev-вход локального бэкенда, чтобы после него открывалось приложение.
   Учётки: aigerim@modus.kz и marat@modus.kz (demo12345), new@ — заявка, no@ — отклонена, off@ — отключён,
   temp@modus.kz (temp12345) — временный пароль. */

interface MockUser {
  password: string;
  state: 'active' | 'pending' | 'rejected' | 'disabled' | 'temporary';
  devUserId: number;
  telegramLinked: boolean;
  fails: number;
  lockedUntil: number;
}

const fail = (status: number, code: ErrorCode, message: string, details: Record<string, unknown> | null = null) =>
  new ApiError(status, code, message, details);

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
    ['no@modus.kz', mockUser('demo12345', 'rejected')],
    ['off@modus.kz', mockUser('demo12345', 'disabled')],
    ['temp@modus.kz', mockUser('temp12345', 'temporary', 4)],
  ]);
  let current: string | null = null;

  const session = async (email: string, u: MockUser): Promise<Session> => {
    current = email;
    const s = await unwrap(api.POST('/api/v1/auth/dev/login', { body: { user_id: u.devUserId } }));
    return { ...s, user: { ...s.user, email, has_password: true, telegram_linked: u.telegramLinked } };
  };

  const me = async (): Promise<Me> => {
    const real = await unwrap(api.GET('/api/v1/me'));
    const u = current ? users.get(current) : undefined;
    return u
      ? { ...real, email: current, has_password: true, telegram_linked: u.telegramLinked }
      : { ...real, email: null, has_password: false, telegram_linked: true };
  };

  const check = (emailRaw: string, password: string): MockUser => {
    const u = users.get(normalizeEmail(emailRaw));
    if (u && u.lockedUntil > now()) throw fail(429, CODES.locked, 'Слишком много попыток. Подождите и попробуйте снова.');
    if (!u || u.password !== password) {
      if (u && ++u.fails >= 5) {
        u.fails = 0;
        u.lockedUntil = now() + LOCK_MINUTES * 60_000;
        throw fail(429, CODES.locked, 'Слишком много попыток. Подождите и попробуйте снова.');
      }
      throw fail(401, CODES.invalidCredentials, 'Неверная почта или пароль.');
    }
    u.fails = 0;
    if (u.state === 'pending') throw fail(403, CODES.pending, 'Заявка на рассмотрении. Войти можно после одобрения.');
    if (u.state === 'rejected') throw fail(403, CODES.rejected, 'Заявка на доступ отклонена.', { reason: 'Подрядчикам доступ не выдаём' });
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
      if (users.has(email)) throw fail(409, CODES.emailTaken, 'Эта почта уже у другого сотрудника.');
      const u = mockUser(input.password, input.inviteToken ? 'active' : 'pending');
      users.set(email, u);
      return input.inviteToken ? { kind: 'session', session: await session(email, u) } : { kind: 'pending' };
    },
    async setEmailAndPassword(emailRaw, password) {
      const email = normalizeEmail(emailRaw);
      if (users.has(email)) throw fail(409, CODES.emailTaken, 'Эта почта уже у другого сотрудника.');
      users.set(email, { ...mockUser(password, 'active'), telegramLinked: true });
      current = email;
      return me();
    },
    async changePassword(currentPassword, next) {
      const u = current ? users.get(current) : undefined;
      if (!u || u.password !== currentPassword) {
        throw fail(422, 'validation_error', 'Проверьте поля.', { fields: [{ field: 'current_password', message: 'Неверный текущий пароль.' }] });
      }
      u.password = next;
      return me();
    },
    async linkTelegram() {
      const u = current ? users.get(current) : undefined;
      if (u) u.telegramLinked = true;
      return me();
    },
    async unlinkTelegram() {
      const u = current ? users.get(current) : undefined;
      if (!u) throw fail(409, CODES.lastLoginMethod, 'Нельзя отвязать единственный способ входа.');
      u.telegramLinked = false;
      return me();
    },
    async resetPassword() {
      return { temporaryPassword: `Tmp-${Math.random().toString(36).slice(2, 6)}-${Math.random().toString(36).slice(2, 6)}` };
    },
  };
}
