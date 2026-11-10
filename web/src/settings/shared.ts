import { ApiError } from '../api/errors';
import type { Schemas } from '../api/types';

export type User = Schemas['User'];
export type Department = Schemas['Department'];
export type Category = Schemas['Category'];
export type Role = Schemas['Role'];
export type Priority = Schemas['Priority'];

/** Ошибки полей из 422 validation_error: details.fields[{field, message}] → {поле: текст}. */
export function fieldErrors(e: unknown): Record<string, string> {
  if (!(e instanceof ApiError) || e.code !== 'validation_error') return {};
  const fields = (e.details?.fields as { field: string; message: string }[] | undefined) ?? [];
  return Object.fromEntries(fields.map((f) => [f.field.replace(/^body\./, ''), f.message]));
}

/** id из <select>: пустая строка — «не выбрано» (null). */
export const idOrNull = (value: string): number | null => (value ? Number(value) : null);

/** Только изменённые поля — PATCH не трогает остальное. */
export function changes<T extends Record<string, unknown>>(before: T, after: T): Partial<T> {
  const diff: Partial<T> = {};
  for (const key of Object.keys(after) as (keyof T)[]) {
    if (after[key] !== before[key]) diff[key] = after[key];
  }
  return diff;
}

/** Кого можно назначить ответственным: действующие сотрудники, кроме администратора (контракт reassign). */
export const assignable = (users: User[]) => users.filter((u) => !u.is_disabled && u.role !== 'admin');

export const byName = <T extends { full_name?: string; name?: string }>(a: T, b: T) =>
  (a.full_name ?? a.name ?? '').localeCompare(b.full_name ?? b.name ?? '', 'ru');
