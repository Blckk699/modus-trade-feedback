# Бэкенд «Модус Трейд»

FastAPI + Postgres (SQLAlchemy 2 async, asyncpg, Alembic), Python 3.12, зависимости через `uv`.
Что строим — `../SPEC.md`, контракт API — `../contract/openapi.yaml`.

## Запуск

**Docker** (API + Postgres, миграции применяются при старте):

```sh
cd backend
cp .env.example .env        # необязательно; ключи внешних сервисов
docker compose up --build   # http://localhost:8000/api/v1/health, документация /api/v1/docs
```

**Без docker** (Postgres поднимается из pip-пакета `pgserver`, данные в `backend/.pgdata`):

```sh
cd backend
uv sync
uv run python scripts/dev.py          # миграции + API с автоперезагрузкой на http://127.0.0.1:8000
```

Свой Postgres: `DATABASE_URL=postgresql://... uv run alembic upgrade head && uv run uvicorn --factory app.main:create_app --reload`.

## Тесты

```sh
uv run pytest
```

Postgres для тестов поднимается сам (`pgserver`, временная папка). Чтобы гонять на Postgres из compose,
заведите **отдельную** базу (тесты очищают её целиком):
`docker compose exec db createdb -U modus modus_test`, затем
`TEST_DATABASE_URL=postgresql://modus:modus@localhost:5432/modus_test uv run pytest`.

Образец теста — `tests/test_background_jobs.py::test_meeting_recording_is_processed_in_background`:
история через HTTP API, фейковый адаптер, явное управление временем.

## Устройство

```
app/
  main.py         create_app(settings, services): сборка приложения, воркер задач в lifespan
  config.py       настройки из окружения (.env.example — полный список)
  clock.py        Clock: единственный источник «сейчас»
  container.py    Services: часы и адаптеры, живёт в app.state.services
  errors.py       AppError и наследники, единый формат ошибки
  db.py           Base моделей, движок, сессии
  api/            router.py (префикс /api/v1), deps.py (зависимости), health.py
  adapters/       Claude, ElevenLabs Scribe, Telegram, Битрикс24 + fakes.py для тестов
  jobs/           очередь задач в Postgres, расписания, воркер
  domain/         перечисления домена и рабочие дни
  models/         модели всех сущностей схемы данных; __init__ импортирует их для Alembic
  seed/           демо-данные и команды init / reset
migrations/       Alembic
tests/            conftest.py (фикстуры), support.py (TimeMachine)
```

Новый модуль удобно класть пакетом по предметной области: `app/appeals/{models,service,router}.py`.
Подключение: роутер — строка в `app/api/router.py`, модели — импорт в `app/models/__init__.py`,
затем миграция: `uv run python scripts/dev.py alembic revision --autogenerate -m "appeals"`
(тест `test_migrations.py` упадёт, если модели и миграции разошлись).

## Демо-данные

Компания из датасета организаторов: 8 подразделений с руководителями, собственник, администратор,
сотрудники, 18 категорий с ответственными и заместителями, сроки по приоритетам (1/3/5 рабочих дней)
и 20 обращений A-001…A-020 с исходными типом, категорией, приоритетом, статусом и текстом.
Данные — `app/seed/data.py`, загрузка — `app/seed/loader.py`.

```bash
uv run python -m app.seed init      # загрузить, только если база пустая (так делает контейнер при старте)
uv run python -m app.seed reset     # стереть данные приложения и загрузить демо заново — перед показом
uv run python scripts/dev.py python -m app.seed reset   # то же для локальной базы из scripts/dev.py
docker compose exec api python -m app.seed reset         # то же в docker
```

- Команды `init` и `reset` добавляют витрину для показа (`app/seed/showcase.py`): открытое обсуждение
  с голосами по A-012, повторы A-021 и A-022, склеенные с A-003, и разобранную запись совещания
  у руководителя закупок. Тесты работают без неё, числа сида считаются от двадцати обращений датасета.
- **Демо-переключатель ролей.** Ключ `switch_group` в файле аккаунтов — список связанных аккаунтов
  (ключ демо-пользователя, почта или Telegram ID): участники переключаются друг на друга в шапке клиента.
  `init` и `reset` применяют группу сами; к работающей базе — `python -m app.seed link` (ничего не стирает,
  повторять можно). Без ключа переключателя нет.
- Даты отсчитываются от момента загрузки в рабочих днях: в любой день минимум три обращения
  просрочены (A-001, A-007, A-011), у остальных открытых есть время первого ответа.
- `reset` очищает все таблицы приложения (кроме расписания периодических задач), идентификаторы
  снова начинаются с 1 — повторный запуск не плодит дубли.
- **Реальные Telegram-аккаунты** задаются файлом вне репозитория: `--accounts <файл>`, переменная
  `SEED_ACCOUNTS_FILE` или `~/.config/modus-trade/seed-accounts.json`. Формат — в `app/seed/accounts.py`,
  ключи — `key` демо-пользователей из `app/seed/data.py` (`owner`, `admin`, `head_procurement`,
  `employee_procurement`, …). Без файла сид всё равно загружается и печатает, под какими ролями никто
  не сможет войти. Telegram ID сид не печатает.
- В docker файл кладётся на хост в `~/.config/modus-trade/seed-accounts.json` (или каталог из
  `SEED_ACCOUNTS_DIR`): compose монтирует каталог в контейнер только на чтение и задаёт `SEED_ACCOUNTS_FILE`.
  Положите файл до первого запуска, иначе `seed init` создаст пользователей без Telegram ID
  (исправляется `docker compose exec api python -m app.seed reset`).

## Соглашения API

- Все маршруты под `/api/v1`.
- Ошибка всегда `{"error": {"code", "message", "details"}}`, `message` по-русски. В коде поднимайте
  `NotFound`, `Forbidden`, `Unauthorized`, `Conflict`, `InvalidTransition`, `ValidationFailed`,
  `ExternalServiceError` из `app.errors` или свой наследник `AppError` с `code` и `status_code`.
  Ошибки валидации FastAPI превращаются в `422 validation_error`, неизвестные исключения — в `500 internal_error`.
- Учётные данные запроса — `CredentialsDep` из `app.api.deps`: `Authorization: Bearer <token>` либо
  `X-Service-Key` + `X-Telegram-Id` для бота. Пользователя по ним находит `current_user` (B-03).
- Зависимости маршрутов: `SessionDep`, `ClockDep`, `SettingsDep`, `ClaudeDep`, `SpeechDep`, `TelegramDep`, `BitrixDep`.

## Время

- Никакого `datetime.now()` в коде: время берётся из `ClockDep` в маршруте или `ctx.now()` в задаче.
- В базе — `timestamptz`, в коде — aware-datetime в UTC. Часовой пояс системы — `settings.tz`
  (`TIMEZONE`, по умолчанию `+05:00`); для рабочих дней и текстов: `app.clock.local(moment, settings.tz)`.
- В тестах часы заморожены на понедельнике 9 ноября 2026, 10:00 по UTC+5 (фикстура `clock`):

```python
async def test_x(client, clock, time_machine):
    clock.advance(hours=2)                                   # просто сдвинуть часы
    await time_machine.advance(days=1)                       # сдвинуть и выполнить созревшие задачи
    await time_machine.advance(days=3, step=timedelta(hours=1))  # как настоящий воркер, шагами
```

## Адаптеры внешних сервисов

Интерфейсы — `Protocol` в `app/adapters/*.py`, реальные реализации там же, фейки — `app/adapters/fakes.py`.
В тестах фейки уже подставлены фикстурами `fake_claude`, `fake_speech`, `fake_telegram`, `fake_bitrix`:

```python
async def test_draft(client, fake_claude):
    fake_claude.draft = AppealDraft(type="problem", category="IT", priority="high", summary="…", proposed_solution=None)
    fake_claude.fail = True        # сервис «упал»: следующий вызов -> ExternalServiceError (503)
    ...
    assert fake_claude.calls_to("draft_appeal")
```

Подменить адаптер в приложении одной строкой: `app.state.services.claude = MyFake()`.
Без ключа реальный адаптер не падает при старте, а отвечает `503` с понятным сообщением.

| Адаптер | Методы | Настройки |
|---|---|---|
| `ClaudeClient` | `draft_appeal`, `find_duplicates`, `extract_meeting_drafts`, `write_digest` | `ANTHROPIC_API_KEY`, `CLAUDE_MODEL` |
| `SpeechToText` | `transcribe` | `ELEVENLABS_API_KEY` |
| `TelegramGateway` | `send_message` | `TELEGRAM_BOT_TOKEN` |
| `Bitrix24Gateway` | `create_task` | `BITRIX24_WEBHOOK_URL`, `BITRIX24_RESPONSIBLE_ID` |

## Фоновые задачи

Очередь — таблица `jobs` в Postgres, воркер — цикл в процессе API (раз в `JOBS_POLL_SECONDS`).
В тестах воркер выключен, задачи выполняет `time_machine`.

Воркер выполняет задачи по одной: пока идёт долгая расшифровка записи совещания, эскалация и сводка ждут своей очереди.

Разовая задача (например, обработка записи совещания):

```python
from datetime import timedelta

from app.jobs import JobContext, enqueue, registry

@registry.job("meetings.process", stale_after=timedelta(hours=2))
async def process_meeting(ctx: JobContext, payload: dict) -> None:
    transcript = await ctx.services.speech.transcribe(...)
    ...  # пишем через ctx.session; коммит сделает механизм, при исключении — откат и повтор

# в маршруте, в той же транзакции, что и запись в базу:
await enqueue(session, "meetings.process", {"meeting_id": meeting.id}, run_at=clock.now())
```

Периодическая (эскалация, сводка):

```python
from app.jobs import DailyAt, Every, registry

@registry.periodic("escalation.check", lambda s: Every(minutes=s.escalation_interval_minutes))
async def check_escalation(ctx: JobContext, payload: dict) -> None: ...

@registry.periodic("digest.send", lambda s: DailyAt(s.digest_time))   # 09:00 по UTC+5
async def send_digest(ctx: JobContext, payload: dict) -> None: ...
```

Модуль с обработчиками добавьте импортом в `app/jobs/catalog.py`. Образец — `app/jobs/builtin.py`
(ежедневная чистка выполненных задач).

Поведение: упавшая задача повторяется через 1, 2, 4… минуты до `max_attempts` (по умолчанию 3), затем
`failed` с текстом ошибки в `last_error`. `dedup_key` не даёт поставить одну задачу дважды
(удобно для шагов эскалации: `f"escalation:{appeal_id}:{step}"`). Пропущенные запуски периодической
задачи (сервер лежал) не догоняются: она выполнится один раз и дальше по расписанию.

Задача, которая висит в `running` дольше `stale_after` (по умолчанию 30 минут), считается брошенной
упавшим процессом и возвращается в очередь. Долгим задачам задавайте свой `stale_after` больше их
реального времени работы — иначе длинная запись совещания начнёт обрабатываться второй раз.
