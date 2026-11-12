import { useEffect, useState } from 'react';
import { useLocation, useNavigate, type Location } from 'react-router-dom';
import { api } from '../../api/client';
import { errorMessage } from '../../api/errors';
import { useDictionaries } from '../../app/dictionaries';
import { useToast } from '../../app/Toast';
import { useAuth, useMe } from '../AuthProvider';
import { openAppealId, switchDestination, type SwitchTarget } from './destination';
import { roleSwitchApi } from './switchApi';

/**
 * Демо-переключатель ролей (W-14): список связанных пользователей и смена сессии без перезахода.
 * После смены экран остаётся прежним, если он есть у новой роли; открытая карточка обращения —
 * если новой роли она видна. Данные перечитываются: вошедшая часть приложения привязана к id пользователя.
 */
export function useRoleSwitch() {
  const me = useMe();
  const { acceptSession } = useAuth();
  const dict = useDictionaries();
  const toast = useToast();
  const navigate = useNavigate();
  const location = useLocation();
  const [targets, setTargets] = useState<SwitchTarget[]>([]);
  const [busyId, setBusyId] = useState<number | null>(null);

  useEffect(() => {
    let alive = true;
    roleSwitchApi
      .targets(me)
      .then((list) => alive && setTargets(list))
      .catch(() => alive && setTargets([]));
    return () => {
      alive = false;
    };
  }, [me]);

  async function switchTo(target: SwitchTarget) {
    if (busyId !== null) return;
    setBusyId(target.id);
    try {
      const session = await roleSwitchApi.switchTo(target.id);
      const background = (location.state as { background?: Location } | null)?.background ?? null;

      // Открыта карточка обращения: спрашиваем сервер новой сессией, видна ли она этой роли.
      const appealId = openAppealId(location.pathname);
      let appealVisible = false;
      if (appealId !== null) {
        appealVisible = await api
          .GET('/api/v1/appeals/{appeal_id}', {
            params: { path: { appeal_id: appealId } },
            headers: { Authorization: `Bearer ${session.access_token}` },
          })
          .then((r) => r.response.ok)
          .catch(() => false);
      }

      const dest = switchDestination(
        { pathname: location.pathname, search: location.search, backgroundPath: background?.pathname ?? null },
        session.user,
        appealVisible,
      );
      const under =
        dest.background === null
          ? null
          : background && background.pathname === dest.background
            ? background
            : { pathname: dest.background, search: '', hash: '', state: null, key: 'role-switch' };
      // Сначала адрес, потом сессия: смена пользователя перемонтирует экран уже на нужном месте.
      navigate(dest.to, { replace: true, state: under ? { background: under } : null });
      acceptSession(session);
      toast(`Вы вошли как ${session.user.full_name}: ${dict.roleLabel(session.user.role).toLowerCase()}`);
    } catch (e) {
      toast(errorMessage(e), 'error');
    } finally {
      setBusyId(null);
    }
  }

  return { me, targets, busyId, switchTo };
}
