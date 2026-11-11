import { useEffect } from 'react';

const CARD_CLOSED = 'modus:card-closed';

/** Окно с карточкой закрылось: списки под ним перезапрашивают данные. */
export function notifyCardClosed() {
  window.dispatchEvent(new Event(CARD_CLOSED));
}

/** Тихо обновить список, когда закрылось окно с карточкой (обращение, обсуждение, совещание). */
export function useReloadOnCardClose(reload: () => void) {
  useEffect(() => {
    window.addEventListener(CARD_CLOSED, reload);
    return () => window.removeEventListener(CARD_CLOSED, reload);
  }, [reload]);
}
