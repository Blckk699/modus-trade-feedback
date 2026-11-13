import { useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';
import { pathFromStartParam } from './startParam';
import { watchTelegramFrame } from './theme';
import { openFullWindow, watchSafeArea } from './viewport';
import { getWebApp } from './webApp';

/**
 * Оболочка Mini App (T-06). Вне Telegram ничего не делает и ничего не рисует.
 * - ready() и раскрытие окна (telegram/viewport.ts): на телефоне — на весь экран (Telegram 8.0+), иначе expand();
 *   свайп вниз окно не закрывает; отступы под чёлку и кнопки Telegram — CSS-переменными --app-safe-*;
 * - тема: наши токены без перекраски под Telegram (как мобильный веб); рамку Telegram (шапка, фон,
 *   нижняя полоса) красим цветами нашей текущей темы и перекрашиваем при её смене;
 * - кнопка «Назад» Telegram: видна, когда есть куда вернуться внутри приложения, ведёт на шаг назад;
 * - ссылка из бота (start_param): открывает нужный экран, например appeals_21 → /appeals/21.
 * Экраны остаются за пачкой фронта: оболочка работает через роутер и не знает о них.
 */
export function MiniAppShell() {
  const webApp = getWebApp();
  const navigate = useNavigate();
  const location = useLocation();
  const { state } = useAuth();
  const startHandled = useRef(false);

  useEffect(() => {
    if (!webApp) return;
    const stopFrame = watchTelegramFrame(webApp);
    const stopSafeArea = watchSafeArea(webApp);
    webApp.ready();
    openFullWindow(webApp);
    return () => {
      stopFrame();
      stopSafeArea();
    };
  }, [webApp]);

  // Ссылка из бота: один раз при открытии, пока идёт вход. Так маршрут уже на месте, когда AuthGate
  // отрисует экраны, и его не перебьёт переход на стартовый экран роли.
  // replace: экран из ссылки — первый в истории, «Назад» на нём не показывается.
  useEffect(() => {
    if (!webApp || startHandled.current) return;
    startHandled.current = true;
    const target = pathFromStartParam(webApp.initDataUnsafe.start_param);
    if (target && target !== location.pathname) navigate(target, { replace: true });
  }, [webApp, navigate, location.pathname]);

  useEffect(() => {
    if (!webApp) return;
    const back = () => navigate(-1);
    // BrowserRouter хранит номер записи истории в history.state.idx: 0 — первый экран Mini App.
    const canGoBack = state.status === 'authenticated' && historyIndex() > 0;
    if (canGoBack) webApp.BackButton.show();
    else webApp.BackButton.hide();
    webApp.BackButton.onClick(back);
    return () => {
      webApp.BackButton.offClick(back);
    };
  }, [webApp, navigate, location.key, state.status]);

  return null;
}

function historyIndex(): number {
  const idx = (window.history.state as { idx?: unknown } | null)?.idx;
  return typeof idx === 'number' ? idx : 0;
}
