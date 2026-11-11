import { BrowserRouter, Navigate, Route, Routes, useLocation, type Location } from 'react-router-dom';
import { LoginScreen, useAuth } from '../auth';
import type { ReactNode } from 'react';
import { CardModal } from '../pages/CardModal';
import { AppealPage } from '../pages/AppealPage';
import { DigestPage } from '../pages/DigestPage';
import { MeetingPage } from '../meetings/MeetingPage';
import { MeetingsPage } from '../meetings/MeetingsPage';
import { DiscussionPage } from '../discussions/DiscussionPage';
import { FeedPage } from '../discussions/FeedPage';
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
  feed: <FeedPage />,
  queue: <QueuePage />,
  digest: <DigestPage />,
  meetings: <MeetingsPage />,
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
  const location = useLocation();
  // Список передаёт себя в state.background: тогда он остаётся на экране, а обращение открывается окном поверх.
  const background = (location.state as { background?: Location } | null)?.background;

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
      <Routes location={background ?? location}>
        <Route element={<Layout />}>
          {nav.map((item) => (
            <Route key={item.id} path={item.path} element={PAGES[item.id] ?? <SectionPage {...SECTIONS[item.id]} />} />
          ))}
          {state.me.permissions.can_create_appeal && <Route path="/my/new" element={<NewAppealPage />} />}
          <Route path="/appeals/:id" element={<AppealPage />} />
          <Route path="/discussions/:id" element={<DiscussionPage />} />
          {state.me.permissions.can_upload_meetings && <Route path="/meetings/:id" element={<MeetingPage />} />}
          {/* Ссылки из уведомлений бота (Notification.path) ведут на /analytics, у веба сводка — /digest. */}
          <Route path="/analytics" element={<Navigate to="/digest" replace />} />
          <Route path="*" element={<Navigate to={startPath(state.me)} replace />} />
        </Route>
      </Routes>
      {background && (
        <Routes>
          {state.me.permissions.can_create_appeal && (
            <Route
              path="/my/new"
              element={
                <CardModal label="Новое обращение" size="form">
                  <NewAppealPage />
                </CardModal>
              }
            />
          )}
          <Route
            path="/appeals/:id"
            element={
              <CardModal label="Обращение">
                <AppealPage />
              </CardModal>
            }
          />
          <Route
            path="/discussions/:id"
            element={
              <CardModal label="Обсуждение">
                <DiscussionPage />
              </CardModal>
            }
          />
          {state.me.permissions.can_upload_meetings && (
            <Route
              path="/meetings/:id"
              element={
                <CardModal label="Совещание">
                  <MeetingPage />
                </CardModal>
              }
            />
          )}
        </Routes>
      )}
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
