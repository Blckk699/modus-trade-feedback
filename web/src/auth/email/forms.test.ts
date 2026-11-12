import { describe, expect, it } from 'vitest';
import { ApiError } from '../../api/errors';
import {
  CODES,
  canUnlinkTelegram,
  changePasswordErrors,
  changePasswordProblem,
  credentialsErrors,
  emailError,
  linkTelegramProblem,
  lockWait,
  loginFormErrors,
  loginProblem,
  newPasswordErrors,
  normalizeEmail,
  registerFormErrors,
  registerProblem,
  REGISTER_EMPTY,
} from './forms';

const apiError = (status: number, code: string, details: Record<string, unknown> | null = null) =>
  new ApiError(status, code as never, 'текст сервера', details);

describe('состояния ответа входа по почте', () => {
  it('неверные данные, заявка на рассмотрении, доступ отключён, временный пароль', () => {
    expect(loginProblem(apiError(401, CODES.invalidCredentials))).toEqual({ kind: 'invalid' });
    expect(loginProblem(apiError(403, CODES.pending))).toEqual({ kind: 'pending' });
    expect(loginProblem(apiError(403, CODES.disabled))).toEqual({ kind: 'disabled' });
    expect(loginProblem(apiError(403, CODES.passwordChangeRequired))).toEqual({ kind: 'new_password' });
  });

  it('блокировка: время берём из ответа, без него — пять минут', () => {
    expect(loginProblem(apiError(429, CODES.locked, { retry_after_seconds: 251.2 }))).toEqual({ kind: 'locked', retryAfterSec: 252 });
    expect(loginProblem(apiError(429, CODES.locked))).toEqual({ kind: 'locked', retryAfterSec: null });
    expect(lockWait(252)).toBe('через 4 мин 12 с');
    expect(lockWait(120)).toBe('через 2 мин');
    expect(lockWait(40)).toBe('через 40 с');
    expect(lockWait(null)).toBe('через 5 минут');
  });

  it('незнакомая ошибка и обрыв связи — текстом', () => {
    expect(loginProblem(apiError(500, 'internal_error'))).toEqual({ kind: 'other', message: 'текст сервера' });
    expect(loginProblem(new TypeError('fetch failed'))).toEqual({
      kind: 'other',
      message: 'Не удалось связаться с сервером. Проверьте подключение.',
    });
  });
});

describe('форма входа', () => {
  it('пустые поля и кривая почта', () => {
    expect(loginFormErrors({ email: '', password: '' })).toEqual({ email: 'Укажите рабочую почту.', password: 'Введите пароль.' });
    expect(loginFormErrors({ email: 'aigerim@modus', password: 'x' })).toEqual({ email: 'Проверьте адрес: в нём должны быть @ и домен.' });
    expect(loginFormErrors({ email: ' aigerim@modus.kz ', password: 'x' })).toEqual({});
  });

  it('почта сравнивается без регистра и пробелов', () => {
    expect(normalizeEmail('  Aigerim@Modus.KZ ')).toBe('aigerim@modus.kz');
    expect(emailError('aigerim@modus.kz')).toBeNull();
  });
});

describe('форма регистрации', () => {
  it('имя, почта и пароль обязательны, подразделение и комментарий — нет', () => {
    expect(registerFormErrors(REGISTER_EMPTY)).toEqual({
      fullName: 'Укажите имя и фамилию.',
      email: 'Укажите рабочую почту.',
      password: 'Придумайте пароль.',
    });
    expect(registerFormErrors({ ...REGISTER_EMPTY, fullName: 'Айгерим Нурланова', email: 'a@modus.kz', password: 'длинный-пароль' })).toEqual({});
  });

  it('пароль не короче восьми символов', () => {
    const f = { ...REGISTER_EMPTY, fullName: 'Айгерим', email: 'a@modus.kz' };
    expect(registerFormErrors({ ...f, password: '1234567' })).toEqual({ password: 'Пароль короче 8 символов.' });
    expect(registerFormErrors({ ...f, password: '12345678' })).toEqual({});
  });

  it('занятая почта показывается под полем почты, недействительное приглашение — общим текстом', () => {
    expect(registerProblem(apiError(409, CODES.emailTaken)).field).toBe('email');
    expect(registerProblem(apiError(410, CODES.inviteInvalid))).toEqual({
      field: null,
      message: 'Приглашение не действует: срок истёк, его отозвали или им уже воспользовались.',
    });
    expect(registerProblem(apiError(500, 'internal_error'))).toEqual({ field: null, message: 'текст сервера' });
  });
});

describe('новый пароль', () => {
  it('длина, совпадение, отличие от временного', () => {
    expect(newPasswordErrors({ next: '', repeat: '' })).toEqual({ next: 'Придумайте пароль.' });
    expect(newPasswordErrors({ next: '1234567', repeat: '1234567' })).toEqual({ next: 'Пароль короче 8 символов.' });
    expect(newPasswordErrors({ next: 'новый-пароль', repeat: 'другой-пароль' })).toEqual({ repeat: 'Пароли не совпадают.' });
    expect(newPasswordErrors({ next: 'временный1', repeat: 'временный1' }, 'временный1')).toEqual({
      next: 'Новый пароль должен отличаться от прежнего.',
    });
    expect(newPasswordErrors({ next: 'новый-пароль', repeat: 'новый-пароль' }, 'временный1')).toEqual({});
  });
});

describe('профиль: отвязка Telegram', () => {
  it('можно, только если есть почта для входа', () => {
    expect(canUnlinkTelegram({ email: 'a@modus.kz', telegramLinked: true })).toBe(true);
    expect(canUnlinkTelegram({ email: null, telegramLinked: true })).toBe(false);
    expect(canUnlinkTelegram({ email: 'a@modus.kz', telegramLinked: false })).toBe(false);
  });
});

describe('профиль: смена пароля и почта для пришедших через Telegram', () => {
  it('нужен текущий пароль, новый отличается и повторён верно', () => {
    expect(changePasswordErrors({ current: '', next: 'новый-пароль', repeat: 'новый-пароль' })).toEqual({ current: 'Введите текущий пароль.' });
    expect(changePasswordErrors({ current: 'старый-пароль', next: 'старый-пароль', repeat: 'старый-пароль' })).toEqual({
      next: 'Новый пароль должен отличаться от прежнего.',
    });
    expect(changePasswordErrors({ current: 'старый-пароль', next: 'новый-пароль', repeat: 'новый-пароль' })).toEqual({});
  });

  it('неверный текущий пароль показывается под его полем', () => {
    expect(changePasswordProblem(apiError(422, CODES.wrongPassword))).toEqual({ field: 'current', message: 'Текущий пароль не подходит.' });
    expect(changePasswordProblem(apiError(500, 'internal_error'))).toEqual({ field: null, message: 'текст сервера' });
  });

  it('почта и пароль для Telegram-пользователя', () => {
    expect(credentialsErrors({ email: '', password: '' })).toEqual({ email: 'Укажите рабочую почту.', password: 'Придумайте пароль.' });
    expect(credentialsErrors({ email: 'marat@modus.kz', password: '12345678' })).toEqual({});
  });

  it('занятый Telegram объясняется своими словами', () => {
    expect(linkTelegramProblem(apiError(409, CODES.telegramTaken))).toContain('уже привязан к другому сотруднику');
    expect(linkTelegramProblem(apiError(500, 'internal_error'))).toBe('текст сервера');
  });
});
