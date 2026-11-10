import { ApiError } from './errors';

/**
 * Ошибки полей из 422 validation_error: details.fields[{field, message}] → { поле: текст }.
 * Префикс `body.` (как его отдаёт валидатор FastAPI или мок) отбрасывается, чтобы ключ совпал с именем поля формы.
 * Любая другая ошибка — пустой объект: её текст показывается общим сообщением.
 */
export function fieldErrors(e: unknown): Record<string, string> {
  if (!(e instanceof ApiError) || e.code !== 'validation_error') return {};
  const fields = e.details?.fields;
  if (!Array.isArray(fields)) return {};
  const out: Record<string, string> = {};
  for (const f of fields as { field?: unknown; message?: unknown }[]) {
    if (typeof f?.field !== 'string' || typeof f?.message !== 'string') continue;
    out[f.field.replace(/^body\./, '')] = f.message;
  }
  return out;
}
