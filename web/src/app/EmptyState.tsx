import type { ReactNode } from 'react';
import { AudioLines, CircleCheck, FileText, MessagesSquare, Search, type LucideIcon } from 'lucide-react';

const ICONS = {
  inbox: FileText,
  chat: MessagesSquare,
  done: CircleCheck,
  audio: AudioLines,
  search: Search,
} satisfies Record<string, LucideIcon>;

export type EmptyIcon = keyof typeof ICONS;

/** Пустой список: карточка на месте списка, в центре — значок, заголовок, пояснение и при необходимости действие. */
export function EmptyState({
  icon,
  title,
  children,
  action,
}: {
  icon: EmptyIcon;
  title: string;
  children?: ReactNode;
  action?: ReactNode;
}) {
  const Icon = ICONS[icon];
  return (
    <div className="empty" role="status">
      <span className="empty__icon" aria-hidden="true">
        <Icon size={26} strokeWidth={1.75} />
      </span>
      <p className="empty__title">{title}</p>
      {children && <p className="empty__text">{children}</p>}
      {action && <div className="empty__action">{action}</div>}
    </div>
  );
}
