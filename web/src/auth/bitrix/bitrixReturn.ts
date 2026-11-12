import { ApiError, errorMessage } from '../../api/errors';
import { loginProblem } from '../email/forms';

/** Адрес веба, на который бэкенд возвращает пользователя после портала Битрикс24 (B-23). */
export const BITRIX_DONE_PATH = '/auth/bitrix/done';

/**
 * Чем закончился вход через портал. Бэкенд возвращает на BITRIX_DONE_PATH с ?code=<одноразовый код обмена>
 * или ?error=<код отказа> (контракт B-23). Из адреса берём только эти два параметра:
 * - сессию даёт лишь обмен code через POST /auth/bitrix/exchange, токен из адреса не принимается никогда,
 *   иначе ссылкой с чужим токеном жертву молча впустили бы в чужой аккаунт;
 * - текст на экране — только наш, по известному коду error. message, error_description и reason из адреса
 *   не выводим: это произвольный текст на нашем домене. Причину отказа показываем только из ответа обмена.
 */
export type BitrixOutcome =
  | { kind: 'code'; code: string }
  | { kind: 'pending' }
  | { kind: 'rejected'; reason: string | null }
  | { kind: 'disabled' }
  | { kind: 'cancelled' }
  | { kind: 'error'; message: string | null };

/** Отказы, которые экран объясняет отдельно. Остальные коды — общая ошибка. */
const REFUSALS: Record<string, BitrixOutcome['kind']> = {
  access_request_pending: 'pending',
  access_request_rejected: 'rejected',
  user_disabled: 'disabled',
  // OAuth: пользователь нажал «Отменить» на портале.
  access_denied: 'cancelled',
};

const clean = (v: string | null) => (v && v.trim() ? v.trim() : null);

export function parseBitrixReturn(search: string): BitrixOutcome {
  const params = new URLSearchParams(search.replace(/^\?/, ''));
  const code = clean(params.get('code'));
  const error = clean(params.get('error'));
  if (code && !error) return { kind: 'code', code };

  const kind = error ? REFUSALS[error] : undefined;
  if (kind === 'pending' || kind === 'disabled' || kind === 'cancelled') return { kind };
  if (kind === 'rejected') return { kind, reason: null };
  return { kind: 'error', message: (error && ERROR_TEXT[error]) || null };
}

/** Свои тексты для известных кодов ошибки возврата. Незнакомый код — общий текст экрана. */
const ERROR_TEXT: Record<string, string> = {
  // Так же отвечает и администратору или собственнику без привязанного bitrix_user_id: их по почте не сопоставляют.
  invalid_bitrix_auth:
    'Для этой учётной записи вход через Битрикс24 не настроен. Войдите по почте или через Telegram. Если вход начат давно или в другом браузере, попробуйте ещё раз.',
  bitrix_unavailable: 'Портал Битрикс24 не ответил. Попробуйте позже или войдите по почте.',
};

/** Ответ обмена кода на сессию: те же отказы, что у входа по почте, остальное — ошибка с текстом сервера. */
export function outcomeOfExchangeError(e: unknown): BitrixOutcome {
  const p = loginProblem(e);
  if (p.kind === 'pending' || p.kind === 'disabled') return { kind: p.kind };
  if (p.kind === 'rejected') return { kind: 'rejected', reason: p.reason };
  return { kind: 'error', message: e instanceof ApiError ? e.message : errorMessage(e) };
}

/**
 * Куда вернуть после входа. Только свой путь: «/…», без «//» и «/\» (иначе это чужой хост)
 * и не сам экран возврата.
 */
export function safeReturnTo(path: string | null | undefined): string | null {
  if (!path || !path.startsWith('/') || path.startsWith('//') || path.startsWith('/\\')) return null;
  if (path === '/' || path.startsWith(BITRIX_DONE_PATH) || path.startsWith('/register')) return null;
  return path;
}

const RETURN_KEY = 'modus.bitrix.return_to';

/** Исходный адрес держим во вкладке, пока пользователь на портале: бэкенду его знать не нужно. */
export const returnToStore = {
  save(path: string) {
    const safe = safeReturnTo(path);
    try {
      if (safe) window.sessionStorage.setItem(RETURN_KEY, safe);
      else window.sessionStorage.removeItem(RETURN_KEY);
    } catch {
      /* без хранилища вернёмся на «Сегодня» */
    }
  },
  /** Прочитать и забыть. */
  take(): string | null {
    try {
      const v = window.sessionStorage.getItem(RETURN_KEY);
      window.sessionStorage.removeItem(RETURN_KEY);
      return safeReturnTo(v);
    } catch {
      return null;
    }
  },
};
