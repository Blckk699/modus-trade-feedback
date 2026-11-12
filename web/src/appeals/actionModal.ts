import { createContext, useContext, useEffect } from 'react';

/** Форма действия открыта в окне: окно должно знать, идёт ли отправка, и уметь закрыться по «Отмена». */
export interface ActionModalApi {
  setBusy: (busy: boolean) => void;
  cancel: () => void;
}

export const ActionModal = createContext<ActionModalApi>({ setBusy: () => {}, cancel: () => {} });

/** Пока форма отправляется, окно не закрывается. Возвращает «Отмена» для кнопки формы. */
export function useActionModal(busy: boolean): () => void {
  const api = useContext(ActionModal);
  useEffect(() => {
    api.setBusy(busy);
    return () => api.setBusy(false);
  }, [busy, api]);
  return api.cancel;
}
