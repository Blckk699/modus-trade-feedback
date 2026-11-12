import { useEffect, useState } from 'react';
import { fetchAttachmentBlob } from '../api/files';
import { tokenStore } from '../auth/tokenStore';
import type { Schemas } from '../api/types';

type Attachment = Schemas['Attachment'];

/** Файл скачивается один раз за сеанс: плитка и просмотр берут один и тот же адрес. */
const cache = new Map<number, Promise<string>>();

/**
 * Сеанс закончился или сменился пользователь (выход, переключатель роли): скачанные файлы
 * принадлежали прежней сессии. Забываем их и освобождаем память.
 */
export function forgetAttachments() {
  for (const p of cache.values()) p.then((url) => URL.revokeObjectURL(url)).catch(() => {});
  cache.clear();
}

tokenStore.subscribe(forgetAttachments);

function load(att: Attachment): Promise<string> {
  let p = cache.get(att.id);
  if (!p) {
    p = fetchAttachmentBlob(att).then((blob) => URL.createObjectURL(blob));
    // Неудачу не запоминаем: следующая попытка сходит на сервер заново.
    p.catch(() => cache.delete(att.id));
    cache.set(att.id, p);
  }
  return p;
}

/** Только что загруженный файл уже есть в браузере — показываем его без запроса к серверу. */
export function rememberLocal(attachmentId: number, file: Blob) {
  cache.set(attachmentId, Promise.resolve(URL.createObjectURL(file)));
}

export type UrlState = { status: 'idle' | 'loading' } | { status: 'ready'; url: string } | { status: 'error' };

/**
 * Адрес содержимого вложения для <img>, <video>, <audio>. Ссылка download_url требует токен,
 * поэтому файл скачивается и отдаётся как blob-адрес. `enabled` — когда пора грузить.
 */
export function useAttachmentUrl(att: Attachment, enabled: boolean): UrlState {
  const [state, setState] = useState<UrlState>({ status: 'idle' });

  useEffect(() => {
    if (!enabled) return;
    let alive = true;
    setState({ status: 'loading' });
    load(att)
      .then((url) => alive && setState({ status: 'ready', url }))
      .catch(() => alive && setState({ status: 'error' }));
    return () => {
      alive = false;
    };
  }, [att, enabled]);

  return state;
}
