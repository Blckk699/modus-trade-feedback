import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { api, unwrap } from '../api/client';
import type { Schemas } from '../api/types';

type Dictionaries = Schemas['Dictionaries'];

interface DictionariesValue {
  data: Dictionaries | null;
  roleLabel: (code: string) => string;
  statusLabel: (code: string) => string;
  typeLabel: (code: string) => string;
  priorityLabel: (code: string) => string;
}

function labeler(list: { code: string; label: string }[] | undefined) {
  const map = new Map((list ?? []).map((i) => [i.code, i.label]));
  return (code: string) => map.get(code) ?? code;
}

function build(data: Dictionaries | null): DictionariesValue {
  return {
    data,
    roleLabel: labeler(data?.roles),
    statusLabel: labeler(data?.statuses),
    typeLabel: labeler(data?.appeal_types),
    priorityLabel: labeler(data?.priorities),
  };
}

const Ctx = createContext<DictionariesValue>(build(null));

/** Русские подписи перечислений из GET /api/v1/dictionaries. Маршрут открыт без входа. */
export function DictionariesProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<Dictionaries | null>(null);
  useEffect(() => {
    unwrap(api.GET('/api/v1/dictionaries'))
      .then(setData)
      .catch(() => setData(null));
  }, []);
  const value = useMemo(() => build(data), [data]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export const useDictionaries = () => useContext(Ctx);
