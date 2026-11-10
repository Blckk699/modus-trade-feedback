# Бот «Модус Трейд»

aiogram 3 + httpx, Python 3.12, зависимости через `uv`. Что строим — `../SPEC.md`, контракт — `../contract/openapi.yaml`.

Бот ходит в API от имени пользователя: заголовки `X-Service-Key` (ключ бота) и `X-Telegram-Id`.
Права проверяет бэкенд; бот показывает то, что разрешает `GET /api/v1/me`.

Настройка продуктового бота в @BotFather и окружение на сервере — [BOTFATHER.md](BOTFATHER.md).

## Запуск

```sh
cd bot
uv sync
cp .env.example .env     # TELEGRAM_BOT_TOKEN, BOT_SERVICE_KEY, API_BASE_URL, MINI_APP_URL
uv run python -m app
```

Без `TELEGRAM_BOT_TOKEN` или `BOT_SERVICE_KEY` бот сообщает, что не настроен, и выходит с кодом 2.
`MINI_APP_URL` (HTTPS) включает кнопку меню чата «Открыть» и кнопку «Мои обращения».

Docker: `docker build -t modus-bot . && docker run --env-file .env modus-bot`.

## Тесты

```sh
uv run pytest
```

Сеть не нужна: Telegram подменён сессией aiogram (`app/fake_telegram.py`), API — `httpx.MockTransport`
(`tests/support.py`). Тест подаёт обновление Telegram и смотрит, что ушло в API и что бот отправил.

## E2E против настоящего бэкенда

```sh
uv run pytest e2e          # ~5–10 с: поднимает backend на временной базе (uv run --project ../backend)
```

`e2e/backend_server.py` запускает бэкенд из `../backend` на временном Postgres (`pgserver`). Он загружает сид демо-компании, у демо-пользователей Telegram ID `100000001…`, ключ бота `e2e-service-key`. Claude, ElevenLabs, Telegram и Битрикс24 внутри бэкенда заменены фейками. Бот работает с настоящим HTTP API, фейк у него только один — Telegram. Что проверяется:
- опознание сотрудника и отказ постороннему;
- код входа, который принимает `POST /auth/code` (один раз);
- подача текстом и голосом с номером, ответственным и сутью;
- уведомления из очереди: доставка, `ack`, после чего очередь пуста;
- вопрос ответственного → «Ответить» в боте → обращение «На рассмотрении», ответ в переписке, уведомление ответственному;
- «Мои обращения»;
- согласие на имя: обсуждение, вынесенное ответственным → «Показать имя» в боте → `author_name_consent=shown`;
- сводка по `/digest` с кнопкой аналитики; сотруднику без прав — «недоступна»;
- утренняя рассылка: время сводки ставится на «сейчас», задача `digest.check` запускается сразу (служебный
  маршрут `/e2e/run-job/{kind}` есть только в e2e-сервере) → сводка приходит собственнику и руководителям, сотруднику — нет.

Против уже запущенного бэкенда: `E2E_API_URL=http://127.0.0.1:8765 uv run pytest e2e`.

## Прогон на моке

```sh
npx -y @stoplight/prism-cli@5.15.11 mock -h 127.0.0.1 -p 4011 ../contract/openapi.yaml
uv run python -m scripts.smoke_mock http://127.0.0.1:4011
```

Подача обращения: любой текст или пересланное сообщение → `POST /api/v1/drafts/text` → карточка черновика
(тип, категория, приоритет, суть) с кнопками «Отправить», «Тип», «Категория», «Приоритет», «Поправить текст»,
«Поправить суть», «Отменить» → `POST /api/v1/appeals` с `source=bot`. Черновик хранится в памяти бота (FSM aiogram)
и после перезапуска теряется. При `503 ai_unavailable` бот предлагает форму в Mini App.
Голосовое (или аудиофайл): бот показывает «Расшифровываю…» и статус «печатает», скачивает файл из Telegram и
отправляет multipart в `POST /api/v1/drafts/voice`. Дальше идёт та же карточка, только с расшифровкой. Голосовое длиннее 5 минут
отклоняется сразу, ответы `audio_empty` и `audio_too_long` бот показывает как есть.

Уведомления: фоновая задача раз в `NOTIFICATIONS_POLL_SECONDS` забирает `GET /api/v1/bot/notifications/pending`
(только `X-Service-Key`), отправляет `text` получателю и подтверждает `ack` с `telegram_message_id`. При сбое бот
отправляет `fail`, и бэкенд повторит уведомление позже. Если пользователь заблокировал бота — `fail` с `permanent=true`.
Кнопки уведомления: `open_*` открывают Mini App (`<MINI_APP_URL>/appeals/{id}`), «Ответить» ждёт ответ следующим
сообщением, причём ответить можно и свайпом на вопрос (`POST /appeals/{id}/messages`). «Показать имя» и «Скрыть» вызывают
`POST /discussions/{id}/name-consent`.

Сводка: команда `/digest` или кнопка «Сводка» (видна при `analytics_scope` ≠ `none`) вызывает `GET /api/v1/analytics/digest`
и присылает `text` как есть с кнопкой «Открыть аналитику» (Mini App `/analytics`). При `403` бот отвечает, что сводка
доступна руководителям и собственнику. Утренняя сводка приходит через очередь уведомлений (`kind=digest`, рассылку по
расписанию ведёт бэкенд); если в ней нет кнопки, бот добавляет «Открыть аналитику».

## Устройство

```
app/
  __main__.py       точка входа: python -m app
  main.py           build_dispatcher(api, settings), build_bot(token), запуск long polling
  config.py         настройки из окружения (.env.example)
  api.py            клиент API, ApiError по формату ошибки контракта
  middleware.py     IdentifyUser: GET /me перед каждым обновлением, отказ постороннему
  handlers.py       меню: /start, код входа, мои обращения, сводка; fallback последним
  drafts.py         подача текстом и пересылкой: черновик → правка кнопками → POST /appeals
  formatting.py     карточка черновика, созданное обращение, список «Мои обращения»
  notifications.py  очередь уведомлений (deliver_pending, poll_forever), ответ на вопрос, согласие на имя
  keyboards.py      клавиатуры по Me.permissions
  texts.py          тексты и подписи кнопок
  fake_telegram.py  фейк Bot API для тестов и прогона на моке
```

Кнопки меню: «Подать обращение», «Мои обращения» (номера и статусы, `GET /appeals?scope=mine`), «Сводка» (если
`permissions.analytics_scope` не `none`), «Код входа». Название «Код входа» упоминает экран входа
мобильного приложения — не переименовывать без `modus-flutter`.
