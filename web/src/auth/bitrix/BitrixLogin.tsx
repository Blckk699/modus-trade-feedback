import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { bitrixAuth } from './bitrixAuth';
import { returnToStore } from './bitrixReturn';

/** Включён ли вход через Битрикс24. До ответа считаем, что выключен: кнопка не мигает на экране. */
export function useBitrixLogin(): boolean {
  const [enabled, setEnabled] = useState(false);
  useEffect(() => {
    let alive = true;
    bitrixAuth
      .enabled()
      .then((on) => alive && setEnabled(on))
      .catch(() => alive && setEnabled(false));
    return () => {
      alive = false;
    };
  }, []);
  return enabled;
}

/** Фирменный знак портала: облако с «24». Простая форма, чтобы не тянуть картинку. */
function BitrixMark() {
  return (
    <svg className="sso-btn__mark" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <circle cx="12" cy="12" r="12" fill="#2FC6F6" />
      <text x="12" y="16" textAnchor="middle" fontSize="10.5" fontWeight="700" fill="#fff" fontFamily="inherit">
        24
      </text>
    </svg>
  );
}

/**
 * Кнопка «Войти через Битрикс24». Запоминает, какой адрес открывали, и уводит браузер на бэкенд,
 * откуда тот отправит на портал. Обычная ссылка: работает и без JS-перехода, и открывается средним кликом.
 */
export function BitrixLoginButton() {
  const { pathname, search } = useLocation();
  const [busy, setBusy] = useState(false);
  return (
    <a
      className="btn btn--soft sso-btn"
      href={bitrixAuth.startUrl()}
      aria-disabled={busy || undefined}
      onClick={(e) => {
        if (busy) {
          e.preventDefault();
          return;
        }
        returnToStore.save(`${pathname}${search}`);
        setBusy(true);
      }}
    >
      <BitrixMark />
      {busy ? 'Открываем портал…' : 'Войти через Битрикс24'}
    </a>
  );
}
