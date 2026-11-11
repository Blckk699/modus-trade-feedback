import { useEffect, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { notifyCardClosed } from '../app/cardClosed';
import { Modal } from '../app/Modal';

/** Карточка (обращение, обсуждение) поверх списка. Открывается ссылкой с `state.background`;
 * закрытие возвращает к списку. */
export function CardModal({ label, size = 'wide', children }: { label: string; size?: 'wide' | 'form'; children: ReactNode }) {
  const navigate = useNavigate();
  // Закрытие любым способом (крестик, Esc, «Назад») размонтирует окно — тогда и обновляем список под ним.
  useEffect(() => notifyCardClosed, []);
  return (
    <Modal open onClose={() => navigate(-1)} label={label} size={size}>
      {children}
    </Modal>
  );
}
