import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { api, unwrap } from '../api/client';
import { ApiError, errorMessage } from '../api/errors';
import type { Schemas, Session } from '../api/types';
import { useDictionaries } from '../app/dictionaries';
import { useAuth, type TelegramIdentity } from '../auth';
import { AuthFrame } from '../auth/AuthFrame';
import { RegisterFields } from '../auth/RegisterScreen';
import { TelegramWidget, telegramLoginConfigured, unregisteredFromWidget } from '../auth/methods/telegramWidget';
import { formatDateTime } from '../lib/format';
import { useAsync } from '../lib/useAsync';
import { getWebApp } from '../telegram/webApp';

/** Сессия из ответа POST /invites/accept в форму, которую принимает AuthProvider. */
export function sessionFromAccepted(a: Schemas['InviteAccepted']): Session | null {
  return a.session ? { ...a.session, user: a.user } : null;
}

/**
 * Ссылка-приглашение https://<домен>/invite/<токен> (история 73): показать, куда приглашают,
 * войти через Telegram и принять приглашение. Недействительное — сообщение и путь к заявке.
 */
export function InvitePage() {
  const token = useParams().token ?? '';
  const navigate = useNavigate();
  const dict = useDictionaries();
  const { state, acceptSession, needAccess } = useAuth();
  const preview = useAsync(() => unwrap(api.GET('/api/v1/invites/{token}', { params: { path: { token } } })), [token]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [way, setWay] = useState<'email' | 'telegram'>('email');
  const webApp = getWebApp();

  async function accept(identity: TelegramIdentity, onInvalid?: () => void) {
    setBusy(true);
    setError('');
    try {
      const res = await unwrap(api.POST('/api/v1/invites/accept', { body: { token, ...identity } }));
      const session = sessionFromAccepted(res);
      if (session) acceptSession(session);
      navigate('/', { replace: true });
    } catch (e) {
      if (e instanceof ApiError && e.code === 'invite_invalid') {
        preview.reload();
        onInvalid?.();
      } else setError(errorMessage(e));
      setBusy(false);
    }
  }

  const p = preview.state;
  const invalid = p.status === 'error' && p.error instanceof ApiError && p.error.status === 410;

  return (
    <AuthFrame title="Приглашение">

        {state.status === 'authenticated' && (
          <>
            <p>Вы уже вошли как {state.me.full_name}. Приглашение не нужно.</p>
            <Link to="/" className="btn">
              Открыть приложение
            </Link>
          </>
        )}

        {state.status !== 'authenticated' && p.status === 'loading' && <p className="muted">Проверяем приглашение…</p>}

        {state.status !== 'authenticated' && invalid && (
          <>
            <div className="notice notice--danger">Приглашение не действует: срок истёк, его отозвали или им уже воспользовались.</div>
            <p className="muted">Войдите через Telegram и оставьте заявку на доступ.</p>
            {webApp ? (
              <button
                type="button"
                className="btn"
                onClick={() => navigate('/', { replace: true })}
              >
                Подать заявку
              </button>
            ) : (
              telegramLoginConfigured() && (
                <TelegramWidget
                  onUser={(user) => {
                    // Незнакомому — сразу заявка; уже заведённый просто войдёт.
                    unwrap(api.POST('/api/v1/auth/telegram/widget', { body: user }))
                      .then((s) => {
                        acceptSession(s);
                        navigate('/', { replace: true });
                      })
                      .catch((e) => {
                        if (e instanceof ApiError && e.code === 'user_not_registered') {
                          needAccess(unregisteredFromWidget(user));
                          navigate('/', { replace: true });
                        } else setError(errorMessage(e));
                      });
                  }}
                />
              )
            )}
          </>
        )}

        {state.status !== 'authenticated' && p.status === 'error' && !invalid && (
          <>
            <p className="error-text">{p.message}</p>
            <button type="button" className="btn btn--soft" onClick={preview.reload}>
              Повторить
            </button>
          </>
        )}

        {state.status !== 'authenticated' && p.status === 'ready' && (
          <>
            <p>Вас приглашают в систему обращений «Модус Трейд».</p>
            <dl className="facts facts--flat">
              {p.data.full_name && (
                <>
                  <dt>Для</dt>
                  <dd>{p.data.full_name}</dd>
                </>
              )}
              <dt>Роль</dt>
              <dd>{dict.roleLabel(p.data.role)}</dd>
              <dt>Подразделение</dt>
              <dd>{p.data.department?.name ?? 'Не указано'}</dd>
              <dt>Действует до</dt>
              <dd>{formatDateTime(p.data.expires_at)}</dd>
            </dl>
            {webApp ? (
              <button
                type="button"
                className="btn"
                disabled={busy}
                onClick={() => accept({ init_data: webApp.initData })}
              >
                {busy ? 'Принимаем…' : 'Принять приглашение'}
              </button>
            ) : (
              <>
                {/* В браузере приглашение принимают по почте или через Telegram (SPEC, «Приглашение по почте»). */}
                {telegramLoginConfigured() && (
                  <div className="segmented" role="radiogroup" aria-label="Как принять приглашение">
                    <label className="segmented__item">
                      <input type="radio" name="invite-way" checked={way === 'email'} onChange={() => setWay('email')} />
                      <span>По почте</span>
                    </label>
                    <label className="segmented__item">
                      <input type="radio" name="invite-way" checked={way === 'telegram'} onChange={() => setWay('telegram')} />
                      <span>Через Telegram</span>
                    </label>
                  </div>
                )}
                {way === 'email' || !telegramLoginConfigured() ? (
                  <RegisterFields
                    inviteToken={token}
                    suggestedName={p.data.full_name ?? ''}
                    submitLabel="Зарегистрироваться и войти"
                    onSession={(session) => {
                      acceptSession(session);
                      navigate('/', { replace: true });
                    }}
                  />
                ) : busy ? (
                  <p className="muted">Принимаем приглашение…</p>
                ) : (
                  <>
                    <p className="muted">Войдите через Telegram, чтобы принять приглашение.</p>
                    <TelegramWidget onUser={(user) => accept({ telegram_login: user })} />
                  </>
                )}
              </>
            )}
          </>
        )}

        {error && (
          <p className="error-text" role="alert">
            {error}
          </p>
        )}
    </AuthFrame>
  );
}
