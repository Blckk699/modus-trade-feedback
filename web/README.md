# Веб и экраны Mini App

React + TypeScript + Vite. Одни и те же экраны открываются в браузере и в Telegram Mini App на ширине телефона.

## Запуск на моке

Нужен Node.js 18+. Из корня репозитория:

```bash
npx -y @stoplight/prism-cli@5.15.11 mock -h 0.0.0.0 -p 4010 contract/openapi.yaml
```

В другом терминале:

```bash
cd web
cp .env.example .env
npm install
npm run dev
```

Откройте http://localhost:5173 и войдите через dev-вход.

## Настройки (`web/.env`)

| Переменная | Что задаёт |
|---|---|
| `VITE_API_BASE_URL` | Хост API без `/api/v1`: мок `http://localhost:4010`, локальный бэкенд `http://localhost:8000` или адрес сервера |
| `VITE_DEV_LOGIN` | `true` — показывать dev-вход. На сервере для демо `false`, бэкенд там же отвечает `403 dev_login_disabled` |
| `VITE_TELEGRAM_BOT_USERNAME` | Имя бота без `@` для виджета Telegram Login. Пусто — виджет скрыт. Виджет работает только на домене, привязанном к боту |
| `VITE_MOCK_ME_EXAMPLE` | Только для мока: пример `GET /me` (`owner`). Мок не помнит, под кем вход, и по умолчанию отдаёт сотрудника |

## Команды

- `npm run dev` — dev-сервер.
- `npm run build` — проверка типов и сборка в `dist/`.
- `npm test` — тесты.
- `npm run gen:api` — пересобрать `src/api/schema.d.ts` из `contract/openapi.yaml`. Запускать после каждого обновления контракта.

## Устройство

- `src/api/` — клиент API: `openapi-fetch` с типами из контракта. `unwrap()` возвращает данные или бросает `ApiError` с `code` и `message` из ответа.
- `src/auth/` — модуль входа. Экраны о способах входа не знают.
  - `methods/index.ts` — список способов: Telegram Login, dev-вход.
  - Способ входа — объект `AuthMethod`: `autoLogin` для входа без участия пользователя, `LoginButton` для экрана входа.
  - **Вход Mini App (T-06):** добавьте `methods/miniApp.ts` с `autoLogin` по `Telegram.WebApp.initData` → `POST /api/v1/auth/telegram/mini-app` и поставьте его первым в список. Экраны править не нужно.
- `src/app/navigation.ts` — разделы по `Me.permissions` и стартовый экран роли. Права клиент не вычисляет.
- `src/app/dictionaries.tsx` — русские подписи статусов, типов и ролей из `GET /api/v1/dictionaries`.
- `src/styles/global.css` — токены темы. Светлая и тёмная тема: по системе или переключателем в шапке. Оболочка Mini App может переопределить переменные цветами Telegram.
