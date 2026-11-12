import { describe, expect, it } from 'vitest';
import type { Me, Permissions } from '../api/types';
import { buildNav, splitForTabbar, startPath } from './navigation';

const none: Permissions = {
  can_create_appeal: true,
  can_process_appeals: false,
  can_view_department: false,
  can_view_all_appeals: false,
  analytics_scope: 'none',
  can_upload_meetings: false,
  can_manage_settings: false,
  can_manage_access: false,
  can_view_unassigned: false,
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
    permissions: { ...none, ...permissions },
  };
}

const ids = (m: Me) => buildNav(m).map((n) => n.id);

describe('навигация по Me.permissions (истории 23, 24)', () => {
  it('сотрудник видит «Сегодня», свои обращения и ленту', () => {
    const m = me('employee', {});
    expect(ids(m)).toEqual(['home', 'my', 'feed']);
    expect(startPath(m)).toBe('/');
  });

  it('сотрудник-ответственный видит ещё входящие', () => {
    const m = me('employee', { can_process_appeals: true });
    expect(ids(m)).toEqual(['home', 'my', 'queue', 'feed']);
  });

  it('руководитель видит сводку, входящие и совещания', () => {
    const m = me('head', { can_process_appeals: true, can_view_department: true, analytics_scope: 'department', can_upload_meetings: true });
    expect(ids(m)).toEqual(['home', 'my', 'queue', 'feed', 'digest', 'meetings']);
  });

  it('собственник видит сводку по компании', () => {
    const m = me('owner', { can_process_appeals: true, can_view_all_appeals: true, analytics_scope: 'company', can_upload_meetings: true, can_view_unassigned: true });
    expect(ids(m)).toContain('digest');
    expect(ids(m)).not.toContain('settings');
  });

  it('администратор видит настройки', () => {
    const m = me('admin', { can_manage_settings: true, can_view_all_appeals: true, can_view_unassigned: true });
    expect(ids(m)).toEqual(['home', 'my', 'queue', 'feed', 'settings']);
  });

  it('все роли стартуют с «Сегодня»', () => {
    expect(startPath(me('owner', { analytics_scope: 'company' }))).toBe('/');
    expect(startPath(me('admin', { can_manage_settings: true }))).toBe('/');
  });
});

describe('нижняя панель на телефоне', () => {
  const head = buildNav(
    me('head', { can_process_appeals: true, can_view_department: true, analytics_scope: 'department', can_upload_meetings: true }),
  );

  it('пять разделов и меньше помещаются целиком', () => {
    const nav = buildNav(me('employee', { can_process_appeals: true }));
    expect(splitForTabbar(nav)).toEqual({ main: nav, more: [] });
  });

  it('шестой и дальше уходят под «Ещё», на панели остаются четыре', () => {
    const { main, more } = splitForTabbar(head);
    expect(main.map((n) => n.id)).toEqual(['home', 'my', 'queue', 'feed']);
    expect(more.map((n) => n.id)).toEqual(['digest', 'meetings']);
  });
});
