import type { Me, Schemas } from '../api/types';

export type Scope = Schemas['AppealScope'];
export type Status = Schemas['AppealStatus'];

/** Статусы, в которых обращение ещё в работе. */
export const OPEN_STATUSES: Status[] = ['new', 'in_review', 'awaiting_info', 'in_progress'];

export const SCOPE_LABEL: Record<Scope, string> = {
  assigned: 'Назначенные мне',
  department: 'Подразделение',
  all: 'Все',
  unassigned: 'Без ответственного',
  mine: 'Мои',
};

/** Охваты очереди только по Me.permissions. */
export function queueScopes(me: Me): Scope[] {
  const p = me.permissions;
  const list: Scope[] = [];
  if (p.can_view_department) list.push('department');
  if (p.can_view_all_appeals) list.push('all');
  if (p.can_view_unassigned) list.push('unassigned');
  if (p.can_process_appeals) list.push('assigned');
  return list;
}

/** Стартовый охват — самый широкий, с которым роль работает. */
export function defaultScope(me: Me): Scope | undefined {
  const scopes = queueScopes(me);
  const preferred: Scope[] =
    me.role === 'owner' ? ['all'] : me.role === 'head' ? ['department'] : me.role === 'admin' ? ['unassigned'] : ['assigned'];
  return preferred.find((s) => scopes.includes(s)) ?? scopes[0];
}
