import {
  Children,
  Fragment,
  isValidElement,
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type KeyboardEvent,
  type ReactNode,
} from 'react';

type Option = { value: string; label: string };

type Props = {
  value: string | number;
  /** Та же форма, что у нативного <select>: читаем `e.target.value`. */
  onChange: (e: { target: { value: string } }) => void;
  /** Обычные <option value="…">текст</option>. */
  children: ReactNode;
  required?: boolean;
  disabled?: boolean;
  'aria-invalid'?: boolean;
};

function text(node: ReactNode): string {
  if (node === null || node === undefined || typeof node === 'boolean') return '';
  if (typeof node === 'string' || typeof node === 'number') return String(node);
  if (Array.isArray(node)) return node.map(text).join('');
  if (isValidElement<{ children?: ReactNode }>(node)) return text(node.props.children);
  return '';
}

function readOptions(children: ReactNode): Option[] {
  const out: Option[] = [];
  Children.forEach(children, (child) => {
    if (!isValidElement<{ value?: string | number; children?: ReactNode }>(child)) return;
    if (child.type === Fragment) {
      out.push(...readOptions(child.props.children));
    } else if (child.type === 'option') {
      out.push({ value: String(child.props.value ?? ''), label: text(child.props.children) });
    }
  });
  return out;
}

/** Выпадающий список вместо нативного <select>: своё меню, управление с клавиатуры, те же value/onChange. */
export function Select({ value, onChange, children, required, disabled, 'aria-invalid': invalid }: Props) {
  const options = readOptions(children);
  const current = String(value ?? '');
  const selectedIndex = options.findIndex((o) => o.value === current);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const [up, setUp] = useState(false);
  const root = useRef<HTMLSpanElement>(null);
  const menu = useRef<HTMLUListElement>(null);
  const typed = useRef({ text: '', at: 0 });
  const id = useId();

  function show() {
    if (disabled) return;
    setActive(selectedIndex >= 0 ? selectedIndex : 0);
    setOpen(true);
  }

  function pick(index: number) {
    const option = options[index];
    setOpen(false);
    if (option && option.value !== current) onChange({ target: { value: option.value } });
  }

  // Клик мимо закрывает меню.
  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (!root.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, [open]);

  // Если снизу не хватает места, меню раскрывается вверх.
  useLayoutEffect(() => {
    if (!open || !root.current || !menu.current) return;
    const box = root.current.getBoundingClientRect();
    const need = menu.current.offsetHeight + 8;
    setUp(window.innerHeight - box.bottom < need && box.top > need);
  }, [open]);

  useEffect(() => {
    if (open) menu.current?.querySelector('[data-active="true"]')?.scrollIntoView({ block: 'nearest' });
  }, [open, active]);

  function onKeyDown(e: KeyboardEvent) {
    const last = options.length - 1;
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      if (!open) return show();
      setActive((i) => Math.max(0, Math.min(last, i + (e.key === 'ArrowDown' ? 1 : -1))));
    } else if (e.key === 'Home' && open) {
      e.preventDefault();
      setActive(0);
    } else if (e.key === 'End' && open) {
      e.preventDefault();
      setActive(last);
    } else if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      if (open) pick(active);
      else show();
    } else if (e.key === 'Escape' && open) {
      // Не даём Esc закрыть ещё и модальное окно вокруг.
      e.preventDefault();
      e.stopPropagation();
      setOpen(false);
    } else if (e.key === 'Tab') {
      setOpen(false);
    } else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
      // Набор первых букв переводит к подходящему пункту.
      const now = Date.now();
      typed.current = { text: now - typed.current.at < 700 ? typed.current.text + e.key : e.key, at: now };
      const needle = typed.current.text.toLowerCase();
      const found = options.findIndex((o) => o.label.toLowerCase().startsWith(needle));
      if (found >= 0) {
        if (open) setActive(found);
        else pick(found);
      }
    }
  }

  return (
    <span className="select" ref={root}>
      <button
        type="button"
        className="input select__button"
        role="combobox"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={`${id}-menu`}
        aria-activedescendant={open && active >= 0 ? `${id}-${active}` : undefined}
        aria-invalid={invalid}
        disabled={disabled}
        onClick={() => (open ? setOpen(false) : show())}
        onKeyDown={onKeyDown}
      >
        <span className="select__value">{selectedIndex >= 0 ? options[selectedIndex].label : ''}</span>
        <svg className="select__chevron" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true">
          <path d="M4 6l4 4 4-4" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </button>
      {required && (
        // Нативная проверка «обязательное поле» при отправке формы.
        <input className="select__required" tabIndex={-1} aria-hidden="true" required value={current} onChange={() => {}} />
      )}
      {open && (
        <ul
          ref={menu}
          id={`${id}-menu`}
          role="listbox"
          className={up ? 'select__menu select__menu--up' : 'select__menu'}
          // Меню лежит внутри <label>: без этого клик по пункту заново нажал бы кнопку.
          onClick={(e) => e.preventDefault()}
        >
          {options.map((o, i) => (
            <li
              key={o.value}
              id={`${id}-${i}`}
              role="option"
              aria-selected={i === selectedIndex}
              data-active={i === active}
              className="select__option"
              onMouseEnter={() => setActive(i)}
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => pick(i)}
            >
              <span>{o.label}</span>
              {i === selectedIndex && (
                <svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true">
                  <path d="M3.5 8.5l3 3 6-7" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              )}
            </li>
          ))}
        </ul>
      )}
    </span>
  );
}
