import { describe, expect, it } from 'vitest';
import type { Schemas } from '../api/types';
import {
  approveBody,
  approveDefaults,
  ASSIGNABLE_ROLES,
  INVITE_DEFAULTS,
  inviteBody,
  inviteFormError,
} from './accessForms';
import { accessRequestBody, accessView } from './accessView';
import { sessionFromAccepted } from './InvitePage';

const request: Schemas['AccessRequest'] = {
  id: 7,
  status: 'rejected',
  full_name: 'Новый Сотрудник',
  telegram_username: 'newbie',
  department: { id: 1, name: 'Закупки' },
  comment: 'Менеджер',
  created_at: '2026-11-11T10:00:00+05:00',
  updated_at: '2026-11-11T10:00:00+05:00',
  assigned_role: null,
  assigned_department: null,
  decided_by: null,
  decided_at: null,
  reject_reason: 'Не наш сотрудник',
  user_id: null,
};

describe('экран заявки на доступ (история 71)', () => {
  it('нет заявки — форма', () => {
    expect(accessView({ state: 'none', request: null })).toEqual({ kind: 'form', rejectReason: null, draft: null });
  });

  it('на рассмотрении — статус заявки', () => {
    const v = accessView({ state: 'pending', request: { ...request, status: 'pending', reject_reason: null } });
    expect(v.kind).toBe('pending');
  });

  it('отклонена — форма с причиной и прошлыми данными, можно подать снова', () => {
    expect(accessView({ state: 'rejected', request })).toEqual({
      kind: 'form',
      rejectReason: 'Не наш сотрудник',
      draft: { fullName: 'Новый Сотрудник', departmentId: '1', comment: 'Менеджер' },
    });
  });

  it('одобрена — войти; отключён — сообщение', () => {
    expect(accessView({ state: 'registered', request: null })).toEqual({ kind: 'registered' });
    expect(accessView({ state: 'disabled', request: null })).toEqual({ kind: 'disabled' });
  });

  it('тело заявки несёт подписанные данные Telegram и поля формы', () => {
    const login = { id: 1, first_name: 'Н', auth_date: 1, hash: 'h' };
    expect(
      accessRequestBody({ telegram_login: login }, { fullName: ' Новый ', departmentId: '', comment: ' ' }, 'newbie'),
    ).toEqual({ telegram_login: login, full_name: 'Новый', department_id: null, comment: null, telegram_username: 'newbie' });
  });
});

describe('одобрение заявок и приглашения (истории 72–74)', () => {
  it('собственника выдать нельзя', () => {
    expect(ASSIGNABLE_ROLES).not.toContain('owner');
  });

  it('по умолчанию — сотрудник и подразделение из заявки', () => {
    const f = approveDefaults(request);
    expect(f).toEqual({ role: 'employee', departmentId: '1' });
    expect(approveBody({ ...f, role: 'head' })).toEqual({ role: 'head', department_id: 1 });
  });

  it('приглашение: 7 дней и 1 использование по умолчанию, границы проверяются', () => {
    expect(inviteFormError(INVITE_DEFAULTS)).toBeNull();
    expect(inviteBody(INVITE_DEFAULTS)).toEqual({
      role: 'employee',
      department_id: null,
      full_name: null,
      expires_in_days: 7,
      max_uses: 1,
    });
    expect(inviteFormError({ ...INVITE_DEFAULTS, days: '31' })).toMatch(/30 дней/);
    expect(inviteFormError({ ...INVITE_DEFAULTS, uses: '0' })).toMatch(/100/);
  });

  it('принятое приглашение даёт сессию в форме входа; без сессии — null', () => {
    const user = { id: 9 } as Schemas['Me'];
    const session = { access_token: 't', token_type: 'bearer' as const, expires_at: '2026-12-01T00:00:00+05:00' };
    expect(sessionFromAccepted({ created: true, user, session })).toEqual({ ...session, user });
    expect(sessionFromAccepted({ created: false, user, session: null })).toBeNull();
  });
});
