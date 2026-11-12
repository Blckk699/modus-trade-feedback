import { useEffect, useState } from 'react';
import { api, unwrap } from '../../api/client';
import { ApiError, errorMessage } from '../../api/errors';
import type { UserBrief } from '../../api/types';
import { config } from '../../config';
import { Avatar } from '../../app/Avatar';
import { useDictionaries } from '../../app/dictionaries';
import type { AuthMethod, LoginButtonProps } from '../types';

function DevLoginButton({ onSession, onError }: LoginButtonProps) {
  const dict = useDictionaries();
  const [users, setUsers] = useState<UserBrief[] | null>(null);
  const [state, setState] = useState<'loading' | 'ready' | 'disabled' | 'error'>('loading');
  const [loadError, setLoadError] = useState('');
  const [busyId, setBusyId] = useState<number | null>(null);

  useEffect(() => {
    unwrap(api.GET('/api/v1/auth/dev/users'))
      .then((list) => {
        setUsers(list);
        setState('ready');
      })
      .catch((e) => {
        if (e instanceof ApiError && e.code === 'dev_login_disabled') setState('disabled');
        else {
          setLoadError(errorMessage(e));
          setState('error');
        }
      });
  }, []);

  if (state === 'disabled') return null;

  async function login(userId: number) {
    setBusyId(userId);
    try {
      onSession(await unwrap(api.POST('/api/v1/auth/dev/login', { body: { user_id: userId } })));
    } catch (e) {
      onError(e);
    } finally {
      setBusyId(null);
    }
  }

  return (
    <section className="dev-login" aria-labelledby="dev-login-title">
      <div className="dev-login__head">
        <h2 id="dev-login-title" className="dev-login__title">
          Вход для разработки
        </h2>
        <span className="badge">только на стенде</span>
      </div>
      {state === 'loading' && <p className="muted">Загружаем пользователей…</p>}
      {state === 'error' && <p className="error-text">{loadError}</p>}
      {users && (
        <ul className="dev-login__list">
          {users.map((u) => (
            <li key={u.id}>
              <button type="button" className="dev-login__user" disabled={busyId !== null} onClick={() => login(u.id)}>
                <Avatar name={u.full_name} size="sm" />
                <span className="dev-login__text">
                  <span className="dev-login__name">{u.full_name}</span>
                  <span className="dev-login__role">
                    {dict.roleLabel(u.role)}
                    {u.department ? ` · ${u.department.name}` : ''}
                  </span>
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

export const devLoginMethod: AuthMethod = {
  id: 'dev',
  isAvailable: () => config.devLogin,
  LoginButton: DevLoginButton,
};
