import { describe, expect, it } from 'vitest';
import { ApiError } from '../../api/errors';
import type { ErrorCode } from '../../api/types';
import {
  CODES,
  accountOf,
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
  resetPasswordProblem,
  unlinkTelegramProblem,
} from './forms';

const apiError = (status: number, code: ErrorCode, details: Record<string, unknown> | null = null) =>
  new ApiError(status, code, 'текст сервера', details);
const invalidField = (field: string) => apiError(422, 'validation_error', { fields: [{ field, message: 'текст поля' }] });

describe('состояния ответа входа по почте', () => {
  it('неверные данные, заявка на рассмотрении, доступ отключён, временный пароль', () => {
    expect(loginProblem(apiError(401, CODES.invalidCredentials))).toEqual({ kind: 'invalid' });
    expect(loginProblem(apiError(403, CODES.pending))).toEqual({ kind: 'pending' });
    expect(loginProblem(apiError(403, CODES.disabled))).toEqual({ kind: 'disabled' });
    expect(loginProblem(apiError(403, CODES.passwordChangeRequired))).toEqual({ kind: 'new_password' });
  });

  it('отклонённая заявка: причина из details.reason, без неё — null', () => {
    expect(loginProblem(apiError(403, CODES.rejected, { reason: ' Подрядчикам доступ не выдаём ' }))).toEqual({
      kind: 'rejected',
      reason: 'Подрядчикам доступ не выдаём',
    });
    expect(loginProblem(apiError(403, CODES.rejected))).toEqual({ kind: 'rejected', reason: null });
  });

  it('блокировка (429 too_many_requests): время из ответа, если сервер его дал, иначе пять минут', () => {
    expect(loginProblem(apiError(429, CODES.locked, { retry_after_seconds: 251.2 }))).toEqual({ kind: 'locked', retryAfterSec: 252 });
    expect(loginProblem(apiError(429, 'too_many_requests'))).toEqual({ kind: 'locked', retryAfterSec: null });
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

  it('сервер без входа по почте (404, 405) — честное сообщение, а не «не найдено»', () => {
    const text = 'Вход по почте на этом сервере ещё не включён. Войдите через Telegram или попробуйте позже.';
    expect(loginProblem(apiError(404, 'not_found'))).toEqual({ kind: 'other', message: text });
    expect(registerProblem(apiError(405, 'internal_error'))).toEqual({ field: null, message: text });
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
    expect(registerFormErrors({ ...REGISTER_EMPTY, fullName: 'Карина Шаймерденова', email: 'a@modus.kz', password: 'длинный-пароль' })).toEqual({});
  });

  it('пароль не короче восьми символов', () => {
    const f = { ...REGISTER_EMPTY, fullName: 'Карина', email: 'a@modus.kz' };
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
    expect(registerProblem(invalidField('body.password'))).toEqual({ field: 'password', message: 'текст поля' });
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
  it('можно, только если остаются почта и пароль', () => {
    expect(canUnlinkTelegram({ email: 'a@modus.kz', hasPassword: true, telegramLinked: true })).toBe(true);
    expect(canUnlinkTelegram({ email: 'a@modus.kz', hasPassword: false, telegramLinked: true })).toBe(false);
    expect(canUnlinkTelegram({ email: null, hasPassword: false, telegramLinked: true })).toBe(false);
    expect(canUnlinkTelegram({ email: 'a@modus.kz', hasPassword: true, telegramLinked: false })).toBe(false);
  });

  it('способы входа берутся из Me; старый сервер без этих полей — Telegram по telegram_id', () => {
    expect(accountOf({ telegram_id: null, email: 'a@modus.kz', has_password: true, telegram_linked: false })).toEqual({
      email: 'a@modus.kz',
      hasPassword: true,
      telegramLinked: false,
    });
    expect(accountOf({ telegram_id: 100000004 })).toEqual({ email: null, hasPassword: false, telegramLinked: true });
    expect(accountOf({ telegram_id: null })).toEqual({ email: null, hasPassword: false, telegramLinked: false });
  });

  it('единственный способ входа отвязать нельзя; у сотрудника без почты пароль не сбросить', () => {
    expect(unlinkTelegramProblem(apiError(409, CODES.lastLoginMethod))).toContain('единственный способ входа');
    expect(resetPasswordProblem(apiError(409, 'conflict'))).toContain('нет почты');
    // 404 у сброса пароля — контрактный «сотрудник не найден», а не «вход по почте не включён»
    expect(resetPasswordProblem(apiError(404, 'not_found'))).toBe('текст сервера');
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
    expect(changePasswordProblem(invalidField('body.current_password'))).toEqual({ field: 'current', message: 'Текущий пароль не подходит.' });
    expect(changePasswordProblem(invalidField('new_password'))).toEqual({ field: 'next', message: 'текст поля' });
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
