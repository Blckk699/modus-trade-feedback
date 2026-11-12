import { api, unwrap } from '../../api/client';
import { ApiError } from '../../api/errors';
import type { Me, Session } from '../../api/types';
import { config } from '../../config';
import type { SwitchTarget } from './destination';

/** Переключение между связанными демо-пользователями (B-22). Экран знает только этот интерфейс. */
export interface RoleSwitchApi {
  /** На кого можно переключиться. Пусто — переключателя нет. */
  targets(me: Me): Promise<SwitchTarget[]>;
  /** Сессия от имени выбранного пользователя. */
  switchTo(userId: number): Promise<Session>;
}

const httpRoleSwitch: RoleSwitchApi = {
  // До контракта B-22 поля switch_targets в Me нет: список пуст, переключатель не показывается.
  async targets(me) {
    return (me as Me & { switch_targets?: SwitchTarget[] }).switch_targets ?? [];
  },
  async switchTo() {
    throw new ApiError(404, 'not_found', 'Переключение ролей на этом сервере ещё не включено.');
  },
};

/* Мок для локальной проверки (VITE_ROLE_SWITCH_MOCK=true): по одному dev-пользователю на роль, переключение — dev-вход. */
const ROLE_ORDER: Me['role'][] = ['owner', 'admin', 'head', 'employee'];

const mockRoleSwitch: RoleSwitchApi = {
  async targets(me) {
    const users = await unwrap(api.GET('/api/v1/auth/dev/users'));
    return ROLE_ORDER.map((role) => users.find((u) => u.role === role)).filter(
      (u): u is SwitchTarget => u !== undefined && u.id !== me.id,
    );
  },
  switchTo: (userId) => unwrap(api.POST('/api/v1/auth/dev/login', { body: { user_id: userId } })),
};

export const roleSwitchApi: RoleSwitchApi = config.roleSwitchMock ? mockRoleSwitch : httpRoleSwitch;
