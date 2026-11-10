import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { LoginScreen, useAuth } from '../auth';
import type { ReactNode } from 'react';
import { AppealPage } from '../pages/AppealPage';
import { MyAppealsPage } from '../pages/MyAppealsPage';
import { NewAppealPage } from '../pages/NewAppealPage';
import { QueuePage } from '../pages/QueuePage';
import { SectionPage } from '../pages/SectionPage';
import { SettingsPage } from '../settings/SettingsPage';
import { MiniAppShell } from '../telegram/MiniAppShell';
import { Layout } from './Layout';
import { buildNav, startPath, type NavId } from './navigation';
import { UnreadProvider } from './unread';

/** Готовые разделы. Остальные показывают заголовок, пока их не наполнят тикеты W-03…W-08. */
const PAGES: Partial<Record<NavId, ReactNode>> = {
  my: <MyAppealsPage />,
  queue: <QueuePage />,
  settings: <SettingsPage />,
};

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
    <UnreadProvider>
      <Routes>
        <Route element={<Layout />}>
          {nav.map((item) => (
            <Route key={item.id} path={item.path} element={PAGES[item.id] ?? <SectionPage {...SECTIONS[item.id]} />} />
          ))}
          {state.me.permissions.can_create_appeal && <Route path="/my/new" element={<NewAppealPage />} />}
          <Route path="/appeals/:id" element={<AppealPage />} />
          {/* Ссылки из уведомлений бота (Notification.path) ведут на /analytics, у веба сводка — /digest. */}
          <Route path="/analytics" element={<Navigate to="/digest" replace />} />
          <Route path="*" element={<Navigate to={startPath(state.me)} replace />} />
        </Route>
      </Routes>
    </UnreadProvider>
  );
}

export function App() {
  return (
    <BrowserRouter>
      <MiniAppShell />
      <AuthGate />
    </BrowserRouter>
  );
}
