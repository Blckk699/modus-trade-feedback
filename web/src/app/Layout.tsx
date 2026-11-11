import { NavLink, Outlet } from 'react-router-dom';
import { useAuth, useMe } from '../auth';
import { useDictionaries } from './dictionaries';
import { buildNav } from './navigation';
import { themeLabel, useTheme } from './theme';
import { useUnread } from './unread';

const themeIcon = { system: '◐', light: '☀', dark: '☾' } as const;

export function Layout() {
  const me = useMe();
  const { logout } = useAuth();
  const dict = useDictionaries();
  const theme = useTheme();
  const nav = buildNav(me);
  const unread = useUnread();

  return (
    <div className="shell">
      <header className="topbar">
        <span className="topbar__brand brand-mark">Модус Трейд · Обращения</span>
        <div className="topbar__user">
          <span className="topbar__name">{me.full_name}</span>
          <span className="muted topbar__role">
            {dict.roleLabel(me.role)}
            {me.department ? ` · ${me.department.name}` : ''}
          </span>
        </div>
        {unread.count > 0 && (
          <span className="unread" title="Непрочитанные уведомления" aria-label={`Непрочитанных: ${unread.count}`}>
            {unread.count > 99 ? '99+' : unread.count}
          </span>
        )}
        <button
          type="button"
          className="icon-btn theme-toggle"
          onClick={theme.next}
          title={themeLabel[theme.choice]}
          aria-label={themeLabel[theme.choice]}
        >
          {themeIcon[theme.choice]}
        </button>
        <button type="button" className="btn btn--ghost" onClick={logout}>
          Выйти
        </button>
      </header>
      <nav className="sidenav" aria-label="Разделы">
        {nav.map((item) => (
          <NavLink key={item.id} to={item.path} className="sidenav__link">
            <span className="sidenav__label">{item.label}</span>
            <span className="sidenav__short">{item.short}</span>
          </NavLink>
        ))}
      </nav>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
