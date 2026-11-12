import type { Me } from '../api/types';

export type NavId = 'home' | 'my' | 'queue' | 'feed' | 'digest' | 'meetings' | 'settings';

export interface NavItem {
  id: NavId;
  path: string;
  /** Полное название: заголовок раздела и подсказка. */
  label: string;
  /** Короткая подпись под иконкой: рейка слева и нижняя панель на телефоне. */
  short: string;
}

const ITEMS: Record<NavId, NavItem> = {
  home: { id: 'home', path: '/', label: 'Сегодня', short: 'Сегодня' },
  my: { id: 'my', path: '/my', label: 'Мои обращения', short: 'Мои' },
  queue: { id: 'queue', path: '/queue', label: 'Входящие', short: 'Входящие' },
  feed: { id: 'feed', path: '/feed', label: 'Лента', short: 'Лента' },
  digest: { id: 'digest', path: '/digest', label: 'Сводка', short: 'Сводка' },
  meetings: { id: 'meetings', path: '/meetings', label: 'Совещания', short: 'Совещания' },
  settings: { id: 'settings', path: '/settings', label: 'Настройки', short: 'Настройки' },
};

/** Пункты навигации только по Me.permissions — права клиент не вычисляет. «Сегодня» есть у всех. */
export function buildNav(me: Me): NavItem[] {
  const p = me.permissions;
  const ids: NavId[] = ['home'];
  if (p.can_create_appeal) ids.push('my');
  if (p.can_process_appeals || p.can_view_department || p.can_view_all_appeals || p.can_view_unassigned) {
    ids.push('queue');
  }
  ids.push('feed');
  if (p.analytics_scope !== 'none') ids.push('digest');
  if (p.can_upload_meetings) ids.push('meetings');
  // Настройки: администратор — все вкладки, собственник — только заявки и приглашения (can_manage_access).
  if (p.can_manage_settings || p.can_manage_access) ids.push('settings');
  return ids.map((id) => ITEMS[id]);
}

/** Стартовый экран — «Сегодня»: он сам собирается под права пользователя. */
export function startPath(_me?: Me): string {
  return ITEMS.home.path;
}

/** Нижняя панель на телефоне вмещает пять пунктов: если разделов больше, лишние уходят под «Ещё». */
export function splitForTabbar(nav: NavItem[], max = 5): { main: NavItem[]; more: NavItem[] } {
  if (nav.length <= max) return { main: nav, more: [] };
  return { main: nav.slice(0, max - 1), more: nav.slice(max - 1) };
}
