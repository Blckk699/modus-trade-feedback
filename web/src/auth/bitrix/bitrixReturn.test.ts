import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ApiError } from '../../api/errors';
import { outcomeOfExchangeError, parseBitrixReturn, returnToStore, safeReturnTo } from './bitrixReturn';

describe('разбор возврата из портала', () => {
  it('одноразовый код из строки запроса', () => {
    expect(parseBitrixReturn('?code=abc')).toEqual({ kind: 'code', code: 'abc' });
    expect(parseBitrixReturn('code=abc')).toEqual({ kind: 'code', code: 'abc' });
  });

  it('заявка на рассмотрении, отклонена, доступ отключён, отмена на портале', () => {
    expect(parseBitrixReturn('?error=access_request_pending')).toEqual({ kind: 'pending' });
    expect(parseBitrixReturn('?error=access_request_rejected')).toEqual({ kind: 'rejected', reason: null });
    expect(parseBitrixReturn('?error=user_disabled')).toEqual({ kind: 'disabled' });
    expect(parseBitrixReturn('?error=access_denied')).toEqual({ kind: 'cancelled' });
    expect(parseBitrixReturn('?code=x&error=access_denied')).toEqual({ kind: 'cancelled' });
  });

  it('коды ошибок контракта — свои тексты, незнакомый код и пустой адрес — общий текст экрана', () => {
    const bad = parseBitrixReturn('?error=invalid_bitrix_auth');
    expect(bad.kind === 'error' && bad.message).toMatch(
      /^Для этой учётной записи вход через Битрикс24 не настроен\. Войдите по почте или через Telegram/,
    );
    const down = parseBitrixReturn('?error=bitrix_unavailable');
    expect(down.kind === 'error' && down.message).toMatch(/не ответил/);
    expect(parseBitrixReturn('?error=unknown_thing')).toEqual({ kind: 'error', message: null });
    expect(parseBitrixReturn('')).toEqual({ kind: 'error', message: null });
    expect(parseBitrixReturn('?code=%20')).toEqual({ kind: 'error', message: null });
  });
});

describe('безопасность адреса возврата', () => {
  it('токен в адресе игнорируется: сессию даёт только обмен кода', () => {
    expect(parseBitrixReturn('?access_token=evil')).toEqual({ kind: 'error', message: null });
    expect(parseBitrixReturn('?access_token=evil&code=abc')).toEqual({ kind: 'code', code: 'abc' });
  });

  it('чужой текст из адреса не выводится', () => {
    const phishing = 'Позвоните%20по%20номеру%208-800';
    for (const q of [
      `?error=server_error&message=${phishing}`,
      `?error=server_error&error_description=${phishing}`,
      `?error=invalid_bitrix_auth&message=${phishing}`,
    ]) {
      expect(JSON.stringify(parseBitrixReturn(q))).not.toContain('8-800');
    }
    expect(parseBitrixReturn(`?error=access_request_rejected&reason=${phishing}`)).toEqual({ kind: 'rejected', reason: null });
  });
});

describe('ответ обмена кода на сессию', () => {
  const err = (status: number, code: ConstructorParameters<typeof ApiError>[1], details: Record<string, unknown> | null = null) =>
    new ApiError(status, code, 'текст сервера', details);

  it('отказы входа совпадают с входом по почте', () => {
    expect(outcomeOfExchangeError(err(403, 'access_request_pending'))).toEqual({ kind: 'pending' });
    expect(outcomeOfExchangeError(err(403, 'user_disabled'))).toEqual({ kind: 'disabled' });
    expect(outcomeOfExchangeError(err(403, 'access_request_rejected', { reason: 'нет' }))).toEqual({
      kind: 'rejected',
      reason: 'нет',
    });
  });

  it('неверный или истёкший код и сеть — ошибка с текстом', () => {
    expect(outcomeOfExchangeError(err(401, 'invalid_login_code'))).toEqual({ kind: 'error', message: 'текст сервера' });
    expect(outcomeOfExchangeError(new Error('x'))).toEqual({
      kind: 'error',
      message: 'Не удалось связаться с сервером. Проверьте подключение.',
    });
  });
});

describe('исходный адрес после входа', () => {
  it('только свои пути, не экран возврата и не корень', () => {
    expect(safeReturnTo('/appeals/12?tab=chat')).toBe('/appeals/12?tab=chat');
    expect(safeReturnTo('/')).toBeNull();
    expect(safeReturnTo('//evil.example/x')).toBeNull();
    expect(safeReturnTo('/\\evil.example')).toBeNull();
    expect(safeReturnTo('https://evil.example')).toBeNull();
    expect(safeReturnTo('/auth/bitrix/done')).toBeNull();
    expect(safeReturnTo(null)).toBeNull();
  });

  describe('хранилище вкладки', () => {
    const data = new Map<string, string>();
    beforeEach(() => {
      data.clear();
      (globalThis as { window?: unknown }).window = {
        sessionStorage: {
          getItem: (k: string) => data.get(k) ?? null,
          setItem: (k: string, v: string) => data.set(k, v),
          removeItem: (k: string) => data.delete(k),
        },
      };
    });
    afterEach(() => {
      delete (globalThis as { window?: unknown }).window;
    });

    it('сохраняет, отдаёт один раз и забывает', () => {
      returnToStore.save('/profile');
      expect(returnToStore.take()).toBe('/profile');
      expect(returnToStore.take()).toBeNull();
    });

    it('чужой адрес не сохраняет и стирает прежний', () => {
      returnToStore.save('/profile');
      returnToStore.save('//evil.example');
      expect(returnToStore.take()).toBeNull();
    });
  });
});
