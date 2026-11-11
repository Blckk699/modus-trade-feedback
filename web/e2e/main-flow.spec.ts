import { expect, test, type Page } from '@playwright/test';

/**
 * Основной сценарий (SPEC, «Клиенты»: вход, подача, смена статуса, просмотр результата) под двумя пользователями:
 * сотрудник закупок подаёт обращение, руководитель закупок (ответственный по категории) берёт его,
 * задаёт вопрос, автор отвечает, руководитель переводит в работу и отмечает реализованным, автор видит результат.
 */

const AUTHOR = 'Айгерим Нурланова';
const ASSIGNEE = 'Марат Сейткали';
const CATEGORY = 'Межотдельное взаимодействие';

async function loginAs(page: Page, name: string) {
  await page.goto('/');
  await page.evaluate(() => localStorage.removeItem('modus.access_token'));
  await page.goto('/');
  await page.locator('.dev-login__user', { hasText: name }).click();
  await expect(page.getByRole('button', { name: 'Выйти' })).toBeVisible();
}

async function act(page: Page, action: string, text: string | null, submit: string) {
  await page.locator('.actions__buttons').getByRole('button', { name: action }).click();
  const form = page.locator('.actions__form');
  if (text !== null) await form.locator('textarea').first().fill(text);
  await form.getByRole('button', { name: submit }).click();
  await expect(form).toBeHidden();
}

const status = (page: Page) => page.locator('.appeal__head');

test('подал — взяли — уточнили — ответил — реализовано', async ({ page }) => {
  const stamp = new Date().toISOString().slice(0, 19);
  const text = `[e2e ${stamp}] В заявках на закупку нет поля «срок поставки», приходится уточнять у инициатора.`;

  // 1. Сотрудник подаёт обращение через форму.
  await loginAs(page, AUTHOR);
  await page.goto('/my/new');
  await page.locator('label.field', { hasText: 'Категория' }).getByRole('combobox').click();
  await page.getByRole('option', { name: CATEGORY }).click();
  await page.getByRole('textbox', { name: 'Описание' }).fill(text);
  await page.getByRole('button', { name: 'Отправить' }).click();
  await expect(page.getByText(/Обращение A-\d+ подано/)).toBeVisible();
  await expect(page.getByText(ASSIGNEE)).toBeVisible();
  const appealPath = await page.getByRole('link', { name: 'Открыть обращение' }).getAttribute('href');
  expect(appealPath).toMatch(/^\/appeals\/\d+$/);

  // 2. Ответственный берёт обращение и задаёт уточняющий вопрос.
  await loginAs(page, ASSIGNEE);
  await page.goto(appealPath!);
  await expect(status(page)).toContainText('Новое');
  await act(page, 'Взять на рассмотрение', null, 'Взять');
  await expect(status(page)).toContainText('На рассмотрении');
  await act(page, 'Задать уточняющий вопрос', 'Какой срок поставки обычно нужен?', 'Задать вопрос');
  await expect(status(page)).toContainText('Ожидает уточнения');

  // 3. Автор отвечает на вопрос из карточки — обращение возвращается на рассмотрение.
  await loginAs(page, AUTHOR);
  await page.goto(appealPath!);
  await expect(page.getByText('Какой срок поставки обычно нужен?').first()).toBeVisible();
  await page.getByRole('textbox', { name: 'Ответ на вопрос' }).fill('Обычно две недели.');
  await page.getByRole('button', { name: 'Ответить' }).click();
  await expect(status(page)).toContainText('На рассмотрении');

  // 4. Ответственный принимает решение и фиксирует результат.
  await loginAs(page, ASSIGNEE);
  await page.goto(appealPath!);
  await act(page, 'В работу', 'Добавим поле «срок поставки» в шаблон заявки.', 'В работу');
  await expect(status(page)).toContainText('В работе');
  await act(page, 'Реализовано', 'Поле «срок поставки» добавлено в шаблон заявки.', 'Реализовано');
  await expect(status(page)).toContainText('Реализовано');

  // 5. Автор видит результат и историю.
  await loginAs(page, AUTHOR);
  await page.goto(appealPath!);
  await expect(status(page)).toContainText('Реализовано');
  await expect(page.locator('.notice--success', { hasText: 'Результат' })).toContainText(
    'Поле «срок поставки» добавлено в шаблон заявки.',
  );
  const history = page.locator('.timeline');
  await expect(history).toContainText('Получен ответ на вопрос');
  await expect(history).toContainText('В работе → Реализовано');
});
