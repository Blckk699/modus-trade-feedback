import { useEffect, useRef, type ReactNode } from 'react';
import { escapeClaimed } from './escape';
import { X } from 'lucide-react';

type Props = {
  open: boolean;
  /** Esc, крестик или клик по подложке. Пока `locked`, окно не закрывается. */
  onClose: () => void;
  /** id заголовка внутри окна; если заголовка с id нет — передайте `label`. */
  labelledBy?: string;
  label?: string;
  /** sheet — панель на всю высоту у правого края (карточка обращения, обсуждение, совещание);
   * form — окно по центру для длинной формы; viewer — просмотр файлов почти на весь экран;
   * default — небольшое окно действия. */
  size?: 'default' | 'form' | 'sheet' | 'viewer';
  locked?: boolean;
  /** false — клик по подложке не закрывает окно (формы, где легко потерять набранное). */
  closeOnBackdrop?: boolean;
  children: ReactNode;
};

function restoreFocus(el: HTMLElement | null) {
  // Следующим кадром: к этому моменту окно уже убрано, а элемент под ним снова доступен.
  if (el) requestAnimationFrame(() => el.isConnected && el.focus({ preventScroll: true }));
}

/** Модальное окно на нативном <dialog>: фокус внутри окна, Esc и подложка закрывают его.
 * Начальный фокус — элемент с `data-autofocus`. */
export function Modal({ open, onClose, labelledBy, label, size = 'default', locked = false, closeOnBackdrop = true, children }: Props) {
  const ref = useRef<HTMLDialogElement>(null);

  // Кто открыл окно: после закрытия возвращаем фокус туда же (строка списка, кнопка действия).
  const opener = useRef<HTMLElement | null>(null);
  const shown = useRef(false);

  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) {
      opener.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
      d.showModal();
      shown.current = true;
      // showModal ставит фокус на первую кнопку (крестик); переводим его в поле с data-autofocus
      d.querySelector<HTMLElement>('[data-autofocus]')?.focus();
    }
    if (!open && d.open) {
      d.close();
      shown.current = false;
      restoreFocus(opener.current);
    }
  }, [open]);

  // Окно-маршрут (карточка поверх списка) закрывается размонтированием: фокус возвращаем и тогда.
  useEffect(
    () => () => {
      if (shown.current) restoreFocus(opener.current);
    },
    [],
  );

  return (
    <dialog
      ref={ref}
      className={size === 'default' ? 'modal' : `modal modal--${size}`}
      aria-labelledby={labelledBy}
      aria-label={label}
      onCancel={(e) => {
        // Esc во вложенном окне (просмотр файла, форма действия) доходит сюда через дерево React:
        // закрываться должно только то окно, которому событие адресовано.
        if (e.target !== e.currentTarget) return;
        e.preventDefault();
        // Esc уже закрыл вложенную панель (чат, меню) — само окно остаётся.
        if (!locked && !escapeClaimed()) onClose();
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget && !locked && closeOnBackdrop) onClose();
      }}
    >
      <div className="modal__body">
        <button type="button" className="tool-btn modal__close" onClick={onClose} disabled={locked} aria-label="Закрыть">
          <X size={18} aria-hidden="true" />
        </button>
        {children}
      </div>
    </dialog>
  );
}
