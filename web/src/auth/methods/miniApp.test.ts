import { afterEach, describe, expect, it, vi } from 'vitest';

// openapi-fetch запоминает fetch при создании клиента, поэтому подменяем его до импорта модуля.
async function load(response?: Response) {
  const fetchMock = vi.fn(async (_req: Request) => response ?? new Response(null, { status: 500 }));
  vi.stubGlobal('fetch', fetchMock);
  vi.resetModules();
  const { miniAppMethod } = await import('./miniApp');
  return { miniAppMethod, fetchMock };
}

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

const session = {
  access_token: 'token',
  token_type: 'bearer',
  expires_at: '2026-11-11T10:00:00+05:00',
  user: { id: 4 },
};

function inTelegram(initData: string) {
  (globalThis as { window?: unknown }).window = { Telegram: { WebApp: { initData, initDataUnsafe: {} } } };
}

afterEach(() => {
  delete (globalThis as { window?: unknown }).window;
  vi.unstubAllGlobals();
});

describe('вход Mini App', () => {
  it('вне Telegram недоступен', async () => {
    const { miniAppMethod } = await load();
    expect(miniAppMethod.isAvailable()).toBe(false);
    inTelegram('');
    expect(miniAppMethod.isAvailable()).toBe(false);
  });

  it('в Telegram отправляет initData и возвращает сессию', async () => {
    inTelegram('query_id=1&user=%7B%22id%22%3A100000004%7D&hash=abc');
    const { miniAppMethod, fetchMock } = await load(json(session, 200));

    expect(miniAppMethod.isAvailable()).toBe(true);
    await expect(miniAppMethod.autoLogin!()).resolves.toEqual(session);

    const request = fetchMock.mock.calls[0][0];
    expect(request.url).toMatch(/\/api\/v1\/auth\/telegram\/mini-app$/);
    expect(await request.json()).toEqual({ init_data: 'query_id=1&user=%7B%22id%22%3A100000004%7D&hash=abc' });
  });

  it('отказ API пробрасывается с message для экрана входа', async () => {
    inTelegram('hash=abc');
    const { miniAppMethod } = await load(
      json({ error: { code: 'user_not_registered', message: 'Вас нет в списке сотрудников.', details: null } }, 403),
    );

    await expect(miniAppMethod.autoLogin!()).rejects.toMatchObject({
      code: 'user_not_registered',
      message: 'Вас нет в списке сотрудников.',
    });
  });
});
