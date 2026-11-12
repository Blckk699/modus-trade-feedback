import { renderToStaticMarkup } from 'react-dom/server';
import { StaticRouter } from 'react-router-dom/server';
import { describe, expect, it } from 'vitest';
import { BitrixDoneView } from './BitrixDoneScreen';

const render = (view: Parameters<typeof BitrixDoneView>[0]['view']) =>
  renderToStaticMarkup(
    <StaticRouter location="/auth/bitrix/done">
      <BitrixDoneView view={view} />
    </StaticRouter>,
  );

describe('экран возврата из Битрикс24', () => {
  it('пока меняем код на сессию — «Входим…» без кнопки', () => {
    const html = render({ kind: 'busy' });
    expect(html).toContain('Входим…');
    expect(html).not.toContain('Ко входу');
  });

  it.each([
    [{ kind: 'pending' } as const, 'Заявка на рассмотрении', 'notice--warn'],
    [{ kind: 'rejected', reason: 'Нет в штате' } as const, 'Причина: Нет в штате', 'notice--danger'],
    [{ kind: 'disabled' } as const, 'Доступ отключён', 'notice--danger'],
    [{ kind: 'cancelled' } as const, 'Вход отменён', 'notice--warn'],
    [{ kind: 'error', message: 'Ссылка устарела' } as const, 'Ссылка устарела', 'notice--danger'],
    [{ kind: 'error', message: null } as const, 'Не удалось войти', 'notice--danger'],
  ])('%o: объяснение и путь назад ко входу', (view, text, tone) => {
    const html = render(view);
    expect(html).toContain(text);
    expect(html).toContain(tone);
    expect(html).toContain('role="alert"');
    expect(html).toContain('Ко входу');
  });
});
