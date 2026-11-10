"""Сборка приложения.

Запуск: `uvicorn --factory app.main:create_app`. Тесты вызывают `create_app(settings, services)`
со своими настройками, замороженными часами и фейковыми адаптерами.
"""

from __future__ import annotations

import asyncio
import contextlib
import logging
from collections.abc import AsyncIterator

from fastapi import FastAPI
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware

from app import models as _models  # noqa: F401 — все модели видны метаданным
from app.api.router import api_router
from app.config import Settings, get_settings
from app.container import Services, build_services
from app.db import make_engine, make_sessionmaker
from app.errors import install_error_handlers
from app.jobs import catalog as _catalog  # noqa: F401 — регистрирует обработчики фоновых задач
from app.jobs.registry import registry
from app.jobs.runner import JobRunner


def _configure_logging() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    # httpx на уровне INFO пишет полный адрес запроса, а в нём токен бота и секрет вебхука Битрикс24.
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)


def create_app(settings: Settings | None = None, services: Services | None = None) -> FastAPI:
    settings = settings or get_settings()
    services = services or build_services(settings)
    _configure_logging()

    engine = make_engine(settings.async_database_url)
    sessionmaker = make_sessionmaker(engine)
    jobs = JobRunner(registry.copy(), sessionmaker, services, settings)

    @contextlib.asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        worker = None
        if settings.jobs_worker_enabled:
            worker = asyncio.create_task(app.state.jobs.run_forever(settings.jobs_poll_seconds))
        try:
            yield
        finally:
            if worker is not None:
                worker.cancel()
                with contextlib.suppress(asyncio.CancelledError):
                    await worker
            await app.state.services.aclose()
            await engine.dispose()

    app = FastAPI(
        title="Модус Трейд: обращения и предложения сотрудников",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/api/v1/docs",
        openapi_url="/api/v1/openapi.json",
    )
    app.state.settings = settings
    app.state.services = services
    app.state.engine = engine
    app.state.sessionmaker = sessionmaker
    app.state.jobs = jobs

    install_error_handlers(app)
    # X-Forwarded-For / -Proto учитываются только от доверенного прокси (Caddy), иначе адрес клиента
    # для лимита попыток входа можно подделать заголовком.
    app.add_middleware(ProxyHeadersMiddleware, trusted_hosts=settings.trusted_proxies)
    app.include_router(api_router)
    return app
