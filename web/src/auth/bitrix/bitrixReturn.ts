import { ApiError, errorMessage } from '../../api/errors';
import { loginProblem } from '../email/forms';

/** Адрес веба, на который бэкенд возвращает пользователя после портала Битрикс24 (B-23). */
export const BITRIX_DONE_PATH = '/auth/bitrix/done';

/**
 * Чем закончился вход через портал. Бэкенд возвращает на BITRIX_DONE_PATH с ?code=<одноразовый код обмена>
 * или ?error=<код отказа> (контракт B-23). Фрагмент (#…) тоже читаем и ставим в приоритет: если бэкенд
 * перейдёт на него, код не попадёт в журналы сервера, а вебу ничего менять не придётся.
 */
export type BitrixOutcome =
  | { kind: 'code'; code: string }
  | { kind: 'token'; token: string }
  | { kind: 'pending' }
  | { kind: 'rejected'; reason: string | null }
  | { kind: 'disabled' }
  | { kind: 'cancelled' }
  | { kind: 'error'; message: string | null };

/** Отказы, которые экран объясняет отдельно. Остальные коды — общая ошибка. */
const REFUSALS: Record<string, BitrixOutcome['kind']> = {
  access_request_pending: 'pending',
  pending: 'pending',
  access_request_rejected: 'rejected',
  rejected: 'rejected',
  user_disabled: 'disabled',
  disabled: 'disabled',
  // OAuth: пользователь нажал «Отменить» на портале.
  access_denied: 'cancelled',
  cancelled: 'cancelled',
  canceled: 'cancelled',
};

const clean = (v: string | null) => (v && v.trim() ? v.trim() : null);

export function parseBitrixReturn(search: string, hash: string): BitrixOutcome {
  const fromHash = new URLSearchParams(hash.replace(/^#/, ''));
  const fromQuery = new URLSearchParams(search.replace(/^\?/, ''));
  const get = (k: string) => clean(fromHash.get(k)) ?? clean(fromQuery.get(k));

  const token = get('access_token');
  if (token) return { kind: 'token', token };
  const code = get('code');
  const refusal = get('error') ?? get('status');
  if (code && !refusal) return { kind: 'code', code };

  const kind = refusal ? REFUSALS[refusal] : undefined;
  if (kind === 'pending' || kind === 'disabled' || kind === 'cancelled') return { kind };
  if (kind === 'rejected') return { kind, reason: get('reason') };
  return { kind: 'error', message: get('message') ?? get('error_description') ?? (refusal ? ERROR_TEXT[refusal] ?? null : null) };
}

/** Коды ошибок возврата, у которых сервер не передаёт текст в адресе. */
const ERROR_TEXT: Record<string, string> = {
  invalid_bitrix_auth: 'Не удалось подтвердить вход через Битрикс24: ссылка устарела или вход начат в другом браузере. Попробуйте ещё раз.',
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
