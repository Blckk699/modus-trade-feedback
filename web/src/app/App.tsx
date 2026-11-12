import type { ReactNode } from 'react';
import { BrowserRouter, Navigate, Route, Routes, useLocation, type Location } from 'react-router-dom';
import { InvitePage } from '../access/InvitePage';
import { AccessRequestScreen, BITRIX_DONE_PATH, BitrixDoneScreen, LoginScreen, RegisterScreen, useAuth } from '../auth';
import { DiscussionPage } from '../discussions/DiscussionPage';
import { FeedPage } from '../discussions/FeedPage';
import { MeetingPage } from '../meetings/MeetingPage';
import { MeetingsPage } from '../meetings/MeetingsPage';
import { AppealPage } from '../pages/AppealPage';
import { CardModal } from '../pages/CardModal';
import { DigestPage } from '../pages/DigestPage';
import { HomePage } from '../pages/HomePage';
import { MyAppealsPage } from '../pages/MyAppealsPage';
import { NewAppealPage } from '../pages/NewAppealPage';
import { QueuePage } from '../pages/QueuePage';
import { ProfilePage } from '../profile/ProfilePage';
import { SettingsPage } from '../settings/SettingsPage';
import { MiniAppShell } from '../telegram/MiniAppShell';
import { BrandMark } from './BrandLogo';
import { buildNav, startPath, type NavId } from './navigation';
import { Shell } from './Shell';
import { ToastProvider } from './Toast';
import { UnreadProvider } from './unread';

const PAGES: Record<NavId, ReactNode> = {
  home: <HomePage />,
  my: <MyAppealsPage />,
  queue: <QueuePage />,
  feed: <FeedPage />,
  digest: <DigestPage />,
  meetings: <MeetingsPage />,
  settings: <SettingsPage />,
};

function AuthGate() {
  const { state, retry } = useAuth();
  const location = useLocation();
  // Экран передаёт себя в state.background: он остаётся на месте, а карточка открывается панелью поверх.
  const background = (location.state as { background?: Location } | null)?.background;

  if (state.status === 'loading') {
    return (
      <div className="splash" role="status">
        <BrandMark className="splash__mark" />
        <span className="sr-only">Загрузка…</span>
      </div>
    );
  }
  if (state.status === 'error') {
    return (
      <div className="splash">
        <p className="error-text">{state.message}</p>
        <button type="button" className="btn" onClick={retry}>
          Повторить
        </button>
      </div>
    );
  }
  // Ссылка-приглашение открывается до входа: сама страница входит через Telegram и принимает приглашение.
  if (location.pathname.startsWith('/invite/')) {
    return (
      <Routes>
        <Route path="/invite/:token" element={<InvitePage />} />
      </Routes>
    );
  }
  if (state.status === 'anonymous') {
    return (
      <Routes>
        <Route path="/register" element={<RegisterScreen />} />
        <Route path={BITRIX_DONE_PATH} element={<BitrixDoneScreen />} />
        <Route path="*" element={<LoginScreen />} />
      </Routes>
    );
  }
  if (state.status === 'unregistered') return <AccessRequestScreen who={state.who} />;

  const nav = buildNav(state.me);
  const p = state.me.permissions;
  return (
    <UnreadProvider>
      <Routes location={background ?? location}>
        <Route element={<Shell />}>
          {nav.map((item) => (
            <Route key={item.id} path={item.path} element={PAGES[item.id]} />
          ))}
          {p.can_create_appeal && <Route path="/my/new" element={<NewAppealPage />} />}
          <Route path="/appeals/:id" element={<AppealPage />} />
          <Route path="/discussions/:id" element={<DiscussionPage />} />
          {p.can_upload_meetings && <Route path="/meetings/:id" element={<MeetingPage />} />}
          <Route path="/profile" element={<ProfilePage />} />
          {/* Ссылки из уведомлений бота (Notification.path) ведут на /analytics, у веба сводка — /digest. */}
          <Route path="/analytics" element={<Navigate to="/digest" replace />} />
          {/* Уведомление о новой заявке (access_request_created) ведёт на /settings/access-requests. */}
          <Route path="/settings/access-requests" element={<Navigate to="/settings?tab=requests" replace />} />
          <Route path="*" element={<Navigate to={startPath(state.me)} replace />} />
        </Route>
      </Routes>
      {background && (
        <Routes>
          {p.can_create_appeal && (
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
          {p.can_upload_meetings && (
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
      <ToastProvider>
        <MiniAppShell />
        <AuthGate />
      </ToastProvider>
    </BrowserRouter>
  );
}
