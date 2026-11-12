import { createContext, useContext, useEffect, type ReactNode } from 'react';
import { createPortal } from 'react-dom';

/** Место в шапке под заголовок экрана. Его отдаёт оболочка (Shell). */
export const HeadSlot = createContext<HTMLElement | null>(null);

/**
 * Заголовок экрана в общей шапке, слева от поиска: мелкая строка над заголовком и сам заголовок.
 * Экран объявляет его у себя, а рисуется он в шапке — так поиск и уведомления всегда на одном месте.
 */
export function PageHead({ over, title }: { over?: ReactNode; title: string }) {
  const slot = useContext(HeadSlot);
  // Заголовок вкладки браузера — тот же, что у экрана: так вкладки и история различимы.
  useEffect(() => {
    document.title = `${title} · Модус Трейд`;
  }, [title]);
  if (!slot) return null;
  return createPortal(
    <>
      {over && <p className="head__over">{over}</p>}
      <h1 className="head__title">{title}</h1>
    </>,
    slot,
  );
}
