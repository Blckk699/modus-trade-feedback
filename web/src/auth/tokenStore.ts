import { storage } from '../storage';

const KEY = 'modus.access_token';
type Listener = (token: string | null) => void;
const listeners = new Set<Listener>();
let token = storage.get(KEY);

/** Хранит токен сессии. Клиент API берёт его отсюда, AuthProvider подписан на изменения. */
export const tokenStore = {
  get: () => token,
  set(next: string | null) {
    if (next === token) return;
    token = next;
    storage.set(KEY, next);
    listeners.forEach((l) => l(next));
  },
  subscribe(l: Listener) {
    listeners.add(l);
    return () => {
      listeners.delete(l);
    };
  },
};
