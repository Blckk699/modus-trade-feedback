import { useState } from 'react';
import { Link, NavLink, Outlet } from 'react-router-dom';
import {
  AudioLines,
  ChartColumn,
  Ellipsis,
  FileText,
  Inbox,
  LayoutGrid,
  LogOut,
  MessagesSquare,
  Monitor,
  Moon,
  Plus,
  Settings,
  Sun,
  type LucideIcon,
} from 'lucide-react';
import { useAuth, useMe } from '../auth';
import { Avatar } from './Avatar';
import { useBackground } from './background';
import { BrandMark } from './BrandLogo';
import { CommandBar } from './CommandBar';
import { useDictionaries } from './dictionaries';
import { buildNav, splitForTabbar, type NavId, type NavItem } from './navigation';
import { NotificationsBell } from './Notifications';
import { HeadSlot } from './PageHead';
import { themeLabel, useTheme, type ThemeChoice } from './theme';
import { usePopover } from './usePopover';

const NAV_ICON: Record<NavId, LucideIcon> = {
  home: LayoutGrid,
  my: FileText,
  queue: Inbox,
  feed: MessagesSquare,
  digest: ChartColumn,
  meetings: AudioLines,
  settings: Settings,
};

/** Где на телефоне видна круглая кнопка «Подать обращение»: на экранах-списках, где она ничего не закрывает. */
const FAB_PATHS = ['/', '/my', '/feed'];

const THEME_ICON: Record<ThemeChoice, LucideIcon> = { system: Monitor, light: Sun, dark: Moon };

/**
 * Оболочка приложения. На компьютере — рейка разделов слева и шапка с заголовком экрана, поиском и
 * уведомлениями. На телефоне рейку заменяет нижняя панель, а тема и выход уезжают в меню под аватаром.
 */
export function Shell() {
  const me = useMe();
  const { logout } = useAuth();
  const dict = useDictionaries();
  const theme = useTheme();
  const nav = buildNav(me);
  const background = useBackground();
  const [slot, setSlot] = useState<HTMLElement | null>(null);
  const ThemeIcon = THEME_ICON[theme.choice];
  const who = `${dict.roleLabel(me.role)}${me.department ? ` · ${me.department.name}` : ''}`;
  const canCreate = me.permissions.can_create_appeal;

  return (
    <div className="shell">
      <a className="skip-link" href="#main">
        К содержимому
      </a>

      <aside className="rail">
        <Link to="/" className="rail__brand" aria-label="Модус Трейд: на главный экран">
          <BrandMark />
        </Link>
        {canCreate && (
          <Link to="/my/new" state={{ background }} className="rail__create" aria-label="Подать обращение">
            <Plus size={22} strokeWidth={2.25} aria-hidden="true" />
            <span className="tip" aria-hidden="true">
              Подать обращение
            </span>
          </Link>
        )}
        <nav className="rail__nav" aria-label="Разделы">
          {nav.map((item) => (
            <RailLink key={item.id} item={item} count={item.id === 'queue' ? me.assigned_open_count : 0} />
          ))}
        </nav>
        <div className="rail__foot">
          <button type="button" className="rail__btn" onClick={theme.next} aria-label={themeLabel[theme.choice]}>
            <ThemeIcon size={18} aria-hidden="true" />
            <span className="tip" aria-hidden="true">
              {themeLabel[theme.choice]}
            </span>
          </button>
          <button type="button" className="rail__btn" onClick={logout} aria-label="Выйти">
            <LogOut size={18} aria-hidden="true" />
            <span className="tip" aria-hidden="true">
              Выйти
            </span>
          </button>
          <span className="rail__me" tabIndex={0} aria-label={`${me.full_name}, ${who}`}>
            <Avatar name={me.full_name} />
            <span className="tip tip--card" aria-hidden="true">
              <strong>{me.full_name}</strong>
              <span>{who}</span>
            </span>
          </span>
        </div>
      </aside>

      <div className="stage">
        <header className="head">
          <Link to="/" className="head__brand" aria-label="Модус Трейд: на главный экран">
            <BrandMark />
          </Link>
          <div className="head__text" ref={setSlot} />
          <div className="head__tools">
            <CommandBar nav={nav} canCreate={canCreate} />
            <NotificationsBell />
            <UserMenu name={me.full_name} who={who} themeChoice={theme.choice} onTheme={theme.next} onLogout={logout} />
          </div>
        </header>
        <main id="main" className="content" tabIndex={-1}>
          <HeadSlot.Provider value={slot}>
            <Outlet />
          </HeadSlot.Provider>
        </main>
      </div>

      <Tabbar nav={nav} />
      {canCreate && FAB_PATHS.includes(background.pathname) && (
        <Link to="/my/new" state={{ background }} className="fab" aria-label="Подать обращение">
          <Plus size={26} strokeWidth={2.25} aria-hidden="true" />
        </Link>
      )}
    </div>
  );
}

function RailLink({ item, count }: { item: NavItem; count: number }) {
  const Icon = NAV_ICON[item.id];
  return (
    <NavLink to={item.path} end={item.path === '/'} className="rail__link">
      <span className="rail__icon">
        <Icon size={20} aria-hidden="true" />
        {count > 0 && (
          <span className="rail__count" aria-label={`в работе: ${count}`}>
            {count > 99 ? '99+' : count}
          </span>
        )}
      </span>
      <span className="rail__label">{item.short}</span>
    </NavLink>
  );
}

/** Нижняя панель на телефоне: до пяти разделов, остальные — в меню «Ещё». */
function Tabbar({ nav }: { nav: NavItem[] }) {
  const { main, more } = splitForTabbar(nav);
  const menu = usePopover<HTMLDivElement>();
  return (
    <nav className="tabbar" aria-label="Разделы">
      {main.map((item) => {
        const Icon = NAV_ICON[item.id];
        return (
          <NavLink key={item.id} to={item.path} end={item.path === '/'} className="tabbar__link">
            <Icon size={22} aria-hidden="true" />
            <span>{item.short}</span>
          </NavLink>
        );
      })}
      {more.length > 0 && (
        <div className="tabbar__more" ref={menu.ref}>
          <button
            type="button"
            className="tabbar__link"
            aria-haspopup="menu"
            aria-expanded={menu.open}
            data-popover-trigger
            onClick={() => menu.setOpen(!menu.open)}
          >
            <Ellipsis size={22} aria-hidden="true" />
            <span>Ещё</span>
          </button>
          {menu.open && (
            <div className="pop pop--up" role="menu">
              {more.map((item) => {
                const Icon = NAV_ICON[item.id];
                return (
                  <NavLink key={item.id} to={item.path} className="pop__item" role="menuitem">
                    <Icon size={18} aria-hidden="true" />
                    {item.label}
                  </NavLink>
                );
              })}
            </div>
          )}
        </div>
      )}
    </nav>
  );
}

/** Меню под аватаром в шапке — только на телефоне: кто вошёл, тема и выход. */
function UserMenu(props: { name: string; who: string; themeChoice: ThemeChoice; onTheme: () => void; onLogout: () => void }) {
  const menu = usePopover<HTMLDivElement>();
  const ThemeIcon = THEME_ICON[props.themeChoice];
  return (
    <div className="usermenu" ref={menu.ref}>
      <button
        type="button"
        className="usermenu__btn"
        aria-label="Профиль и тема"
        aria-haspopup="menu"
        aria-expanded={menu.open}
        data-popover-trigger
        onClick={() => menu.setOpen(!menu.open)}
      >
        <Avatar name={props.name} />
      </button>
      {menu.open && (
        <div className="pop pop--right" role="menu">
          <div className="pop__who">
            <strong>{props.name}</strong>
            <span>{props.who}</span>
          </div>
          <button type="button" className="pop__item" role="menuitem" onClick={props.onTheme}>
            <ThemeIcon size={18} aria-hidden="true" />
            {themeLabel[props.themeChoice]}
          </button>
          <button type="button" className="pop__item" role="menuitem" onClick={props.onLogout}>
            <LogOut size={18} aria-hidden="true" />
            Выйти
          </button>
        </div>
      )}
    </div>
  );
}
