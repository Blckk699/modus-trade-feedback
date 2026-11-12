import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../api/files', () => ({ fetchAttachmentBlob: vi.fn() }));

import { tokenStore } from '../auth/tokenStore';
import { forgetAttachment, forgetAttachments, rememberLocal } from './useAttachmentUrl';

describe('кеш скачанных вложений живёт в пределах одной сессии', () => {
  const created: string[] = [];
  const revoked: string[] = [];

  beforeEach(() => {
    created.length = 0;
    revoked.length = 0;
    vi.stubGlobal('URL', {
      createObjectURL: () => {
        const url = `blob:test-${created.length + 1}`;
        created.push(url);
        return url;
      },
      revokeObjectURL: (url: string) => revoked.push(url),
    });
    vi.stubGlobal('window', { localStorage: { getItem: () => null, setItem: () => {}, removeItem: () => {} } });
  });

  afterEach(() => {
    forgetAttachments();
    vi.unstubAllGlobals();
  });

  const settle = () => new Promise((r) => setTimeout(r, 0));

  it('смена токена (переключатель роли, новый вход) освобождает файлы прежней сессии', async () => {
    rememberLocal(1, new Blob(['a']));
    rememberLocal(2, new Blob(['b']));
    tokenStore.set('токен-другой-роли');
    await settle();
    expect(revoked).toEqual(['blob:test-1', 'blob:test-2']);
  });

  it('выход (токен сброшен) тоже освобождает', async () => {
    tokenStore.set('токен');
    rememberLocal(3, new Blob(['c']));
    tokenStore.set(null);
    await settle();
    expect(revoked).toEqual(['blob:test-1']);
  });

  it('удалённый файл освобождается один, остальные остаются', async () => {
    rememberLocal(5, new Blob(['e']));
    rememberLocal(6, new Blob(['f']));
    forgetAttachment(5);
    await settle();
    expect(revoked).toEqual(['blob:test-1']);
  });
});
