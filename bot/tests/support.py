"""Обвязка тестов: бот целиком с фейком Telegram и фейком API бэкенда (транспорт httpx)."""

import itertools
import json
from datetime import datetime
from typing import Any

import httpx
from aiogram.types import Chat, Message, MessageEntity, Update, User

from app.api import Api
from app.config import Settings
from app.fake_telegram import FakeTelegram
from app.main import build_bot, build_dispatcher

BOT_TOKEN = "123456:TEST-TOKEN"
SERVICE_KEY = "test-service-key"
MINI_APP_URL = "https://modus.example/app"


class FakeApi:
    """API бэкенда на httpx.MockTransport: ответы по (метод, путь), журнал запросов."""

    def __init__(self) -> None:
        self.routes: dict[tuple[str, str], tuple[int, Any]] = {}
        self.requests: list[httpx.Request] = []

    def on(self, method: str, path: str, status: int, body: Any) -> None:
        self.routes[(method, path)] = (status, body)

    def error(self, method: str, path: str, status: int, code: str, message: str) -> None:
        self.on(method, path, status, {"error": {"code": code, "message": message, "details": None}})

    def handler(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        status, body = self.routes.get((request.method, request.url.path), (404, _not_found()))
        return httpx.Response(status, content=json.dumps(body).encode(), headers={"Content-Type": "application/json"})

    def calls(self, method: str, path: str) -> list[httpx.Request]:
        return [r for r in self.requests if r.method == method and r.url.path == path]


def _not_found() -> dict:
    return {"error": {"code": "not_found", "message": "Не найдено.", "details": None}}


def employee(telegram_id: int, analytics_scope: str = "none") -> dict:
    return {
        "id": 4,
        "telegram_id": telegram_id,
        "full_name": "Айгерим Нурланова",
        "position": "Сотрудник закупок",
        "role": "employee" if analytics_scope == "none" else "owner",
        "department": {"id": 1, "name": "Закупки"},
        "is_absent": False,
        "is_disabled": False,
        "responsible_for": [],
        "deputy_for": [],
        "assigned_open_count": 0,
        "permissions": {
            "can_create_appeal": True,
            "can_process_appeals": False,
            "can_view_department": False,
            "can_view_all_appeals": False,
            "analytics_scope": analytics_scope,
            "can_upload_meetings": False,
            "can_manage_settings": False,
            "can_view_unassigned": False,
        },
    }


class BotHarness:
    """Бот целиком: подаём обновление Telegram, смотрим, что ушло в API и что бот отправил."""

    def __init__(self, mini_app_url: str | None = MINI_APP_URL) -> None:
        self.telegram = FakeTelegram()
        self.backend = FakeApi()
        self.settings = Settings(
            _env_file=None,
            telegram_bot_token=BOT_TOKEN,
            bot_service_key=SERVICE_KEY,
            api_base_url="http://api.test",
            mini_app_url=mini_app_url,
        )
        self.api = Api("http://api.test", SERVICE_KEY, transport=httpx.MockTransport(self.backend.handler))
        self.bot = build_bot(BOT_TOKEN, session=self.telegram)
        self.dp = build_dispatcher(self.api, self.settings)
        self._update_ids = itertools.count(1)

    async def send_text(self, text: str, user_id: int = 100000004, first_name: str = "Айгерим") -> None:
        message = Message(
            message_id=next(self._update_ids),
            date=datetime.now(),
            chat=Chat(id=user_id, type="private"),
            from_user=User(id=user_id, is_bot=False, first_name=first_name),
            text=text,
            entities=_command_entity(text),
        )
        await self.dp.feed_update(self.bot, Update(update_id=next(self._update_ids), message=message))

    async def close(self) -> None:
        await self.api.close()


def _command_entity(text: str) -> list[MessageEntity] | None:
    if not text.startswith("/"):
        return None
    return [MessageEntity(type="bot_command", offset=0, length=len(text.split()[0]))]
