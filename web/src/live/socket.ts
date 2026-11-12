import { tokenStore } from '../auth/tokenStore';
import { config } from '../config';
import { parseEvent, retryDelay, type LiveEvent } from './events';

/** Адрес сокета на том же хосте, что и API: http → ws, https → wss. Токена в адресе нет. */
export function socketUrl(apiBaseUrl: string = config.apiBaseUrl): string {
  return `${apiBaseUrl.replace(/^http/, 'ws')}/api/v1/ws`;
}

const MOCK_CHANNEL = 'modus-live-mock';

/** Для локальной проверки: послать событие во все вкладки с VITE_LIVE_MOCK=true. */
export function emitMock(event: LiveEvent) {
  new BroadcastChannel(MOCK_CHANNEL).postMessage(event);
}

/**
 * Подписка на живые обновления (B-24). Возвращает функцию закрытия.
 * Соединение рвётся — переподключаемся с растущей паузой; сервер без сокета (до выкладки B-24)
 * просто не отвечает, и приложение работает как раньше: опросом и перезапросом при действиях.
 */
export function connectLive(onEvent: (event: LiveEvent) => void): () => void {
  if (config.liveMock) {
    const ch = new BroadcastChannel(MOCK_CHANNEL);
    ch.onmessage = (m) => {
      const ev = parseEvent(m.data);
      if (ev) onEvent(ev);
    };
    return () => ch.close();
  }

  let closed = false;
  let ws: WebSocket | null = null;
  let timer: number | undefined;
  let attempt = 0;

  const open = () => {
    const token = tokenStore.get();
    if (closed || !token || typeof WebSocket === 'undefined') return;
    try {
      ws = new WebSocket(socketUrl());
    } catch {
      return schedule();
    }
    ws.onopen = () => {
      // Токен идёт первым сообщением, а не в адресе: адреса попадают в журналы.
      ws?.send(JSON.stringify({ type: 'auth', token }));
    };
    ws.onmessage = (m) => {
      attempt = 0;
      const ev = parseEvent(m.data);
      if (ev) onEvent(ev);
    };
    ws.onclose = () => {
      ws = null;
      schedule();
    };
    ws.onerror = () => ws?.close();
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
    document.removeEventListener('visibilitychange', onVisible);
    ws?.close();
  };
}
