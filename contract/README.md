# Контракт API и мок-сервер

`openapi.yaml` — контракт API бэкенда (OpenAPI 3.0.3). Источник истины для веба, Mini App, Flutter и бота.
Продуктовые правила — в `SPEC.md`, контракт их не повторяет, а описывает запросы и ответы.

## Мок-сервер

Нужен Node.js 18+. Одна команда из корня репозитория:

```bash
npx -y @stoplight/prism-cli@5.15.11 mock -h 0.0.0.0 -p 4010 contract/openapi.yaml
```

Или из папки `contract/` после `npm install`: `npm run mock`.

Мок слушает `http://localhost:4010`, все маршруты под `/api/v1`, например `http://localhost:4010/api/v1/me`.
С эмулятора Android хост — `http://10.0.2.2:4010`, с телефона в той же сети — IP компьютера.

### Мок не хранит состояние

**Мок ничего не запоминает.** Он отвечает примерами из контракта: созданное обращение не появится в списке,
смена статуса не изменит карточку, голос не изменит счёт. Каждый ответ — заранее записанный пример
на данных датасета (A-001…A-020). На моке проверяются экраны и правильность запросов; поведение —
на реальном сервере в тикетах интеграции (W-10, F-10, T-08, W-09, F-09, T-07).

### Что умеет мок

- **Проверяет запросы по контракту.** Неверное тело, лишний или пропущенный обязательный параметр — ответ 422 или 400.
  Это главный способ убедиться, что клиент шлёт то, что ждёт бэкенд.
- **Проверяет наличие авторизации.** Без `Authorization: Bearer <любой токен>` (или пары `X-Service-Key` + `X-Telegram-Id`
  для бота) — 401. Значение токена мок не проверяет: подойдёт токен из `POST /api/v1/auth/dev/login`.
- **Отдаёт другой пример** по заголовку `Prefer: example=<имя>`. Имена примеров — в `openapi.yaml` (`examples:`). Например:
  - `GET /api/v1/me` + `Prefer: example=owner` — собственник вместо сотрудника;
  - `GET /api/v1/appeals/{id}` + `Prefer: example=rejected` | `implemented` | `participant_view`;
  - `POST /api/v1/auth/code` + `Prefer: code=401` — неверный код.
- **Отдаёт ошибку** по заголовку `Prefer: code=<статус>`, например `Prefer: code=409` на `POST /api/v1/appeals/{id}/reject`
  вернёт `invalid_transition`, `Prefer: code=503` на `POST /api/v1/drafts/text` — `ai_unavailable`.
- CORS открыт, веб на любом порту может ходить в мок напрямую.

## Главное о контракте

- **Базовый адрес** клиента — хост без префикса (`http://localhost:4010`, позже — адрес сервера);
  пути в контракте уже начинаются с `/api/v1`.
- **Авторизация пользователя**: `Authorization: Bearer <access_token>`. Токен выдают:
  - `POST /api/v1/auth/telegram/mini-app` — Mini App, тело `{init_data}`;
  - `POST /api/v1/auth/telegram/widget` — Telegram Login в вебе, тело — поля колбэка виджета как есть;
  - `POST /api/v1/auth/code` — мобильное приложение, одноразовый код из бота;
  - `POST /api/v1/auth/dev/login` — dev-вход с выбором пользователя из `GET /api/v1/auth/dev/users`.
    На сервере для демо выключен (`403 dev_login_disabled`).
- **Бот** вызывает те же пользовательские маршруты с `X-Service-Key` и `X-Telegram-Id` пользователя —
  бэкенд проверяет права как для самого пользователя. Опознать пользователя: `GET /api/v1/me`
  (`403 user_not_registered` / `user_disabled`). Только боту: `POST /api/v1/auth/login-codes`, `/api/v1/bot/*`.
- **Права в клиенте не вычисляются.** Навигация — по `Me.permissions`, кнопки в карточке — по `Appeal.allowed_actions`,
  в обсуждении — по `can_vote` / `can_close` / `can_set_name_consent`, склейка — по `DuplicateSuggestion.can_merge`.
- **Статусы и типы** — латинские коды; русские подписи и таблица переходов — `GET /api/v1/dictionaries`.
- **Ошибки** всегда `{"error": {"code", "message", "details"}}`. `message` — готовый текст для пользователя,
  ветвиться только по `code`. Список кодов — схема `ErrorCode`.
- **Время** — ISO 8601 со смещением `+05:00` (часовой пояс системы UTC+5).
- **Уведомления**: бот забирает `GET /api/v1/bot/notifications/pending`, отправляет и подтверждает `.../ack`
  (или `.../fail` — повторится позже). Кнопки уведомления — `buttons[]` с `type`. Ответ на уточняющий вопрос бот
  отправляет как `POST /api/v1/appeals/{id}/messages` от имени автора, согласие на имя — `POST /api/v1/discussions/{id}/name-consent`.
  Клиенты показывают счётчик `GET /api/v1/notifications/unread-count` и сбрасывают его `POST /api/v1/notifications/read`.
- **Черновик из бота** (`POST /api/v1/drafts/text`, `/drafts/voice`) ничего не создаёт: автор правит поля
  и отправляет `POST /api/v1/appeals` с `source=bot`. При `503 ai_unavailable` — предложить форму в Mini App.
- **Совещание** обрабатывается в фоне: `POST /api/v1/meetings` отвечает `202` со `status=processing`,
  клиент опрашивает `GET /api/v1/meetings/{id}`, пока не `ready` или `failed`.

## Генерация клиентов

- TypeScript (веб, Mini App): `npx openapi-typescript contract/openapi.yaml -o src/api/schema.d.ts` и `openapi-fetch`,
  либо любой генератор на свой вкус.
- Dart (Flutter): `openapi-generator-cli generate -i contract/openapi.yaml -g dart-dio -o lib/api`
  или ручные модели по схемам.
- Python (бот): ручной клиент на `httpx` или `datamodel-code-generator` для моделей.

## Правила изменения контракта

- **Контракт меняет только пачка бэкенда.** Клиенту нужно изменение — `question` агенту `modus-back` с копией
  `modus-orch` и точным описанием: маршрут, поле, тип, зачем.
- Изменение контракта идёт отдельным PR бэкенда в `main`. После мержа бэкенд сообщает всем пачкам
  через `broadcast`, что поменялось. Клиенты подтягивают `main` перед каждым тикетом.
- Совместимые изменения (новый маршрут, новое необязательное поле) — без согласования. Несовместимые
  (переименование, удаление, смена типа) — только после согласования с оркестратором.
- Перед PR: `npm run lint` и проверка примеров
  `uv run --with pyyaml --with jsonschema python scripts/check_examples.py` (из папки `contract/`).
- `npm run docs` собирает HTML-документацию в `dist/index.html`.
