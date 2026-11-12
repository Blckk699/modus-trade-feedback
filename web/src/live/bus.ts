import { useEffect, useRef } from 'react';
import type { Topic } from './events';

type Listener = () => void;
const listeners = new Map<Topic, Set<Listener>>();

/** Сообщить экранам, что данные по темам изменились. */
export function publish(topics: Topic[]) {
  const called = new Set<Listener>();
  for (const topic of topics) {
    for (const l of listeners.get(topic) ?? []) {
      if (called.has(l)) continue; // один экран — один перезапрос на событие
      called.add(l);
      l();
    }
  }
}

function subscribe(topic: Topic, l: Listener) {
  let set = listeners.get(topic);
  if (!set) listeners.set(topic, (set = new Set()));
  set.add(l);
  return () => {
    set.delete(l);
    if (set.size === 0) listeners.delete(topic);
  };
}

/**
 * Тихо перезапросить данные экрана, когда пришло событие по одной из тем.
 * Перезапрос идёт без сброса на «загрузку» (useAsync.reload), поэтому экран не мигает и ввод не теряется.
 */
export function useLiveReload(topics: Topic[], reload: () => void) {
  const ref = useRef(reload);
  ref.current = reload;
  const key = topics.join('|');
  useEffect(() => {
    const call = () => ref.current();
    const offs = (key ? (key.split('|') as Topic[]) : []).map((t) => subscribe(t, call));
    return () => offs.forEach((off) => off());
  }, [key]);
}
