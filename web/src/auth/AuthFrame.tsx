import type { ReactNode } from 'react';
import { BrandLogo } from '../app/BrandLogo';
import { DotNumber } from '../app/DotNumber';
import { AuthScene } from './AuthScene';

/**
 * Рамка экранов до входа: вход, заявка на доступ, приглашение. Слева — фирменная панель с логотипом
 * декоративной фигурой и коротким описанием продукта, справа — содержимое экрана. На телефоне панель сжимается в шапку.
 */
export function AuthFrame({ title, lead, children }: { title: string; lead?: ReactNode; children: ReactNode }) {
  return (
    <main className="auth">
      <aside className="auth__brand">
        <AuthScene />
        <span className="auth__logo">
          <BrandLogo />
        </span>
        <div className="auth__pitch">
          <p className="auth__headline">У каждого обращения есть ответственный и срок ответа.</p>
          <ul className="auth__points">
            <li>
              <DotNumber className="auth__num" value="1" label="1." />
              <span>Проблемы, идеи и благодарности коллегам принимаются на сайте и в Telegram, текстом или голосом.</span>
            </li>
            <li>
              <DotNumber className="auth__num" value="2" label="2." />
              <span>Обращение попадает к ответственному за тему. Без ответа в срок оно уходит руководителю.</span>
            </li>
            <li>
              <DotNumber className="auth__num" value="3" label="3." />
              <span>Повторы объединяются, спорные предложения выносятся на голосование, итоги видны в сводке.</span>
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
