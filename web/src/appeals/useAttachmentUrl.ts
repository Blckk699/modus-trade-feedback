import { useEffect, useState } from 'react';
import { fetchAttachmentBlob } from '../api/files';
import { tokenStore } from '../auth/tokenStore';
import type { Schemas } from '../api/types';

type Attachment = Schemas['Attachment'];

/** full — сам файл для просмотра; preview — уменьшенная копия картинки для плитки и ленты миниатюр. */
export type Variant = 'full' | 'preview';

/** Файл скачивается один раз за сеанс: все плитки и просмотр берут один и тот же адрес. */
const cache = new Map<string, Promise<string>>();
const key = (id: number, variant: Variant) => `${id}:${variant}`;

/**
 * Сеанс закончился или сменился пользователь (выход, переключатель роли): скачанные файлы
 * принадлежали прежней сессии. Забываем их и освобождаем память.
 */
export function forgetAttachments() {
  for (const p of new Set(cache.values())) p.then((url) => URL.revokeObjectURL(url)).catch(() => {});
  cache.clear();
}

tokenStore.subscribe(forgetAttachments);

/** Файл удалён: его копии в памяти больше не нужны. */
export function forgetAttachment(attachmentId: number) {
  const urls = new Set<Promise<string>>();
  for (const variant of ['full', 'preview'] as const) {
    const p = cache.get(key(attachmentId, variant));
    if (p) urls.add(p);
    cache.delete(key(attachmentId, variant));
  }
  for (const p of urls) p.then((url) => URL.revokeObjectURL(url)).catch(() => {});
}

function load(att: Attachment, variant: Variant): Promise<string> {
  const k = key(att.id, variant);
  let p = cache.get(k);
  if (!p) {
    // Уменьшенной копии нет (не картинка, старый сервер) или она не отдалась — берём сам файл.
    p =
      variant === 'preview'
        ? att.preview_url
          ? fetchAttachmentBlob(att, att.preview_url)
              .then((blob) => URL.createObjectURL(blob))
              .catch(() => load(att, 'full'))
          : load(att, 'full')
        : fetchAttachmentBlob(att).then((blob) => URL.createObjectURL(blob));
    // Неудачу не запоминаем: следующая попытка сходит на сервер заново.
    p.catch(() => cache.delete(k));
    cache.set(k, p);
  }
  return p;
}

/** Только что загруженный файл уже есть в браузере — показываем его без запроса к серверу. */
export function rememberLocal(attachmentId: number, file: Blob) {
  const url = Promise.resolve(URL.createObjectURL(file));
  cache.set(key(attachmentId, 'full'), url);
  cache.set(key(attachmentId, 'preview'), url);
}

export type UrlState = { status: 'idle' | 'loading' } | { status: 'ready'; url: string } | { status: 'error' };

/**
 * Адрес содержимого вложения для <img>, <video>, <audio>. Ссылки требуют токен, поэтому файл
 * скачивается и отдаётся как blob-адрес. `enabled` — когда пора грузить.
 */
export function useAttachmentUrl(att: Attachment, enabled: boolean, variant: Variant = 'full'): UrlState {
  const [state, setState] = useState<UrlState>({ status: 'idle' });

  useEffect(() => {
    if (!enabled) return;
    let alive = true;
    setState({ status: 'loading' });
    load(att, variant)
      .then((url) => alive && setState({ status: 'ready', url }))
      .catch(() => alive && setState({ status: 'error' }));
    return () => {
      alive = false;
    };
  }, [att, enabled, variant]);

  return state;
}
