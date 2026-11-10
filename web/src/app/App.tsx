import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { LoginScreen, useAuth } from '../auth';
import { SectionPage } from '../pages/SectionPage';
import { Layout } from './Layout';
import { buildNav, startPath, type NavId } from './navigation';

const SECTIONS: Record<NavId, { title: string; lead: string }> = {
  my: { title: 'Мои обращения', lead: 'Обращения, которые вы подали, их статусы и история.' },
  feed: { title: 'Лента реализованного', lead: 'Что предложили сотрудники и что в итоге сделали.' },
  queue: { title: 'Обработка', lead: 'Назначенные вам обращения, отсортированные по сроку.' },
  digest: { title: 'Сводка', lead: 'Обращения по типам и категориям, доля закрытых, время первого ответа.' },
  meetings: { title: 'Совещания', lead: 'Запись совещания превращается в черновики обращений.' },
  settings: { title: 'Настройки', lead: 'Сотрудники, подразделения, категории и сроки ответа.' },
};

function AuthGate() {
  const { state, retry } = useAuth();

  if (state.status === 'loading') {
    return (
      <div className="center muted" role="status">
        Загрузка…
      </div>
    );
  }
  if (state.status === 'error') {
    return (
      <div className="center">
        <p className="error-text">{state.message}</p>
        <button type="button" className="btn" onClick={retry}>
          Повторить
        </button>
      </div>
    );
  }
  if (state.status === 'anonymous') return <LoginScreen />;

  const nav = buildNav(state.me);
  return (
    <Routes>
      <Route element={<Layout />}>
        {nav.map((item) => (
          <Route key={item.id} path={item.path} element={<SectionPage {...SECTIONS[item.id]} />} />
        ))}
        <Route path="*" element={<Navigate to={startPath(state.me)} replace />} />
      </Route>
    </Routes>
  );
}

export function App() {
  return (
    <BrowserRouter>
      <AuthGate />
    </BrowserRouter>
  );
}
