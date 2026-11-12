import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { ApiError } from '../../api/errors';
import { outcomeOfExchangeError, parseBitrixReturn, returnToStore, safeReturnTo } from './bitrixReturn';

describe('разбор возврата из портала', () => {
  it('одноразовый код из фрагмента и из строки запроса, фрагмент в приоритете', () => {
    expect(parseBitrixReturn('', '#code=abc')).toEqual({ kind: 'code', code: 'abc' });
    expect(parseBitrixReturn('?code=q', '')).toEqual({ kind: 'code', code: 'q' });
    expect(parseBitrixReturn('?code=q', '#code=h')).toEqual({ kind: 'code', code: 'h' });
  });

  it('готовый токен во фрагменте', () => {
    expect(parseBitrixReturn('', '#access_token=t1')).toEqual({ kind: 'token', token: 't1' });
  });

  it('заявка на рассмотрении, отклонена с причиной, доступ отключён', () => {
    expect(parseBitrixReturn('?error=access_request_pending', '')).toEqual({ kind: 'pending' });
    expect(parseBitrixReturn('', '#status=pending')).toEqual({ kind: 'pending' });
    expect(parseBitrixReturn('?error=access_request_rejected&reason=%20Нет%20в%20штате%20', '')).toEqual({
      kind: 'rejected',
      reason: 'Нет в штате',
    });
    expect(parseBitrixReturn('?error=rejected', '')).toEqual({ kind: 'rejected', reason: null });
    expect(parseBitrixReturn('?error=user_disabled', '')).toEqual({ kind: 'disabled' });
  });

  it('отмена на портале: OAuth access_denied, даже если рядом есть code', () => {
    expect(parseBitrixReturn('?error=access_denied', '')).toEqual({ kind: 'cancelled' });
    expect(parseBitrixReturn('?code=x&error=access_denied', '')).toEqual({ kind: 'cancelled' });
  });

  it('прочие ошибки и пустой адрес — общая ошибка, текст сервера если есть', () => {
    expect(parseBitrixReturn('?error=invalid_state&message=Ссылка%20устарела', '')).toEqual({
      kind: 'error',
      message: 'Ссылка устарела',
    });
    expect(parseBitrixReturn('?error=server_error&error_description=boom', '')).toEqual({ kind: 'error', message: 'boom' });
    expect(parseBitrixReturn('', '')).toEqual({ kind: 'error', message: null });
    expect(parseBitrixReturn('?error=unknown_thing', '')).toEqual({ kind: 'error', message: null });
    expect(parseBitrixReturn('?code=%20', '')).toEqual({ kind: 'error', message: null });
  });
});

describe('коды ошибок контракта B-23 без текста в адресе', () => {
  it('invalid_bitrix_auth и bitrix_unavailable объясняются своими словами', () => {
    const bad = parseBitrixReturn('?error=invalid_bitrix_auth', '');
    expect(bad.kind).toBe('error');
    expect(bad.kind === 'error' && bad.message).toMatch(/Попробуйте ещё раз/);
    const down = parseBitrixReturn('?error=bitrix_unavailable', '');
    expect(down.kind === 'error' && down.message).toMatch(/не ответил/);
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
