import { describe, expect, it } from 'vitest';
import type { Me, Permissions } from '../../api/types';
import { openAppealId, switchDestination, targetCaption } from './destination';

const NONE: Permissions = {
  can_create_appeal: false,
  can_process_appeals: false,
  can_view_department: false,
  can_view_all_appeals: false,
  can_view_unassigned: false,
  can_manage_settings: false,
  can_manage_access: false,
  can_upload_meetings: false,
  analytics_scope: 'none',
};

function me(role: Me['role'], permissions: Partial<Permissions>): Me {
  return {
    id: 1,
    telegram_id: null,
    email: null,
    has_password: false,
    telegram_linked: false,
    switch_targets: [],
    full_name: 'Тест',
    position: null,
    role,
    department: null,
    is_absent: false,
    is_disabled: false,
    responsible_for: [],
    deputy_for: [],
    assigned_open_count: 0,
    permissions: { ...NONE, ...permissions },
  };
}

const employee = me('employee', { can_create_appeal: true });
const head = me('head', { can_create_appeal: true, can_process_appeals: true, can_view_department: true, analytics_scope: 'department', can_upload_meetings: true });
const admin = me('admin', { can_view_all_appeals: true, can_view_unassigned: true, can_manage_settings: true, can_manage_access: true });

const at = (pathname: string, backgroundPath: string | null = null, search = '') => ({ pathname, search, backgroundPath });

describe('куда вести после смены роли (W-14)', () => {
  it('карточка обращения остаётся, если новой роли она видна', () => {
    expect(switchDestination(at('/appeals/28'), head, true)).toEqual({ to: '/appeals/28', background: null });
  });

  it('карточка не видна новой роли — «Сегодня»', () => {
    expect(switchDestination(at('/appeals/28', '/queue'), employee, false)).toEqual({ to: '/', background: null });
  });

  it('экран под карточкой недоступен новой роли — карточка остаётся, под ней «Сегодня»', () => {
    // руководитель открыл обращение из «Входящих», переключился на автора-сотрудника: «Входящих» у него нет
    expect(switchDestination(at('/appeals/28', '/queue'), employee, true)).toEqual({ to: '/appeals/28', background: '/' });
    expect(switchDestination(at('/appeals/28', '/my'), employee, true)).toEqual({ to: '/appeals/28', background: '/my' });
  });

  it('обычный экран остаётся, если он есть у новой роли, фильтры в адресе сохраняются', () => {
    expect(switchDestination(at('/queue', null, '?scope=assigned'), admin, false)).toEqual({ to: '/queue?scope=assigned', background: null });
    expect(switchDestination(at('/profile'), employee, false)).toEqual({ to: '/profile', background: null });
  });

  it('экрана у новой роли нет — «Сегодня»', () => {
    expect(switchDestination(at('/settings'), employee, false)).toEqual({ to: '/', background: null });
    expect(switchDestination(at('/meetings'), admin, false)).toEqual({ to: '/', background: null });
  });

  it('совещание видно только тем, кто их загружает; обсуждение — всем', () => {
    expect(switchDestination(at('/meetings/3', '/meetings'), employee, false)).toEqual({ to: '/', background: null });
    expect(switchDestination(at('/discussions/1', '/feed'), employee, false)).toEqual({ to: '/discussions/1', background: '/feed' });
  });
});

describe('вспомогательное', () => {
  it('id обращения из адреса карточки', () => {
    expect(openAppealId('/appeals/28')).toBe(28);
    expect(openAppealId('/appeals/new')).toBeNull();
    expect(openAppealId('/queue')).toBeNull();
  });

  it('подпись под именем: роль и подразделение', () => {
    expect(targetCaption({ department: { id: 1, name: 'Закупки' } }, 'Руководитель')).toBe('Руководитель · Закупки');
    expect(targetCaption({ department: null }, 'Собственник')).toBe('Собственник');
  });
});
