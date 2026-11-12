import { expect, test } from '@playwright/test';

/**
 * Вход и регистрация по почте (W-13, истории 75–77) против настоящего бэкенда с B-20.
 * Нужна демо-учётка с почтой: E2E_EMAIL и E2E_PASSWORD (сид берёт их из настройки вне репозитория).
 * Без них тесты пропускаются. Регистрация создаёт в базе новую заявку с пометкой e2e.
 */
const EMAIL = process.env.E2E_EMAIL ?? '';
const PASSWORD = process.env.E2E_PASSWORD ?? '';

test.skip(!EMAIL || !PASSWORD, 'нет E2E_EMAIL и E2E_PASSWORD');

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => localStorage.removeItem('modus.access_token'));
  await page.goto('/');
});

test('неверный пароль не пускает, верный — пускает, в профиле видна почта', async ({ page }) => {
  await page.getByRole('textbox', { name: 'Рабочая почта' }).fill(EMAIL);
  await page.getByLabel('Пароль', { exact: true }).fill(`${PASSWORD}-не-тот`);
  await page.getByRole('button', { name: 'Войти', exact: true }).click();
  await expect(page.getByText('Неверная почта или пароль.')).toBeVisible();

  await page.getByLabel('Пароль', { exact: true }).fill(PASSWORD);
  await page.getByRole('button', { name: 'Войти', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Выйти' })).toBeVisible();

  await page.goto('/profile');
  await expect(page.getByText(EMAIL, { exact: false }).first()).toBeVisible();
  await expect(page.getByRole('button', { name: 'Сменить пароль' })).toBeVisible();
});

test('регистрация создаёт заявку: до одобрения вход отвечает «Заявка на рассмотрении»', async ({ page }) => {
  const stamp = Date.now();
  const email = `e2e-${stamp}@modus.example`;
  const password = `e2e-pass-${stamp}`;

  await page.getByRole('link', { name: 'Зарегистрироваться' }).click();
  await page.getByLabel('Имя и фамилия').fill(`e2e Проверка ${stamp}`);
  await page.getByRole('textbox', { name: 'Рабочая почта' }).fill(email);
  await page.getByLabel('Пароль', { exact: true }).fill(password);
  await page.getByRole('button', { name: 'Отправить заявку' }).click();
  await expect(page.getByRole('heading', { name: 'Заявка на рассмотрении' })).toBeVisible();

  await page.getByRole('link', { name: 'Ко входу' }).click();
  await page.getByRole('textbox', { name: 'Рабочая почта' }).fill(email);
  await page.getByLabel('Пароль', { exact: true }).fill(password);
  await page.getByRole('button', { name: 'Войти', exact: true }).click();
  await expect(page.getByRole('alert').filter({ hasText: 'Заявка на рассмотрении' })).toBeVisible();
});
