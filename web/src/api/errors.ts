import type { ApiErrorBody, ErrorCode } from './types';

/** Ошибка API в формате контракта. message можно показывать пользователю, ветвиться — по code. */
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: ErrorCode | 'network_error',
    message: string,
    public readonly details: Record<string, unknown> | null = null,
  ) {
    super(message);
  }
}

export function toApiError(status: number, body: unknown): ApiError {
  const err = (body as ApiErrorBody | undefined)?.error;
  if (err?.code) return new ApiError(status, err.code, err.message, err.details ?? null);
  return new ApiError(status, 'internal_error', 'Сервер ответил ошибкой. Попробуйте ещё раз.');
}

export function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  return 'Не удалось связаться с сервером. Проверьте подключение.';
}
