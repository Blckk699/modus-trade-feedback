import { useEffect, useRef } from 'react';

/** На телефоне панель сжата в шапку: фигуре там нет места, библиотеку не загружаем. */
const WIDE = '(min-width: 761px)';

/**
 * Трёхмерная фигура в фирменной панели. Чисто декоративная: грузится отдельным куском после экрана входа,
 * а если WebGL недоступен, панель остаётся как была.
 */
export function AuthScene() {
  const host = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = host.current;
    if (!el || !window.matchMedia(WIDE).matches) return;
    let dispose: (() => void) | undefined;
    let cancelled = false;
    const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    import('./scene/rings')
      .then(({ mountRings }) => {
        if (cancelled) return;
        // Текст панели прижат к низу: над ним фигура видна целиком, ниже уходит в тень.
        const pitch = el.parentElement?.querySelector<HTMLElement>('.auth__pitch');
        dispose = mountRings(el, still, () => pitch?.offsetTop ?? el.clientHeight);
        el.dataset.ready = 'true';
      })
      .catch(() => {
        // Нет WebGL или кусок не загрузился: украшение необязательно.
      });
    return () => {
      cancelled = true;
      dispose?.();
    };
  }, []);

  return <div ref={host} className="auth__scene" aria-hidden="true" />;
}
