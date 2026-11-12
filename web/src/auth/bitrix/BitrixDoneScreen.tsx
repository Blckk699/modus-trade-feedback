import { useEffect, useRef, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { AuthFrame } from '../AuthFrame';
import { useAuth } from '../AuthProvider';
import { bitrixAuth } from './bitrixAuth';
import { outcomeOfExchangeError, parseBitrixReturn, returnToStore, type BitrixOutcome } from './bitrixReturn';

type View = { kind: 'busy' } | Exclude<BitrixOutcome, { kind: 'code' }>;

/**
 * Возврат из портала Битрикс24 (/auth/bitrix/done). Код из адреса читаем один раз и сразу убираем
 * из адресной строки и истории. Удачный вход — на исходный адрес или «Сегодня», отказ — объясняем.
 */
export function BitrixDoneScreen() {
  const { acceptSession } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [outcome] = useState(() => parseBitrixReturn(location.search));
  const [view, setView] = useState<View>(() =>
    outcome.kind === 'code' ? { kind: 'busy' } : outcome,
  );
  // Код одноразовый: в StrictMode эффект запускается дважды, второй обмен сжёг бы уже использованный код.
  const started = useRef(false);

  useEffect(() => {
    if (location.search || location.hash) navigate(location.pathname, { replace: true });
    if (started.current) return;
    started.current = true;

    if (outcome.kind !== 'code') {
      returnToStore.take();
      return;
    }
    bitrixAuth
      .exchange(outcome.code)
      .then((s) => {
        const to = returnToStore.take() ?? '/';
        acceptSession(s);
        navigate(to, { replace: true });
      })
      .catch((e) => {
        returnToStore.take();
        setView(outcomeOfExchangeError(e) as View);
      });
    // Только при открытии экрана: адрес после первой правки уже чистый.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return <BitrixDoneView view={view} />;
}

export function BitrixDoneView({ view }: { view: View }) {
  if (view.kind === 'busy') {
    return (
      <AuthFrame title="Вход через Битрикс24">
        <p className="muted" role="status">
          Входим…
        </p>
      </AuthFrame>
    );
  }

  const { title, text, tone } = describe(view);
  return (
    <AuthFrame title="Вход через Битрикс24">
      <div className={`notice notice--${tone}`} role="alert">
        <p className="notice__title">{title}</p>
        <p>{text}</p>
      </div>
      <Link className="btn auth__submit" to="/" replace>
        Ко входу
      </Link>
    </AuthFrame>
  );
}

function describe(view: Exclude<View, { kind: 'busy' }>): { title: string; text: string; tone: 'warn' | 'danger' } {
  switch (view.kind) {
    case 'pending':
      return {
        title: 'Заявка на рассмотрении',
        text: 'Портал подтвердил, кто вы. Заявка на доступ у администратора, войти получится после одобрения.',
        tone: 'warn',
      };
    case 'rejected':
      return {
        title: 'Заявка отклонена',
        text: view.reason ? `Причина: ${view.reason}` : 'Причину можно узнать у администратора.',
        tone: 'danger',
      };
    case 'disabled':
      return { title: 'Доступ отключён', text: 'Обратитесь к администратору.', tone: 'danger' };
    case 'cancelled':
      return {
        title: 'Вход отменён',
        text: 'Портал не передал данные. Войдите снова или выберите другой способ.',
        tone: 'warn',
      };
    case 'error':
      return {
        title: 'Не удалось войти',
        text: view.message ?? 'Портал или сервер ответили ошибкой. Попробуйте ещё раз или войдите по почте.',
        tone: 'danger',
      };
  }
}
