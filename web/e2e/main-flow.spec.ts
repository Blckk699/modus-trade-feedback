import { expect, test, type Page } from '@playwright/test';

/**
 * Основной сценарий (SPEC, «Клиенты»: вход, подача, смена статуса, просмотр результата) под двумя пользователями:
 * сотрудник закупок подаёт обращение, руководитель закупок (ответственный по категории) берёт его,
 * задаёт вопрос, автор отвечает, руководитель переводит в работу и отмечает реализованным, автор видит результат.
 * Элементы ищутся по ролям и подписям — так тест не зависит от классов вёрстки.
 */

const AUTHOR = 'Айгерим Нурланова';
const ASSIGNEE = 'Марат Сейткали';
const CATEGORY = 'Межотдельное взаимодействие';

async function loginAs(page: Page, name: string) {
  await page.goto('/');
  await page.evaluate(() => localStorage.removeItem('modus.access_token'));
  await page.goto('/');
  await page.getByRole('button', { name: new RegExp(`^${name}`) }).click();
  await expect(page.getByRole('button', { name: 'Выйти' })).toBeVisible();
}

/** Действие из строки «Действия»: кнопка открывает окно с формой, отправка его закрывает. */
async function act(page: Page, action: string, text: string | null, submit: string) {
  await page.getByRole('group', { name: 'Действия' }).getByRole('button', { name: action }).click();
  const dialog = page.getByRole('dialog');
  await expect(dialog).toBeVisible();
  if (text !== null) await dialog.getByRole('textbox').first().fill(text);
  await dialog.getByRole('button', { name: submit, exact: true }).click();
  await expect(dialog).toBeHidden();
}

const state = (page: Page) => page.getByRole('group', { name: 'Состояние обращения' });

test('подал — взяли — уточнили — ответил — реализовано', async ({ page }) => {
  const stamp = new Date().toISOString().slice(0, 19);
  const text = `[e2e ${stamp}] В заявках на закупку нет поля «срок поставки», приходится уточнять у инициатора.`;

  // 1. Сотрудник подаёт обращение через форму.
  await loginAs(page, AUTHOR);
  await page.goto('/my/new');
  await page.getByRole('combobox', { name: /Категория/ }).click();
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
  await expect(state(page)).toContainText('Новое');
  await act(page, 'Взять на рассмотрение', null, 'Взять');
  await expect(state(page)).toContainText('На рассмотрении');
  await act(page, 'Задать уточняющий вопрос', 'Какой срок поставки обычно нужен?', 'Задать вопрос');
  await expect(state(page)).toContainText('Ожидает уточнения');

  // 3. Автор отвечает на вопрос из карточки — обращение возвращается на рассмотрение.
  await loginAs(page, AUTHOR);
  await page.goto(appealPath!);
  await expect(page.getByText('Какой срок поставки обычно нужен?').first()).toBeVisible();
  await page.getByRole('textbox', { name: 'Ответ на вопрос' }).fill('Обычно две недели.');
  await page.getByRole('button', { name: 'Ответить' }).click();
  await expect(state(page)).toContainText('На рассмотрении');

  // 4. Ответственный принимает решение и фиксирует результат.
  await loginAs(page, ASSIGNEE);
  await page.goto(appealPath!);
  await act(page, 'В работу', 'Добавим поле «срок поставки» в шаблон заявки.', 'В работу');
  await expect(state(page)).toContainText('В работе');
  await act(page, 'Реализовано', 'Поле «срок поставки» добавлено в шаблон заявки.', 'Реализовано');
  await expect(state(page)).toContainText('Реализовано');

  // 5. Автор видит результат и историю.
  await loginAs(page, AUTHOR);
  await page.goto(appealPath!);
  await expect(state(page)).toContainText('Реализовано');
  await expect(page.getByRole('region', { name: 'Результат' })).toContainText('Поле «срок поставки» добавлено в шаблон заявки.');
  const history = page.getByRole('list', { name: 'История' });
  await expect(history).toContainText('Получен ответ на вопрос');
  await expect(history).toContainText('В работе → Реализовано');
});
