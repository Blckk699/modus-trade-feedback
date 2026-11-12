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

/** Экран открыт карточкой поверх другого: тогда ему не нужны ссылка «назад» и заголовок в шапке. */
const InCard = createContext(false);
export const useInCard = () => useContext(InCard);

/** Карточка (обращение, обсуждение, совещание) панелью справа или форма окном по центру — поверх экрана,
 * с которого её открыли ссылкой с `state.background`; закрытие возвращает к нему.
 * Форма (size="form") не закрывается кликом по подложке. */
export function CardModal({ label, size = 'sheet', children }: { label: string; size?: 'sheet' | 'form'; children: ReactNode }) {
  const navigate = useNavigate();
  const [locked, setLocked] = useState(false);
  // Закрытие любым способом (крестик, Esc, «Назад») размонтирует окно — тогда и обновляем список под ним.
  useEffect(() => notifyCardClosed, []);
  return (
    <Modal open onClose={() => navigate(-1)} label={label} size={size} locked={locked} closeOnBackdrop={size !== 'form'}>
      <InCard.Provider value={true}>
        <CardLock.Provider value={setLocked}>{children}</CardLock.Provider>
      </InCard.Provider>
    </Modal>
  );
}
