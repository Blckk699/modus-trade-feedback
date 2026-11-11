import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { notifyCardClosed } from '../app/cardClosed';
import { Modal } from '../app/Modal';

/** Страница внутри окна может запретить его закрытие, пока идёт отправка. */
const CardLock = createContext<(locked: boolean) => void>(() => {});

/** Пока `locked`, окно с этой страницей не закрывается (Esc, крестик, подложка). Вне окна ничего не делает. */
export function useCardLock(locked: boolean) {
  const setLocked = useContext(CardLock);
  useEffect(() => {
    setLocked(locked);
    return () => setLocked(false);
  }, [locked, setLocked]);
}

/** Карточка (обращение, обсуждение) или форма поверх списка. Открывается ссылкой с `state.background`;
 * закрытие возвращает к списку. Форма (size="form") не закрывается кликом по подложке. */
export function CardModal({ label, size = 'wide', children }: { label: string; size?: 'wide' | 'form'; children: ReactNode }) {
  const navigate = useNavigate();
  const [locked, setLocked] = useState(false);
  // Закрытие любым способом (крестик, Esc, «Назад») размонтирует окно — тогда и обновляем список под ним.
  useEffect(() => notifyCardClosed, []);
  return (
    <Modal open onClose={() => navigate(-1)} label={label} size={size} locked={locked} closeOnBackdrop={size !== 'form'}>
      <CardLock.Provider value={setLocked}>{children}</CardLock.Provider>
    </Modal>
  );
}
