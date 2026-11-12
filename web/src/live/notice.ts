import type { Schemas } from '../api/types';
import { notificationTarget, plainText } from '../app/Notifications';

type Notification = Schemas['Notification'];

export interface Screen {
  /** Адрес текущего экрана. */
  pathname: string;
  /** Обращение, чей чат сейчас открыт. */
  openChatAppealId: number | null;
}

export interface Notice {
  text: string;
  /** Куда ведёт кнопка «Открыть»; null — открывать нечего. */
  to: string | null;
}

/**
 * Тост по пришедшему уведомлению: первая строка его текста и переход туда же, куда ведёт колокольчик.
 * Тоста нет, если человек уже смотрит на это: открыт чат обращения, по которому пришло сообщение,
 * или экран, на который ведёт уведомление.
 */
export function noticeFor(n: Notification, screen: Screen): Notice | null {
  const to = notificationTarget(n);
  if (n.kind === 'message_received' && n.appeal && n.appeal.id === screen.openChatAppealId) return null;
  if (to && to === screen.pathname) return null;
  const text = plainText(n.text).split('\n')[0] ?? '';
  if (!text) return null;
  return { text: text.length > 90 ? `${text.slice(0, 89).trimEnd()}…` : text, to };
}
