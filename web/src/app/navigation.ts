import type { Me } from '../api/types';

export type NavId = 'my' | 'feed' | 'queue' | 'digest' | 'meetings' | 'settings';

export interface NavItem {
  id: NavId;
  path: string;
  label: string;
  /** Короткая подпись для нижней панели на телефоне. */
  short: string;
}

const ITEMS: Record<NavId, NavItem> = {
  my: { id: 'my', path: '/my', label: 'Мои обращения', short: 'Мои' },
  feed: { id: 'feed', path: '/feed', label: 'Лента реализованного', short: 'Лента' },
  queue: { id: 'queue', path: '/queue', label: 'Обработка', short: 'Обработка' },
  digest: { id: 'digest', path: '/digest', label: 'Сводка', short: 'Сводка' },
  meetings: { id: 'meetings', path: '/meetings', label: 'Совещания', short: 'Совещания' },
  settings: { id: 'settings', path: '/settings', label: 'Настройки', short: 'Настройки' },
};

/** Пункты навигации только по Me.permissions — права клиент не вычисляет. */
export function buildNav(me: Me): NavItem[] {
  const p = me.permissions;
  const ids: NavId[] = [];
  if (p.can_create_appeal) ids.push('my');
  ids.push('feed');
  if (p.can_process_appeals || p.can_view_department || p.can_view_all_appeals || p.can_view_unassigned) {
    ids.push('queue');
  }
  if (p.analytics_scope !== 'none') ids.push('digest');
  if (p.can_upload_meetings) ids.push('meetings');
  if (p.can_manage_settings) ids.push('settings');
  return ids.map((id) => ITEMS[id]);
}

/** Стартовый экран роли: собственник и руководитель — сводка, администратор — настройки, остальные — свои обращения. */
export function startPath(me: Me): string {
  const nav = buildNav(me);
  const has = (id: NavId) => nav.some((n) => n.id === id);
  const preferred: NavId[] =
    me.role === 'owner' || me.role === 'head'
      ? ['digest', 'queue', 'my']
      : me.role === 'admin'
        ? ['settings', 'queue', 'my']
        : ['my'];
  const id = preferred.find(has) ?? nav[0].id;
  return ITEMS[id].path;
}
