import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { Bell, Check, CircleAlert } from 'lucide-react';

/** Действие в сообщении: «Новое сообщение по A-028» → [Открыть]. */
export interface ToastAction {
  label: string;
  run: () => void;
}

interface Toast {
  id: number;
  text: string;
  tone: 'ok' | 'error' | 'info';
  action?: ToastAction;
}

const Ctx = createContext<(text: string, tone?: Toast['tone'], action?: ToastAction) => void>(() => {});
const LIFE_MS = 5000;

/**
 * Короткие сообщения о результате действия внизу экрана: «Обращение взято», «Ссылка скопирована».
 * Контейнер живёт в верхнем слое (popover), иначе его закрыла бы подложка открытой карточки.
 */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<Toast[]>([]);
  const host = useRef<HTMLDivElement>(null);
  const seq = useRef(0);

  const push = useCallback((text: string, tone: Toast['tone'] = 'ok', action?: ToastAction) => {
    const id = ++seq.current;
    setItems((list) => [...list.slice(-2), { id, text, tone, action }]);
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
              {t.tone === 'ok' ? <Check size={14} strokeWidth={3} /> : t.tone === 'info' ? <Bell size={14} /> : <CircleAlert size={16} />}
            </span>
            {t.text}
            {t.action && (
              <button
                type="button"
                className="toast__action"
                onClick={() => {
                  t.action?.run();
                  setItems((list) => list.filter((x) => x.id !== t.id));
                }}
              >
                {t.action.label}
              </button>
            )}
          </div>
        ))}
      </div>
    </Ctx.Provider>
  );
}

/** toast('Готово') или toast('Не получилось', 'error'). */
export const useToast = () => useContext(Ctx);
