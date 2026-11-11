import type { ReactNode } from 'react';

const ICONS = {
  /** Обращения: лист с текстом. */
  inbox: (
    <>
      <path d="M7 3.5h7l4.5 4.5v11a1.5 1.5 0 0 1-1.5 1.5H7A1.5 1.5 0 0 1 5.5 19V5A1.5 1.5 0 0 1 7 3.5z" />
      <path d="M13.5 3.5V8h5M8.5 12.5h7M8.5 16h5" />
    </>
  ),
  /** Обсуждения: облачко реплики. */
  chat: <path d="M5 5.5h14a1.5 1.5 0 0 1 1.5 1.5v8.5a1.5 1.5 0 0 1-1.5 1.5H10l-4.5 3.5V17H5a1.5 1.5 0 0 1-1.5-1.5V7A1.5 1.5 0 0 1 5 5.5z" />,
  /** Реализовано: галочка в круге. */
  done: (
    <>
      <circle cx="12" cy="12" r="8.5" />
      <path d="M8.5 12.25l2.5 2.5 4.75-5" />
    </>
  ),
  /** Совещания: дорожка звука. */
  audio: <path d="M4 10.5v3M8 7v10M12 9.5v5M16 5v14M20 10.5v3" />,
  /** Поиск без результата. */
  search: (
    <>
      <circle cx="11" cy="11" r="6.5" />
      <path d="M20 20l-4.25-4.25" />
    </>
  ),
};

export type EmptyIcon = keyof typeof ICONS;

/** Пустой список: иконка по центру, заголовок, подзаголовок и при необходимости действие. Без карточки. */
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
  return (
    <div className="empty" role="status">
      <span className="empty__icon" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
          {ICONS[icon]}
        </svg>
      </span>
      <p className="empty__title">{title}</p>
      {children && <p className="empty__text">{children}</p>}
      {action && <div className="empty__action">{action}</div>}
    </div>
  );
}
