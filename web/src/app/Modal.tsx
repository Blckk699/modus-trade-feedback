import { useEffect, useRef, type ReactNode } from 'react';
import { X } from 'lucide-react';

type Props = {
  open: boolean;
  /** Esc, крестик или клик по подложке. Пока `locked`, окно не закрывается. */
  onClose: () => void;
  /** id заголовка внутри окна; если заголовка с id нет — передайте `label`. */
  labelledBy?: string;
  label?: string;
  /** sheet — панель на всю высоту у правого края (карточка обращения, обсуждение, совещание);
   * form — окно по центру для длинной формы; default — небольшое окно действия. */
  size?: 'default' | 'form' | 'sheet';
  locked?: boolean;
  /** false — клик по подложке не закрывает окно (формы, где легко потерять набранное). */
  closeOnBackdrop?: boolean;
  children: ReactNode;
};

/** Модальное окно на нативном <dialog>: фокус внутри окна, Esc и подложка закрывают его.
 * Начальный фокус — элемент с `data-autofocus`. */
export function Modal({ open, onClose, labelledBy, label, size = 'default', locked = false, closeOnBackdrop = true, children }: Props) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) {
      d.showModal();
      // showModal ставит фокус на первую кнопку (крестик); переводим его в поле с data-autofocus
      d.querySelector<HTMLElement>('[data-autofocus]')?.focus();
    }
    if (!open && d.open) d.close();
  }, [open]);

  return (
    <dialog
      ref={ref}
      className={size === 'default' ? 'modal' : `modal modal--${size}`}
      aria-labelledby={labelledBy}
      aria-label={label}
      onCancel={(e) => {
        e.preventDefault();
        if (!locked) onClose();
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
