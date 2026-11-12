import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { Check, CircleAlert } from 'lucide-react';

interface Toast {
  id: number;
  text: string;
  tone: 'ok' | 'error';
}

const Ctx = createContext<(text: string, tone?: Toast['tone']) => void>(() => {});
const LIFE_MS = 5000;

/**
 * Короткие сообщения о результате действия внизу экрана: «Обращение взято», «Ссылка скопирована».
 * Контейнер живёт в верхнем слое (popover), иначе его закрыла бы подложка открытой карточки.
 */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<Toast[]>([]);
  const host = useRef<HTMLDivElement>(null);
  const seq = useRef(0);

  const push = useCallback((text: string, tone: Toast['tone'] = 'ok') => {
    const id = ++seq.current;
    setItems((list) => [...list.slice(-2), { id, text, tone }]);
    window.setTimeout(() => setItems((list) => list.filter((t) => t.id !== id)), LIFE_MS);
  }, []);

  // Перепоказываем popover при каждом новом сообщении: так он оказывается выше окна, открытого позже.
  useEffect(() => {
    const el = host.current as (HTMLDivElement & { showPopover?: () => void; hidePopover?: () => void }) | null;
    if (!el?.showPopover || !el.hidePopover) return;
    try {
      if (el.matches(':popover-open')) el.hidePopover();
      el.showPopover();
    } catch {
      /* старый браузер: сообщения остаются обычным фиксированным блоком */
    }
  }, [items.length]);

  return (
    <Ctx.Provider value={push}>
      {children}
      <div ref={host} className="toasts" role="status" aria-live="polite" {...{ popover: 'manual' }}>
        {items.map((t) => (
          <div key={t.id} className={`toast toast--${t.tone}`}>
            <span className="toast__icon" aria-hidden="true">
              {t.tone === 'ok' ? <Check size={14} strokeWidth={3} /> : <CircleAlert size={16} />}
            </span>
            {t.text}
          </div>
        ))}
      </div>
    </Ctx.Provider>
  );
}

/** toast('Готово') или toast('Не получилось', 'error'). */
export const useToast = () => useContext(Ctx);
