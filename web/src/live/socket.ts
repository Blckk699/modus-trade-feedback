import { tokenStore } from '../auth/tokenStore';
import { config } from '../config';
import { closeAction, parseMessage, PING_MS, retryDelay, type LiveEvent, type ServerMessage } from './events';

/**
 * Адрес сокета на том же хосте, что и API: http → ws, https → wss. Токена в адресе нет.
 * База API может быть относительной (пустой): адрес достраиваем от адреса страницы — относительный
 * адрес WebSocket принимают не все браузеры.
 */
export function socketUrl(apiBaseUrl: string = config.apiBaseUrl, pageUrl: string = window.location.href): string {
  const url = new URL(`${apiBaseUrl.replace(/\/$/, '')}/api/v1/ws`, pageUrl);
  url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
  return url.toString();
}

const MOCK_CHANNEL = 'modus-live-mock';

/** Для локальной проверки: послать сообщение сервера во все вкладки с VITE_LIVE_MOCK=true. */
export function emitMock(message: ServerMessage) {
  new BroadcastChannel(MOCK_CHANNEL).postMessage(message);
}

export interface LiveHandlers {
  onEvent: (event: LiveEvent) => void;
  /**
   * Сервер принял вход. `reconnected` — это не первое подключение: пропущенные события сервер
   * не досылает, экранам пора перечитать данные.
   */
  onReady: (unreadCount: number, reconnected: boolean) => void;
}

/**
 * Подписка на живые обновления (B-24). Возвращает функцию закрытия.
 * Первым сообщением уходит `auth` с токеном сессии, события идут после `ready`. Соединение рвётся —
 * переподключаемся с растущей паузой; код 4401 значит, что сессии больше нет, и ведёт на вход.
 * Сервер без сокета просто не отвечает, и приложение работает как раньше: опросом и перезапросом при действиях.
 */
export function connectLive({ onEvent, onReady }: LiveHandlers): () => void {
  const dispatch = (raw: unknown, wasReady: boolean): boolean => {
    const msg = parseMessage(raw);
    if (!msg || msg.type === 'pong') return false;
    if (msg.type === 'ready') {
      onReady(msg.unread_count, wasReady);
      return true;
    }
    onEvent(msg);
    return false;
  };

  if (config.liveMock) {
    const ch = new BroadcastChannel(MOCK_CHANNEL);
    let ready = false;
    ch.onmessage = (m) => {
      if (dispatch(m.data, ready)) ready = true;
    };
    return () => ch.close();
  }

  let closed = false;
  let ws: WebSocket | null = null;
  let timer: number | undefined;
  let ping: number | undefined;
  let attempt = 0;
  let everReady = false;

  const open = () => {
    const token = tokenStore.get();
    if (closed || !token || typeof WebSocket === 'undefined') return;
    let socket: WebSocket;
    try {
      socket = new WebSocket(socketUrl());
    } catch {
      return schedule();
    }
    ws = socket;
    socket.onopen = () => {
      // Токен идёт первым сообщением, а не в адресе: адреса попадают в журналы.
      socket.send(JSON.stringify({ type: 'auth', token }));
    };
    socket.onmessage = (m) => {
      if (dispatch(m.data, everReady)) {
        everReady = true;
        attempt = 0;
        window.clearInterval(ping);
        ping = window.setInterval(() => {
          if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: 'ping' }));
        }, PING_MS);
      }
    };
    socket.onclose = (e) => {
      window.clearInterval(ping);
      if (ws === socket) ws = null;
      if (closed) return;
      const action = closeAction(e.code);
      if (action === 'relogin') {
        closed = true;
        // Как на 401 от API: сессии нет, выходим на экран входа. Токен уже сменился (другой вход
        // в этой вкладке) — значит, закрыли прежнюю сессию, новую не трогаем.
        if (tokenStore.get() === token) tokenStore.set(null);
      } else if (action === 'stop') {
        closed = true;
      } else {
        schedule();
      }
    };
    socket.onerror = () => socket.close();
  };

  const schedule = () => {
    if (closed) return;
    timer = window.setTimeout(open, retryDelay(attempt++));
  };

  // Вкладка вернулась на экран после долгого простоя — не ждём паузу, подключаемся сразу.
  const onVisible = () => {
    if (document.visibilityState === 'visible' && !ws && !closed) {
      window.clearTimeout(timer);
      attempt = 0;
      open();
    }
  };
  document.addEventListener('visibilitychange', onVisible);
  open();

  return () => {
    closed = true;
    window.clearTimeout(timer);
    window.clearInterval(ping);
    document.removeEventListener('visibilitychange', onVisible);
    ws?.close();
  };
}
