import type { ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { Modal } from '../app/Modal';

/** Карточка (обращение, обсуждение) поверх списка. Открывается ссылкой с `state.background`;
 * закрытие возвращает к списку. */
export function CardModal({ label, children }: { label: string; children: ReactNode }) {
  const navigate = useNavigate();
  return (
    <Modal open onClose={() => navigate(-1)} label={label} size="wide">
      {children}
    </Modal>
  );
}
