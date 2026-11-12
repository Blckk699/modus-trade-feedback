/** Настройки окружения. Значения задаются в web/.env (см. .env.example). */
const env = import.meta.env;

export const config = {
  /** Хост API без /api/v1: мок http://localhost:4010 или реальный сервер. */
  apiBaseUrl: (env.VITE_API_BASE_URL as string | undefined)?.replace(/\/$/, '') || 'http://localhost:4010',
  /** Показывать dev-вход. На сервере для демо выключен и там же бэкенд отвечает 403 dev_login_disabled. */
  devLogin: env.VITE_DEV_LOGIN === 'true',
  /** Имя бота для виджета Telegram Login, без @. */
  telegramBotUsername: (env.VITE_TELEGRAM_BOT_USERNAME as string | undefined) || '',
  /** Только для мока: имя примера /me (заголовок Prefer). Мок без состояния и не помнит, под кем вход. */
  mockMeExample: (env.VITE_MOCK_ME_EXAMPLE as string | undefined) || '',
  /** Только для локальной проверки экранов: вход по почте на моке в памяти вместо API. На сервере не задаётся. */
  emailAuthMock: env.VITE_EMAIL_AUTH_MOCK === 'true',
  /** Только для локальной проверки экранов: вход через Битрикс24 без портала и бэкенда B-23. */
  bitrixAuthMock: env.VITE_BITRIX_AUTH_MOCK === 'true',
  /** Только для локальной проверки: переключатель ролей на dev-пользователях вместо API. На сервере не задаётся. */
  roleSwitchMock: env.VITE_ROLE_SWITCH_MOCK === 'true',
};
