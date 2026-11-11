import type { Schemas } from '../api/types';

type AccessStatus = Schemas['AccessStatus'];

/** Что показать незнакомому аккаунту по ответу POST /access-requests/mine (история 71). */
export type AccessView =
  | { kind: 'form'; rejectReason: string | null; draft: Draft | null }
  | { kind: 'pending'; request: Schemas['AccessRequest'] }
  | { kind: 'registered' }
  | { kind: 'disabled' };

export interface Draft {
  fullName: string;
  departmentId: string;
  comment: string;
}

export function accessView(status: AccessStatus): AccessView {
  switch (status.state) {
    case 'pending':
      if (status.request) return { kind: 'pending', request: status.request };
      return { kind: 'form', rejectReason: null, draft: null };
    case 'rejected':
      // После отказа можно подать снова: форма заполнена прошлой заявкой, причина показана сверху.
      return {
        kind: 'form',
        rejectReason: status.request?.reject_reason ?? null,
        draft: status.request ? draftFrom(status.request) : null,
      };
    case 'registered':
      return { kind: 'registered' };
    case 'disabled':
      return { kind: 'disabled' };
    default:
      return { kind: 'form', rejectReason: null, draft: null };
  }
}

export function draftFrom(r: Schemas['AccessRequest']): Draft {
  return { fullName: r.full_name, departmentId: r.department ? String(r.department.id) : '', comment: r.comment ?? '' };
}

/** Тело POST /access-requests: подписанные данные Telegram + поля формы. */
export function accessRequestBody(
  identity: Schemas['TelegramIdentity'],
  draft: Draft,
  username: string | null,
): Schemas['AccessRequestSubmit'] {
  return {
    ...identity,
    full_name: draft.fullName.trim(),
    department_id: draft.departmentId ? Number(draft.departmentId) : null,
    comment: draft.comment.trim() || null,
    telegram_username: username,
  };
}
