"""Обвязка тестов: бот целиком с фейком Telegram и фейком API бэкенда (транспорт httpx)."""

import itertools
import json
from datetime import datetime
from typing import Any

import httpx
from aiogram.types import CallbackQuery, Chat, Message, MessageEntity, MessageOriginChat, Update, User, Voice

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
        "full_name": "Карина Шаймерденова",
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

    def __init__(
        self, mini_app_url: str | None = MINI_APP_URL, real_api_url: str | None = None, service_key: str = SERVICE_KEY
    ) -> None:
        self.telegram = FakeTelegram()
        self.backend = FakeApi()
        self.settings = Settings(
            _env_file=None,
            telegram_bot_token=BOT_TOKEN,
            bot_service_key=service_key,
            api_base_url="http://api.test",
            mini_app_url=mini_app_url,
        )
        if real_api_url:  # прогон против мок-сервера Prism или бэкенда
            self.api = Api(real_api_url, service_key)
        else:
            self.api = Api("http://api.test", SERVICE_KEY, transport=httpx.MockTransport(self.backend.handler))
        self.bot = build_bot(BOT_TOKEN, session=self.telegram)
        self.dp = build_dispatcher(self.api, self.settings)
        self._update_ids = itertools.count(1)

    async def send_text(
        self,
        text: str,
        user_id: int = 100000004,
        first_name: str = "Карина",
        last_name: str | None = None,
        username: str | None = None,
    ) -> None:
        message = Message(
            message_id=next(self._update_ids),
            date=datetime.now(),
            chat=Chat(id=user_id, type="private"),
            from_user=User(id=user_id, is_bot=False, first_name=first_name, last_name=last_name, username=username),
            text=text,
            entities=_command_entity(text),
        )
        await self.dp.feed_update(self.bot, Update(update_id=next(self._update_ids), message=message))

    async def send_forward(self, text: str, chat_title: str, user_id: int = 100000004) -> None:
        origin = MessageOriginChat(
            type="chat", date=datetime.now(), sender_chat=Chat(id=-100500, type="supergroup", title=chat_title)
        )
        await self._feed_message(user_id, text=text, forward_origin=origin)

    async def send_voice(self, content: bytes, duration: int, user_id: int = 100000004) -> None:
        file_id = f"voice{next(self._update_ids)}"
        self.telegram.files[file_id] = content
        voice = Voice(
            file_id=file_id, file_unique_id=file_id, duration=duration, mime_type="audio/ogg", file_size=len(content)
        )
        await self._feed_message(user_id, voice=voice)

    async def send_reply(self, text: str, to: Any, user_id: int = 100000004) -> None:
        """Ответ свайпом на сообщение бота (SendMessage из журнала фейка)."""
        replied = Message(
            message_id=self.telegram.message_id_of(to),
            date=datetime.now(),
            chat=Chat(id=user_id, type="private"),
            text=to.text,
            reply_markup=to.reply_markup,
        )
        await self._feed_message(user_id, text=text, reply_to_message=replied)

    async def _feed_message(self, user_id: int, **fields: Any) -> None:
        message = Message(
            message_id=next(self._update_ids),
            date=datetime.now(),
            chat=Chat(id=user_id, type="private"),
            from_user=User(id=user_id, is_bot=False, first_name="Карина"),
            **fields,
        )
        await self.dp.feed_update(self.bot, Update(update_id=next(self._update_ids), message=message))

    async def press(self, sent: Any, button_text: str, user_id: int = 100000004) -> None:
        """Нажать inline-кнопку на сообщении, которое бот отправил (SendMessage или EditMessageText)."""
        markup = sent.reply_markup
        [button] = [b for row in markup.inline_keyboard for b in row if b.text.lstrip("• ") == button_text]
        message_id = getattr(sent, "message_id", None) or self.telegram.message_id_of(sent)
        callback = CallbackQuery(
            id=str(next(self._update_ids)),
            from_user=User(id=user_id, is_bot=False, first_name="Карина"),
            chat_instance="ci",
            message=Message(
                message_id=message_id,
                date=datetime.now(),
                chat=Chat(id=user_id, type="private"),
                # У виджета нет text, только подпись: так бот отличает его от текстовой карточки.
                **({"caption": "card"} if message_id in self.telegram.widget_ids else {"text": "card"}),
            ),
            data=button.callback_data,
        )
        await self.dp.feed_update(self.bot, Update(update_id=next(self._update_ids), callback_query=callback))

    async def close(self) -> None:
        await self.api.close()


def _command_entity(text: str) -> list[MessageEntity] | None:
    if not text.startswith("/"):
        return None
    return [MessageEntity(type="bot_command", offset=0, length=len(text.split()[0]))]
