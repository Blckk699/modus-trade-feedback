import { useCallback, useEffect, useRef, useState, type DependencyList } from 'react';
import { errorMessage } from '../api/errors';

export type AsyncState<T> =
  | { status: 'loading'; data?: undefined; error?: undefined }
  | { status: 'ready'; data: T; error?: undefined }
  | { status: 'error'; data?: undefined; error: unknown; message: string };

/** Загрузка данных с повтором. reload() перезапрашивает без сброса на «загрузку». */
export function useAsync<T>(load: () => Promise<T>, deps: DependencyList) {
  const [state, setState] = useState<AsyncState<T>>({ status: 'loading' });
  const seq = useRef(0);
  const loadRef = useRef(load);
  loadRef.current = load;

  const run = useCallback((reset: boolean) => {
    const id = ++seq.current;
    if (reset) setState({ status: 'loading' });
    loadRef
      .current()
      .then((data) => id === seq.current && setState({ status: 'ready', data }))
      .catch((error) => id === seq.current && setState({ status: 'error', error, message: errorMessage(error) }));
  }, []);

  useEffect(() => {
    run(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  const reload = useCallback(() => run(false), [run]);
  const set = useCallback((data: T) => setState({ status: 'ready', data }), []);
  return { state, reload, set };
}
