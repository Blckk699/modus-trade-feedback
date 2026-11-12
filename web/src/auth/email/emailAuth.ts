import { api, unwrap } from '../../api/client';
import type { Me, Session } from '../../api/types';
import { config } from '../../config';
import type { WidgetUser } from '../methods/telegramWidget';
import { createMockEmailAuth } from './mockEmailAuth';

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
 * Экраны знают только этот интерфейс. Ошибки — ApiError с кодами контракта (см. forms.ts).
 */
export interface EmailAuthApi {
  login(email: string, password: string): Promise<Session>;
  /** Вход с временным паролем: задать новый и войти. */
  replaceTemporaryPassword(email: string, temporary: string, next: string): Promise<Session>;
  register(input: RegisterInput): Promise<RegisterResult>;
  /** Для пришедших через Telegram: задать почту и пароль. */
  setEmailAndPassword(email: string, password: string): Promise<Me>;
  changePassword(current: string, next: string): Promise<Me>;
  linkTelegram(user: WidgetUser): Promise<Me>;
  unlinkTelegram(): Promise<Me>;
  /** Администратор: временный пароль показывается один раз. */
  resetPassword(userId: number): Promise<{ temporaryPassword: string }>;
}

const httpEmailAuth: EmailAuthApi = {
  login: (email, password) => unwrap(api.POST('/api/v1/auth/login', { body: { email: email.trim(), password } })),

  // Контракт: на 403 password_change_required тот же запрос повторяют с new_password.
  replaceTemporaryPassword: (email, temporary, next) =>
    unwrap(api.POST('/api/v1/auth/login', { body: { email: email.trim(), password: temporary, new_password: next } })),

  async register(input) {
    const res = await unwrap(
      api.POST('/api/v1/auth/register', {
        body: {
          full_name: input.fullName,
          email: input.email,
          password: input.password,
          department_id: input.departmentId,
          comment: input.comment || null,
          invite_token: input.inviteToken ?? null,
        },
      }),
    );
    // Успех — только то, что сервер подтвердил: заявка принята либо выдана сессия по приглашению.
    if (res.status === 'registered' && res.session) return { kind: 'session', session: res.session };
    if (res.status === 'pending') return { kind: 'pending' };
    throw new Error('Сервер не подтвердил регистрацию.');
  },

  setEmailAndPassword: (email, password) => unwrap(api.PUT('/api/v1/me/credentials', { body: { email, new_password: password } })),

  changePassword: (current, next) =>
    unwrap(api.PUT('/api/v1/me/credentials', { body: { current_password: current, new_password: next } })),

  linkTelegram: (user) => unwrap(api.POST('/api/v1/me/telegram', { body: user })),

  unlinkTelegram: () => unwrap(api.DELETE('/api/v1/me/telegram')),

  async resetPassword(userId) {
    const res = await unwrap(
      api.POST('/api/v1/admin/users/{user_id}/reset-password', { params: { path: { user_id: userId } } }),
    );
    return { temporaryPassword: res.temporary_password };
  },
};

/**
 * Рабочий экземпляр — клиент API. Мок в памяти включается только настройкой VITE_EMAIL_AUTH_MOCK=true
 * (локальная проверка экранов, пока сервер не умеет вход по почте) и никогда не попадает на сервер демо.
 */
export const emailAuth: EmailAuthApi = config.emailAuthMock ? createMockEmailAuth() : httpEmailAuth;
