import { useId, type ReactNode } from 'react';
import { Modal } from './Modal';

interface Props {
  open: boolean;
  title: string;
  children: ReactNode;
  /** Текст кнопки действия: «Отключить доступ», «Отозвать», «Присоединить». */
  confirmLabel: string;
  busyLabel?: string;
  busy?: boolean;
  error?: string;
  /** Необратимое или опасное действие — красная кнопка. */
  danger?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

/**
 * Подтверждение перед действием, которое трудно отменить. Фокус — на «Отмене»: случайный Enter
 * ничего не делает. Пока действие выполняется, окно не закрывается, а ошибка показывается в нём же.
 */
export function Confirm({ open, title, children, confirmLabel, busyLabel, busy = false, error, danger, onConfirm, onCancel }: Props) {
  // Своё id на каждое окно: подтверждение может открыться поверх другого окна с подтверждением.
  const titleId = useId();
  return (
    <Modal open={open} onClose={onCancel} labelledBy={titleId} locked={busy}>
      {open && (
        <div className="dialog-form">
          <h2 id={titleId} className="dialog-form__title">
            {title}
          </h2>
          <div className="confirm__text">{children}</div>
          {error && (
            <p className="error-text" role="alert">
              {error}
            </p>
          )}
          <div className="dialog-form__actions">
            <button type="button" className="btn btn--soft" onClick={onCancel} disabled={busy} data-autofocus>
              Отмена
            </button>
            <button type="button" className={danger ? 'btn btn--danger' : 'btn'} onClick={onConfirm} disabled={busy}>
              {busy ? (busyLabel ?? 'Подождите…') : confirmLabel}
            </button>
          </div>
        </div>
      )}
    </Modal>
  );
}
