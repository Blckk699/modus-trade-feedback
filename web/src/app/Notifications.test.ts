import { describe, expect, it } from 'vitest';
import { notificationTarget, plainText } from './Notifications';

describe('текст уведомления в списке', () => {
  it('убирает разметку Telegram и сохраняет строки', () => {
    expect(plainText('Обращение <b>A-024</b> зарегистрировано.\nОтветственный: <i>Олжас</i><br>Срок: 17.11')).toBe(
      'Обращение A-024 зарегистрировано.\nОтветственный: Олжас\nСрок: 17.11',
    );
  });

  it('раскрывает сущности после снятия тегов, а не до', () => {
    expect(plainText('A &amp; B &lt;script&gt; &quot;x&quot;')).toBe('A & B <script> "x"');
  });

  it('схлопывает лишние пробелы и пустые строки', () => {
    expect(plainText('  раз   два \n\n три ')).toBe('раз два\nтри');
  });
});

describe('куда ведёт уведомление', () => {
  const appeal = { id: 21, number: 'A-021', summary: null, status: 'new', type: 'problem' } as const;

  it('маршрут контракта /analytics — на сводку', () => {
    expect(notificationTarget({ path: '/analytics', appeal: null })).toBe('/digest');
  });

  it('обычный маршрут — как есть', () => {
    expect(notificationTarget({ path: '/discussions/5', appeal })).toBe('/discussions/5');
  });

  it('без маршрута — карточка обращения, а без обращения — никуда', () => {
    expect(notificationTarget({ path: null, appeal })).toBe('/appeals/21');
    expect(notificationTarget({ path: null, appeal: null })).toBeNull();
  });
});
