import { useEffect, useState } from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { BrandLogo } from './BrandLogo';
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
  const scrolled = useScrolled();

  return (
    <div className="shell">
      <header className={scrolled ? 'topbar topbar--scrolled' : 'topbar'}>
        <BrandLogo className="topbar__brand" />
        <nav className="mainnav" aria-label="Разделы">
          {nav.map((item) => (
            <NavLink key={item.id} to={item.path} className="mainnav__link">
              <span className="mainnav__label">{item.label}</span>
              <span className="mainnav__short">{item.short}</span>
            </NavLink>
          ))}
        </nav>
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
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}

/** Страница прокручена вниз: под прилипшей шапкой появляется тень, иначе её край сливается с белыми карточками. */
function useScrolled(): boolean {
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const update = () => setScrolled(window.scrollY > 4);
    update();
    window.addEventListener('scroll', update, { passive: true });
    return () => window.removeEventListener('scroll', update);
  }, []);
  return scrolled;
}
