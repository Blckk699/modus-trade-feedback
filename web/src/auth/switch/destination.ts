import type { Me, Schemas } from '../../api/types';
import { buildNav } from '../../app/navigation';

/** Связанный демо-пользователь, под которого можно переключиться (B-22): id, имя, роль, подразделение. */
export type SwitchTarget = Schemas['UserBrief'];

/** Куда вести после переключения и что оставить под открытой карточкой. */
export interface Destination {
  /** Адрес после переключения. */
  to: string;
  /** Экран под карточкой (state.background) или null, если карточка не поверх экрана. */
  background: string | null;
}

const APPEAL = /^\/appeals\/(\d+)$/;
const DISCUSSION = /^\/discussions\/\d+$/;
const MEETING = /^\/meetings\/\d+$/;

/** id обращения, если открыта его карточка: перед переключением проверяем, видна ли она новой роли. */
export function openAppealId(pathname: string): number | null {
  const m = APPEAL.exec(pathname);
  return m ? Number(m[1]) : null;
}

/**
 * Что показать новой роли (W-14): открытая карточка обращения остаётся, если она ей видна, иначе — «Сегодня».
 * Экран, которого у роли нет в навигации (настройки у сотрудника), тоже сменяется на «Сегодня».
 * Экран под карточкой, недоступный новой роли, заменяется на «Сегодня», а карточка остаётся.
 */
export function switchDestination(
  at: { pathname: string; search: string; backgroundPath: string | null },
  next: Me,
  appealVisible: boolean,
): Destination {
  const pages = new Set(buildNav(next).map((n) => n.path).concat('/profile'));
  const home: Destination = { to: '/', background: null };
  const here = at.pathname + at.search;

  const isAppeal = APPEAL.test(at.pathname);
  const isCard = isAppeal || DISCUSSION.test(at.pathname) || MEETING.test(at.pathname);
  if (isCard) {
    if (isAppeal && !appealVisible) return home;
    if (MEETING.test(at.pathname) && !next.permissions.can_upload_meetings) return home;
    if (at.backgroundPath === null) return { to: here, background: null };
    return { to: here, background: pages.has(at.backgroundPath) ? at.backgroundPath : '/' };
  }
  return pages.has(at.pathname) ? { to: here, background: null } : home;
}

/** Строка под именем: «Руководитель · Закупки». */
export function targetCaption(t: Pick<SwitchTarget, 'department'>, roleLabel: string): string {
  return t.department ? `${roleLabel} · ${t.department.name}` : roleLabel;
}
