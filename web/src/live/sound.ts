import { maySound } from './events';

const KEY = 'modus.sound';
const URL_ = `${import.meta.env.BASE_URL}sounds/notify.wav`;

/** Звук включён, пока пользователь его не выключил в профиле. Хранится в браузере. */
export function soundEnabled(): boolean {
  try {
    return window.localStorage.getItem(KEY) !== '0';
  } catch {
    return true;
  }
}

export function setSoundEnabled(on: boolean): void {
  try {
    window.localStorage.setItem(KEY, on ? '1' : '0');
  } catch {
    /* хранилище недоступно — настройка живёт до перезагрузки */
  }
}

let lastAt = -Infinity;
let audio: HTMLAudioElement | null = null;

/** Короткий мягкий сигнал: не чаще раза в четыре секунды. `force` — проба из профиля. */
export function playNotify(force = false): void {
  if (!force && !soundEnabled()) return;
  const now = Date.now();
  if (!force && !maySound(lastAt, now)) return;
  lastAt = now;
  try {
    audio ??= new Audio(URL_);
    audio.volume = 0.5;
    audio.currentTime = 0;
    // Браузер может запретить звук до первого действия пользователя — это не ошибка.
    void audio.play().catch(() => {});
  } catch {
    /* звука нет — уведомление всё равно видно */
  }
}
