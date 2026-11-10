import { describe, expect, it } from 'vitest';
import type { Me, Permissions } from '../api/types';
import { buildNav, startPath } from './navigation';

const none: Permissions = {
  can_create_appeal: true,
  can_process_appeals: false,
  can_view_department: false,
  can_view_all_appeals: false,
  analytics_scope: 'none',
  can_upload_meetings: false,
  can_manage_settings: false,
  can_view_unassigned: false,
};

function me(role: Me['role'], permissions: Partial<Permissions>): Me {
  return {
    id: 1,
    telegram_id: null,
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
  it('сотрудник видит свои обращения и ленту', () => {
    const m = me('employee', {});
    expect(ids(m)).toEqual(['my', 'feed']);
    expect(startPath(m)).toBe('/my');
  });

  it('сотрудник-ответственный видит ещё обработку, но стартует со своих', () => {
    const m = me('employee', { can_process_appeals: true });
    expect(ids(m)).toEqual(['my', 'feed', 'queue']);
    expect(startPath(m)).toBe('/my');
  });

  it('руководитель видит сводку и обработку и стартует со сводки', () => {
    const m = me('head', { can_process_appeals: true, can_view_department: true, analytics_scope: 'department', can_upload_meetings: true });
    expect(ids(m)).toEqual(['my', 'feed', 'queue', 'digest', 'meetings']);
    expect(startPath(m)).toBe('/digest');
  });

  it('собственник видит сводку по компании', () => {
    const m = me('owner', { can_process_appeals: true, can_view_all_appeals: true, analytics_scope: 'company', can_upload_meetings: true, can_view_unassigned: true });
    expect(ids(m)).toContain('digest');
    expect(ids(m)).not.toContain('settings');
    expect(startPath(m)).toBe('/digest');
  });

  it('администратор видит настройки и стартует с них', () => {
    const m = me('admin', { can_manage_settings: true, can_view_all_appeals: true, can_view_unassigned: true });
    expect(ids(m)).toEqual(['my', 'feed', 'queue', 'settings']);
    expect(startPath(m)).toBe('/settings');
  });
});
