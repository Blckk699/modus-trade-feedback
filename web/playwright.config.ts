import { defineConfig } from '@playwright/test';

/**
 * Сквозной прогон веба (W-09) против настоящего бэкенда с dev-входом.
 * Браузер — установленный Chrome (channel: 'chrome'), отдельно скачивать Chromium не нужно.
 * Перед запуском: бэкенд на :8000 с DEV_LOGIN_ENABLED=true и веб `npm run dev` с прокси (см. web/README.md).
 * Адрес веба можно сменить: E2E_BASE_URL=https://staging.example npm run e2e.
 */
export default defineConfig({
  testDir: './e2e',
  timeout: 60_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  workers: 1,
  reporter: [['list']],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:5173',
    channel: process.env.E2E_CHANNEL ?? 'chrome',
    locale: 'ru-RU',
    timezoneId: 'Asia/Almaty',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
});
