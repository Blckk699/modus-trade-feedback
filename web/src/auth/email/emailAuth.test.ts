import { describe, expect, it, vi } from 'vitest';
import { loginProblem } from './forms';

// Мок берёт сессию через dev-вход; в тестах сети нет — подменяем клиент.
vi.mock('../../api/client', () => ({
  api: { POST: vi.fn() },
  unwrap: vi.fn(async () => ({ access_token: 't', token_type: 'bearer', user: { id: 4 } })),
}));

import { createMockEmailAuth } from './emailAuth';

const problem = async (run: () => Promise<unknown>) => {
  try {
    await run();
    return null;
  } catch (e) {
    return loginProblem(e);
  }
};

describe('мок входа по почте повторяет правила B-20', () => {
  it('состояния: неверные данные, заявка, отключён, временный пароль, вход без учёта регистра', async () => {
    const a = createMockEmailAuth();
    expect(await problem(() => a.login('aigerim@modus.kz', 'не тот'))).toEqual({ kind: 'invalid' });
    expect(await problem(() => a.login('кто-то@modus.kz', 'demo12345'))).toEqual({ kind: 'invalid' });
    expect(await problem(() => a.login('new@modus.kz', 'demo12345'))).toEqual({ kind: 'pending' });
    expect(await problem(() => a.login('off@modus.kz', 'demo12345'))).toEqual({ kind: 'disabled' });
    expect(await problem(() => a.login('temp@modus.kz', 'temp12345'))).toEqual({ kind: 'new_password' });
    expect(await problem(() => a.login(' Aigerim@Modus.KZ ', 'demo12345'))).toBeNull();
  });

  it('пять неудач подряд блокируют почту на пять минут, потом вход снова работает', async () => {
    let t = 1_000_000;
    const a = createMockEmailAuth(() => t);
    for (let i = 0; i < 4; i++) expect(await problem(() => a.login('aigerim@modus.kz', 'x'))).toEqual({ kind: 'invalid' });
    expect(await problem(() => a.login('aigerim@modus.kz', 'x'))).toEqual({ kind: 'locked', retryAfterSec: 300 });
    // во время блокировки не пускает и верный пароль
    t += 60_000;
    expect(await problem(() => a.login('aigerim@modus.kz', 'demo12345'))).toEqual({ kind: 'locked', retryAfterSec: 240 });
    t += 5 * 60_000;
    expect(await problem(() => a.login('aigerim@modus.kz', 'demo12345'))).toBeNull();
  });

  it('временный пароль меняется на новый, после чего работает обычный вход', async () => {
    const a = createMockEmailAuth();
    await a.replaceTemporaryPassword('temp@modus.kz', 'temp12345', 'новый-пароль');
    expect(await problem(() => a.login('temp@modus.kz', 'новый-пароль'))).toBeNull();
    expect(await problem(() => a.login('temp@modus.kz', 'temp12345'))).toEqual({ kind: 'invalid' });
  });

  it('регистрация: без приглашения — заявка, с приглашением — сразу сессия, занятая почта — ошибка', async () => {
    const a = createMockEmailAuth();
    const input = { fullName: 'Дина Жуматова', email: 'dina@modus.kz', password: 'demo12345', departmentId: 2, comment: '' };
    expect(await a.register(input)).toEqual({ kind: 'pending' });
    expect(await problem(() => a.login('dina@modus.kz', 'demo12345'))).toEqual({ kind: 'pending' });
    expect((await a.register({ ...input, email: 'timur@modus.kz', inviteToken: 'inv' })).kind).toBe('session');
    await expect(a.register({ ...input, email: 'DINA@modus.kz' })).rejects.toMatchObject({ code: 'email_taken' });
  });
});
