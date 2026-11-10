# klinduhwtf: пачка фронта

Ваш агент на шине — `modus-front`. Он делает веб-приложение на React и TypeScript; те же экраны открываются внутри Telegram как Mini App.

## Что у вас будет

- Приглашение в репозиторий `Blckk699/modus-trade-feedback` — придёт письмом от GitHub, примите его.
- Файл `modus-front.token` — Александр передаст лично. Это пароль агента: никому не пересылайте и не показывайте агенту.

## Подключение (10 минут)

Пошагово — в `bus/README.md`. Коротко:

```bash
git clone https://github.com/Blckk699/modus-trade-feedback.git
cd modus-trade-feedback
sh bus/setup-bus.sh ~/.config/modus-bus/modus-front.token
```

На Windows вместо последней строки:

```powershell
powershell -ExecutionPolicy Bypass -File bus\setup-bus.ps1 $env:USERPROFILE\.config\modus-bus\modus-front.token
```

Откройте Claude Code в папке репозитория и проверьте `/mcp`: сервер `bus` должен быть подключён.

## Стартовое сообщение агенту

Скопируйте целиком:

> Ты агент `modus-front`, пачка фронта (веб и экраны Mini App). Прочитай `CLAUDE.md`, `SPEC.md` и `tickets/README.md`. Отметься на шине: `bus_status(state="idle", model=<твой полный id модели>, machine=<имя машины>)`, затем проверь почту `bus_inbox`. Свои тикеты бери по `gh issue list --label agent:modus-front --label ready-for-agent`, только те, у которых закрыты все блокеры. Первый — W-01, он ждёт контракт API и мок-сервер из B-01: пока их нет, жди в `bus_wait` сообщения от `modus-back` и не придумывай контракт сам. Работай по правилам из `CLAUDE.md`: одна ветка и один PR на тикет, `pr_ready` ревьюеру, свой PR не мержишь, на сервер не ходишь.

## Что важно именно для фронта

- Пока бэкенда нет, работайте на мок-сервере из контракта. Мок не хранит состояние: тикет на моке закрывается, когда экраны готовы и отправляют правильные запросы; поведение проверяется позже в W-10 и W-09.
- Локально и на моке входите через dev-вход. Telegram Login заработает только на настоящем домене (W-10).
- Модуль входа держите отдельно: в него встроится вход Mini App из пачки Telegram (T-06).
- Нужна правка контракта — вопрос через шину агенту `modus-back` с копией `modus-orch`.
