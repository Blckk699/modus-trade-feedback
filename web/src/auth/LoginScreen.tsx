import { AuthFrame } from './AuthFrame';
import { useAuth } from './AuthProvider';
import { authMethods } from './methods';

export function LoginScreen() {
  const { state, acceptSession, failLogin, needAccess } = useAuth();
  const notice = state.status === 'anonymous' ? state.notice : undefined;
  const methods = authMethods.filter((m) => m.LoginButton && m.isAvailable());

  return (
    <AuthFrame title="Вход" lead="Обращения и предложения сотрудников Модус Трейд. Войдите через Telegram.">
      {notice && (
        <div className="notice notice--danger" role="alert">
          {notice}
        </div>
      )}
      {methods.length === 0 && <p className="error-text">Вход не настроен: не указан бот для Telegram Login.</p>}
      {methods.map((m) => {
        const Button = m.LoginButton!;
        return <Button key={m.id} onSession={acceptSession} onError={failLogin} onUnregistered={needAccess} />;
      })}
    </AuthFrame>
  );
}
