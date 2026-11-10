"""Фейк Telegram на границе адаптера: сессия aiogram без сети. Для тестов и прогона на моке."""

import itertools
from datetime import datetime
from typing import Any

from aiogram import Bot
from aiogram.client.session.base import BaseSession
from aiogram.methods import SendMessage, TelegramMethod
from aiogram.types import Chat, InlineKeyboardMarkup, Message


class FakeTelegram(BaseSession):
    """Сессия aiogram без сети: запоминает вызовы Bot API и отвечает правдоподобно."""

    def __init__(self) -> None:
        super().__init__()
        self.calls: list[TelegramMethod] = []
        self._ids = itertools.count(1000)
        self._message_ids: dict[int, int] = {}  # id(SendMessage) → message_id
        # chat_id → фабрика исключения: так тест изображает заблокированного пользователя или сбой сети
        self.errors: dict[int, Any] = {}

    async def make_request(self, bot: Bot, method: TelegramMethod, timeout: int | None = None) -> Any:
        self.calls.append(method)
        if isinstance(method, SendMessage) and method.chat_id in self.errors:
            raise self.errors[method.chat_id](method)
        if isinstance(method, SendMessage):
            message_id = next(self._ids)
            self._message_ids[id(method)] = message_id
            return Message(
                message_id=message_id,
                date=datetime.now(),
                chat=Chat(id=method.chat_id, type="private"),
                text=method.text,
                reply_markup=method.reply_markup if isinstance(method.reply_markup, InlineKeyboardMarkup) else None,
            )
        return True

    async def close(self) -> None:
        pass

    async def stream_content(self, *args, **kwargs):  # pragma: no cover
        yield b""

    def sent(self) -> list[SendMessage]:
        return [c for c in self.calls if isinstance(c, SendMessage)]

    def message_id_of(self, method: SendMessage) -> int:
        return self._message_ids[id(method)]

    def of_type(self, method_type: type) -> list[TelegramMethod]:
        return [c for c in self.calls if isinstance(c, method_type)]
