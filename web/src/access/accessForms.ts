import type { Schemas } from '../api/types';

type AssignableRole = Schemas['AssignableRole'];

/** Роли, которые можно выдать по заявке или приглашению. Собственника — нельзя (SPEC, «Регистрация и приглашения»). */
export const ASSIGNABLE_ROLES: AssignableRole[] = ['employee', 'head', 'admin'];

export interface ApproveForm {
  role: AssignableRole;
  departmentId: string;
}

/** Решение по заявке: по умолчанию «сотрудник» и подразделение из заявки (история 72). */
export function approveDefaults(r: Schemas['AccessRequest']): ApproveForm {
  return { role: 'employee', departmentId: r.department ? String(r.department.id) : '' };
}

export function approveBody(f: ApproveForm): Schemas['AccessRequestApprove'] {
  return { role: f.role, department_id: f.departmentId ? Number(f.departmentId) : null };
}

export interface InviteForm {
  role: AssignableRole;
  departmentId: string;
  fullName: string;
  days: string;
  uses: string;
}

export const INVITE_DEFAULTS: InviteForm = { role: 'employee', departmentId: '', fullName: '', days: '7', uses: '1' };

/** Срок 1–30 дней, использований 1–100 (контракт B-18). Возвращает текст ошибки или null. */
export function inviteFormError(f: InviteForm): string | null {
  const days = Number(f.days);
  const uses = Number(f.uses);
  if (!Number.isInteger(days) || days < 1 || days > 30) return 'Срок действия: от 1 до 30 дней.';
  if (!Number.isInteger(uses) || uses < 1 || uses > 100) return 'Число использований: от 1 до 100.';
  return null;
}

export function inviteBody(f: InviteForm): Schemas['InviteCreate'] {
  return {
    role: f.role,
    department_id: f.departmentId ? Number(f.departmentId) : null,
    full_name: f.fullName.trim() || null,
    expires_in_days: Number(f.days),
    max_uses: Number(f.uses),
  };
}

export const INVITE_STATE_LABEL: Record<Schemas['InviteState'], string> = {
  active: 'Действует',
  expired: 'Истекло',
  revoked: 'Отозвано',
  exhausted: 'Использовано',
};
