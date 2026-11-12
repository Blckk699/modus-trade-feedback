import { useEffect, useId, useMemo, useRef, useState, type KeyboardEvent } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { ArrowLeft, CornerDownLeft, Plus, Search } from 'lucide-react';
import { api, unwrap } from '../api/client';
import type { Schemas } from '../api/types';
import { StatusBadge } from '../appeals/Badges';
import { useBackground } from './background';
import type { NavItem } from './navigation';

type Item = Schemas['AppealListItem'];

interface Entry {
  key: string;
  group: 'Действия' | 'Разделы' | 'Обращения';
  label: string;
  hint?: string;
  appeal?: Item;
  run: () => void;
}

const isMac = typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform);

/**
 * Поиск и быстрые переходы в шапке. Пустая строка — действия и разделы; от двух букв — обращения,
 * которые видит пользователь (GET /appeals?q=). Открывается кликом, Ctrl/⌘ + K или «/».
 */
export function CommandBar({ nav, canCreate }: { nav: NavItem[]; canCreate: boolean }) {
  const navigate = useNavigate();
  const location = useLocation();
  const background = useBackground();
  const id = useId();
  const input = useRef<HTMLInputElement>(null);
  const root = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [active, setActive] = useState(0);
  const [found, setFound] = useState<{ q: string; items: Item[] } | null>(null);
  const q = query.trim();

  const close = () => {
    setOpen(false);
    setQuery('');
    setFound(null);
    input.current?.blur();
  };

  useEffect(close, [location.key]); // eslint-disable-line react-hooks/exhaustive-deps

  // Ctrl/⌘ + K — отовсюду; «/» — когда фокус не в поле ввода.
  useEffect(() => {
    const onKey = (e: globalThis.KeyboardEvent) => {
      const typing = (e.target as HTMLElement | null)?.closest?.('input, textarea, [contenteditable="true"]');
      const hotkey = ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') || (e.key === '/' && !typing);
      if (!hotkey || document.querySelector('dialog[open]')) return;
      e.preventDefault();
      setOpen(true);
      input.current?.focus();
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, []);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (!root.current?.contains(e.target as Node)) close();
    };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, [open]); // eslint-disable-line react-hooks/exhaustive-deps

  // Поиск с паузой: не дёргаем сервер на каждую букву.
  useEffect(() => {
    if (q.length < 2) {
      setFound(null);
      return;
    }
    let stale = false;
    const timer = window.setTimeout(() => {
      unwrap(api.GET('/api/v1/appeals', { params: { query: { q, page_size: 6 } } }))
        .then((page) => !stale && setFound({ q, items: page.items }))
        .catch(() => !stale && setFound({ q, items: [] }));
    }, 250);
    return () => {
      stale = true;
      window.clearTimeout(timer);
    };
  }, [q]);

  const entries = useMemo<Entry[]>(() => {
    const match = (label: string) => !q || label.toLowerCase().includes(q.toLowerCase());
    const list: Entry[] = [];
    if (canCreate && match('Подать обращение')) {
      list.push({
        key: 'new',
        group: 'Действия',
        label: 'Подать обращение',
        run: () => navigate('/my/new', { state: { background } }),
      });
    }
    for (const item of nav) {
      if (match(item.label)) list.push({ key: item.id, group: 'Разделы', label: item.label, run: () => navigate(item.path) });
    }
    for (const a of found?.items ?? []) {
      list.push({
        key: `a${a.id}`,
        group: 'Обращения',
        label: a.summary ?? 'Без краткой сути',
        hint: a.number,
        appeal: a,
        run: () => navigate(`/appeals/${a.id}`, { state: { background } }),
      });
    }
    return list;
  }, [q, found, nav, canCreate, navigate, background]);

  useEffect(() => setActive(0), [q, found]);

  function onKeyDown(e: KeyboardEvent) {
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      if (entries.length === 0) return;
      setActive((i) => (i + (e.key === 'ArrowDown' ? 1 : -1) + entries.length) % entries.length);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      entries[active]?.run();
    } else if (e.key === 'Escape') {
      e.preventDefault();
      close();
    }
  }

  const searching = q.length >= 2 && found?.q !== q;
  const nothing = q.length >= 2 && !searching && entries.length === 0;
  let lastGroup = '';

  return (
    <div className={open ? 'cmd cmd--open' : 'cmd'} ref={root}>
      <button
        type="button"
        className="cmd__toggle"
        aria-label="Поиск"
        onClick={() => {
          setOpen(true);
          // Поле появляется только после открытия — фокус ставим следующим кадром.
          requestAnimationFrame(() => input.current?.focus());
        }}
      >
        <Search size={20} aria-hidden="true" />
      </button>
      <div className="cmd__field">
        <button type="button" className="cmd__back" aria-label="Закрыть поиск" onClick={close}>
          <ArrowLeft size={20} aria-hidden="true" />
        </button>
        <Search className="cmd__glass" size={16} aria-hidden="true" />
        <input
          ref={input}
          className="cmd__input"
          role="combobox"
          aria-expanded={open}
          aria-controls={`${id}-list`}
          aria-activedescendant={open && entries[active] ? `${id}-${entries[active].key}` : undefined}
          aria-label="Поиск по обращениям и разделам"
          placeholder="Найти обращение или раздел"
          autoComplete="off"
          spellCheck={false}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setOpen(true)}
          onKeyDown={onKeyDown}
        />
        <kbd className="cmd__kbd" aria-hidden="true">
          {isMac ? '⌘K' : 'Ctrl K'}
        </kbd>
      </div>
      {open && (
        <div className="cmd__panel">
          <ul id={`${id}-list`} role="listbox" aria-label="Результаты" className="cmd__list">
            {entries.map((e, i) => {
              const head = e.group !== lastGroup ? e.group : null;
              lastGroup = e.group;
              return (
                <li key={e.key} role="presentation">
                  {head && <div className="cmd__group">{head}</div>}
                  <div
                    id={`${id}-${e.key}`}
                    role="option"
                    aria-selected={i === active}
                    className="cmd__option"
                    onMouseEnter={() => setActive(i)}
                    onMouseDown={(ev) => ev.preventDefault()}
                    onClick={e.run}
                  >
                    {e.group === 'Действия' && (
                      <span className="cmd__plus" aria-hidden="true">
                        <Plus size={14} strokeWidth={2.5} />
                      </span>
                    )}
                    {e.hint && <span className="cmd__num">{e.hint}</span>}
                    <span className="cmd__label">{e.label}</span>
                    {e.appeal && <StatusBadge status={e.appeal.status} />}
                    {i === active && !e.appeal && <CornerDownLeft className="cmd__enter" size={14} aria-hidden="true" />}
                  </div>
                </li>
              );
            })}
          </ul>
          {searching && <p className="cmd__note">Ищем…</p>}
          {nothing && <p className="cmd__note">Ничего не нашлось. Попробуйте номер обращения или другое слово.</p>}
          {q.length < 2 && <p className="cmd__note cmd__note--hint">Введите номер или пару слов из обращения.</p>}
        </div>
      )}
    </div>
  );
}
