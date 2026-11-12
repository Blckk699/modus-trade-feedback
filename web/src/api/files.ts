import { config } from '../config';
import { tokenStore } from '../auth/tokenStore';
import { api, unwrap } from './client';
import { ApiError, toApiError } from './errors';
import type { Schemas } from './types';

/** Загрузить файл к обращению (multipart). 413 file_too_large приходит как ApiError. */
export function uploadAttachment(appealId: number, file: File): Promise<Schemas['Attachment']> {
  const form = new FormData();
  form.append('file', file, file.name);
  return unwrap(
    api.POST('/api/v1/appeals/{appeal_id}/attachments', {
      params: { path: { appeal_id: appealId } },
      // Тело уже готово: openapi-fetch не сериализует FormData и не ставит Content-Type, его задаст браузер.
      body: form as unknown as { file: string },
      bodySerializer: (b) => b as unknown as FormData,
    }),
  );
}

/** Загрузить аудиозапись совещания (multipart). Ответ 202 со status=processing. */
export function uploadMeeting(file: File, title: string): Promise<Schemas['Meeting']> {
  const form = new FormData();
  form.append('file', file, file.name);
  if (title) form.append('title', title);
  return unwrap(
    api.POST('/api/v1/meetings', {
      body: form as unknown as { file: string; title?: string },
      bodySerializer: (b) => b as unknown as FormData,
    }),
  );
}

/** Содержимое вложения: download_url требует токен, поэтому файл берём через fetch, а не ссылкой. */
export async function fetchAttachmentBlob(att: Schemas['Attachment']): Promise<Blob> {
  const url = att.download_url.startsWith('http') ? att.download_url : `${config.apiBaseUrl}${att.download_url}`;
  const token = tokenStore.get();
  let res: Response;
  try {
    res = await fetch(url, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
  } catch {
    throw new ApiError(0, 'network_error', 'Не удалось связаться с сервером. Проверьте подключение.');
  }
  if (!res.ok) throw toApiError(res.status, await res.json().catch(() => null));
  return res.blob();
}

/** Сохранить вложение как файл. */
export async function downloadAttachment(att: Schemas['Attachment']): Promise<void> {
  const href = URL.createObjectURL(await fetchAttachmentBlob(att));
  const a = document.createElement('a');
  a.href = href;
  a.download = att.filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(href), 1000);
}
