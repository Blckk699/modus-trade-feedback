import { useEffect, useState } from 'react';
import { storage } from '../storage';

export type ThemeChoice = 'system' | 'light' | 'dark';
const KEY = 'modus.theme';

function apply(choice: ThemeChoice) {
  const root = document.documentElement;
  if (choice === 'system') root.removeAttribute('data-theme');
  else root.setAttribute('data-theme', choice);
}

/** Тема: по умолчанию системная, пользователь может закрепить светлую или тёмную. */
export function useTheme() {
  const [choice, setChoice] = useState<ThemeChoice>(() => {
    const saved = storage.get(KEY);
    return saved === 'light' || saved === 'dark' ? saved : 'system';
  });
  useEffect(() => {
    apply(choice);
    storage.set(KEY, choice === 'system' ? null : choice);
  }, [choice]);
  const next = () => setChoice((c) => (c === 'system' ? 'light' : c === 'light' ? 'dark' : 'system'));
  return { choice, next };
}

export const themeLabel: Record<ThemeChoice, string> = {
  system: 'Тема: как в системе',
  light: 'Тема: светлая',
  dark: 'Тема: тёмная',
};
