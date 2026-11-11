import { useEffect, useRef, type ReactNode } from 'react';

type Props = {
  open: boolean;
  /** Esc, крестик или клик по подложке. Пока `locked`, окно не закрывается. */
  onClose: () => void;
  /** id заголовка внутри окна; если заголовка с id нет — передайте `label`. */
  labelledBy?: string;
  label?: string;
  /** wide — для больших карточек, например обращения. */
  size?: 'default' | 'wide';
  locked?: boolean;
  children: ReactNode;
};

/** Модальное окно на нативном <dialog>: фокус внутри окна, Esc и подложка закрывают его.
 * Начальный фокус — элемент с `data-autofocus`. */
export function Modal({ open, onClose, labelledBy, label, size = 'default', locked = false, children }: Props) {
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
      className={size === 'wide' ? 'modal modal--wide' : 'modal'}
      aria-labelledby={labelledBy}
      aria-label={label}
      onCancel={(e) => {
        e.preventDefault();
        if (!locked) onClose();
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget && !locked) onClose();
      }}
    >
      <div className="modal__body">
        <button type="button" className="icon-btn modal__close" onClick={onClose} disabled={locked} aria-label="Закрыть">
          ✕
        </button>
        {children}
      </div>
    </dialog>
  );
}
