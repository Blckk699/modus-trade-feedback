"""Проверка настоящих внешних сервисов: Claude, ElevenLabs, Битрикс24.

Ключи берутся из окружения, как у приложения. Печатает только результат и время: никаких ключей,
адресов и ответов сервисов. Код выхода 1, если хотя бы одна проверка упала.

    docker compose exec api python -m scripts.smoke_external

Битрикс24 без `BITRIX24_WEBHOOK_URL` пропускается. Иначе в тестовом портале создаётся настоящая задача
с заголовком из `BITRIX_TITLE`. Образец речи синтезирован программно, настоящих голосов в нём нет.
"""

from __future__ import annotations

import asyncio
import sys
import time
from collections.abc import Awaitable, Callable
from pathlib import Path

from app.config import Settings
from app.container import Services, build_services
from app.errors import AppError

SAMPLE = Path(__file__).with_name("smoke_sample.wav")
DRAFT_TEXT = "В заявках на оборудование не хватает назначения изделия, приходится уточнять вручную."
CATEGORIES = ["Межотдельное взаимодействие", "Интеграции и IT"]
BITRIX_TITLE = "Проверка интеграции: можно удалить"

Report = Callable[[str], None]


async def _claude(services: Services) -> None:
    draft = await services.claude.draft_appeal(DRAFT_TEXT, CATEGORIES)
    if not draft.summary.strip():
        raise ValueError("пустой черновик")


async def _speech(services: Services) -> None:
    transcript = await services.speech.transcribe(SAMPLE.read_bytes(), filename=SAMPLE.name, content_type="audio/wav")
    if not transcript.text.strip():
        raise ValueError("пустая расшифровка")


async def _bitrix(services: Services) -> None:
    task = await services.bitrix.create_task(title=BITRIX_TITLE, description="Автоматическая проверка подключения.", deadline=None)
    if not task.id:
        raise ValueError("нет идентификатора задачи")


async def _check(name: str, step: Callable[[], Awaitable[None]], report: Report) -> bool:
    started = time.monotonic()
    try:
        await step()
    except Exception as exc:  # noqa: BLE001 — текст исключения может содержать адрес вебхука или ключ
        reason = exc.code if isinstance(exc, AppError) else type(exc).__name__
        report(f"{name}: ошибка ({reason}), {time.monotonic() - started:.1f} с")
        return False
    report(f"{name}: ok, {time.monotonic() - started:.1f} с")
    return True


async def run_checks(services: Services, settings: Settings, report: Report = print) -> int:
    results = [
        await _check("Claude", lambda: _claude(services), report),
        await _check("ElevenLabs", lambda: _speech(services), report),
    ]
    if settings.bitrix24_webhook_url:
        results.append(await _check("Битрикс24", lambda: _bitrix(services), report))
    else:
        report("Битрикс24: пропущено (нет BITRIX24_WEBHOOK_URL)")
    return 0 if all(results) else 1


async def _main() -> int:
    settings = Settings()
    services = build_services(settings)
    try:
        return await run_checks(services, settings)
    finally:
        await services.aclose()


if __name__ == "__main__":
    sys.exit(asyncio.run(_main()))
