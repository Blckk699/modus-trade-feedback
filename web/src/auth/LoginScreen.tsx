import { useAuth } from './AuthProvider';
import { authMethods } from './methods';

export function LoginScreen() {
  const { state, acceptSession, failLogin } = useAuth();
  const notice = state.status === 'anonymous' ? state.notice : undefined;
  const methods = authMethods.filter((m) => m.LoginButton && m.isAvailable());

  return (
    <main className="login">
      <div className="login__card">
        <h1 className="login__title">Обращения и предложения</h1>
        <p className="muted">Модус Трейд. Войдите через Telegram, чтобы подать обращение или посмотреть свои.</p>
        {notice && (
          <p className="error-text" role="alert">
            {notice}
          </p>
        )}
        {methods.length === 0 && (
          <p className="error-text">Вход не настроен: не указан бот для Telegram Login.</p>
        )}
        {methods.map((m) => {
          const Button = m.LoginButton!;
          return <Button key={m.id} onSession={acceptSession} onError={failLogin} />;
        })}
      </div>
    </main>
  );
}
