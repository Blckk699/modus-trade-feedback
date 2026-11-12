import type { ReactNode } from 'react';
import { BrandLogo } from '../app/BrandLogo';
import { DotNumber } from '../app/DotNumber';

/**
 * Рамка экранов до входа: вход, заявка на доступ, приглашение. Слева — фирменная панель с логотипом
 * и коротким объяснением, зачем это всё, справа — содержимое экрана. На телефоне панель сжимается в шапку.
 */
export function AuthFrame({ title, lead, children }: { title: string; lead?: ReactNode; children: ReactNode }) {
  return (
    <main className="auth">
      <aside className="auth__brand">
        <span className="auth__logo">
          <BrandLogo />
        </span>
        <div className="auth__pitch">
          <p className="auth__headline">Скажите, что мешает работать. Ответ придёт в срок.</p>
          <ul className="auth__points">
            <li>
              <DotNumber className="auth__num" value="1" label="1." />
              <span>Напишите о проблеме, идее или хорошей работе коллег.</span>
            </li>
            <li>
              <DotNumber className="auth__num" value="2" label="2." />
              <span>Обращение сразу получит тот, кто отвечает за тему.</span>
            </li>
            <li>
              <DotNumber className="auth__num" value="3" label="3." />
              <span>Следите за статусом здесь и в Telegram.</span>
            </li>
          </ul>
        </div>
      </aside>
      <div className="auth__panel">
        <div className="auth__card">
          <h1 className="auth__title">{title}</h1>
          {lead && <p className="auth__lead">{lead}</p>}
          {children}
        </div>
      </div>
    </main>
  );
}
