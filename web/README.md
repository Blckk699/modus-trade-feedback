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

## Mini App (T-06)

Та же сборка открывается в Telegram как Mini App. Скрипт `telegram-web-app.js` подключён в `index.html`. Если в `Telegram.WebApp.initData` пусто, то это обычный браузер, и всё работает как раньше.

- Вход: `auth/methods/miniApp.ts` идёт первым в `authMethods` и отправляет `initData` в `POST /api/v1/auth/telegram/mini-app`. При отказе (`401`/`403`) показывается экран входа с `message`.
- Оболочка `telegram/MiniAppShell.tsx` (в `App` рядом с `AuthGate`, вне Telegram ничего не делает):
  - вызывает `ready()` и `expand()`;
  - берёт тему из `themeParams` (`telegram/theme.ts`, переменные из `global.css`) и обновляет её по `themeChanged`;
  - показывает кнопку «Назад» Telegram, когда в истории есть куда вернуться (`navigate(-1)`).
- Ссылки из бота (`telegram/startParam.ts`): `startapp` — это маршрут контракта (`Notification.path`), в котором `/` заменён на `_`. Например, `appeals_21` → `/appeals/21`, `discussions_5` → `/discussions/5`, `analytics` → `/digest`. Inline-кнопка `web_app` в боте может вести сразу на путь: `<MINI_APP_URL>/appeals/21`.
- Проверка в браузере без Telegram: откройте `http://localhost:5173/#tgWebAppData=<urlencoded initData>&tgWebAppVersion=8.0&tgWebAppPlatform=ios&tgWebAppThemeParams=<urlencoded JSON>`. Мок принимает любые `initData`.

## Сквозной прогон (W-09)

Основной сценарий «подал — взяли — уточнили — ответил — реализовано» под двумя пользователями (сотрудник закупок и руководитель закупок) в браузере, против настоящего бэкенда с dev-входом. Браузер — установленный Chrome, Playwright его не скачивает.

```bash
# 1. Бэкенд с dev-входом (Postgres поднимется сам)
cd backend && uv sync && DEV_LOGIN_ENABLED=true uv run python scripts/dev.py
```

```bash
# 2. Веб через прокси на бэкенд: в web/.env
#    VITE_API_BASE_URL=http://localhost:5173
#    VITE_API_PROXY=http://127.0.0.1:8000
#    VITE_DEV_LOGIN=true
cd web && npm run dev
```

```bash
# 3. Прогон
cd web && npm run e2e
```

Каждый прогон создаёт новое обращение с пометкой `[e2e …]`. Сбросить демо-данные: `cd backend && uv run python scripts/dev.py python -m app.seed reset`. Другой адрес веба — `E2E_BASE_URL`, другой браузер — `E2E_CHANNEL` (например `msedge`).

Нет установленного Chrome — возьмите Chromium из Playwright:

```bash
cd web && npx playwright install chromium && E2E_CHANNEL=chromium npm run e2e
```

Прогон проверен и на текущей вёрстке, и на ветке дизайнера с формами действий в модальном окне (`web/design-next-4`, #141): кнопки ищутся в `.actions__buttons`, форма — `.actions__form` в обоих вариантах.
