"""Фейк Telegram на границе адаптера: сессия aiogram без сети. Для тестов и прогона на моке."""

import itertools
from datetime import datetime
from typing import Any

from aiogram import Bot
from aiogram.client.session.base import BaseSession
from aiogram.methods import GetFile, SendMessage, TelegramMethod

from app.widgets import SendWidget
from aiogram.types import Chat, File, InlineKeyboardMarkup, Message


class FakeTelegram(BaseSession):
    """Сессия aiogram без сети: запоминает вызовы Bot API и отвечает правдоподобно."""

    def __init__(self) -> None:
        super().__init__()
        self.calls: list[TelegramMethod] = []
        self._ids = itertools.count(1000)
        self._message_ids: dict[int, int] = {}  # id(SendMessage) → message_id
        # chat_id → фабрика исключения: так тест изображает заблокированного пользователя или сбой сети
        self.errors: dict[int, Any] = {}
        self.files: dict[str, bytes] = {}
        # Фабрика исключения для sendWidget: так тест изображает Bot API без виджетов
        self.reject_widgets: Any = None  # file_id → содержимое для getFile и скачивания

    async def make_request(self, bot: Bot, method: TelegramMethod, timeout: int | None = None) -> Any:
        self.calls.append(method)
        if isinstance(method, GetFile):
            return File(file_id=method.file_id, file_unique_id=method.file_id, file_path=f"files/{method.file_id}")
        if isinstance(method, (SendMessage, SendWidget)) and method.chat_id in self.errors:
            error = self.errors[method.chat_id](method)
            if error is not None:
                raise error
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
        if isinstance(method, SendWidget):
            if self.reject_widgets:
                raise self.reject_widgets(method)
            message_id = next(self._ids)
            self._message_ids[id(method)] = message_id
            return Message(
                message_id=message_id,
                date=datetime.now(),
                chat=Chat(id=method.chat_id, type="private"),
                caption=method.caption,
                reply_markup=method.reply_markup if isinstance(method.reply_markup, InlineKeyboardMarkup) else None,
            )
        return True

    async def close(self) -> None:
        pass

    async def stream_content(self, url: str, *args, **kwargs):
        yield self.files[url.rsplit("/", 1)[-1]]

    def sent(self) -> list[SendMessage]:
        return [c for c in self.calls if isinstance(c, SendMessage)]

    def widgets(self) -> list[SendWidget]:
        return [c for c in self.calls if isinstance(c, SendWidget)]

    def messages(self) -> list[SendMessage | SendWidget]:
        """Всё, что увидел пользователь: и сообщения, и виджеты, по порядку."""
        return [c for c in self.calls if isinstance(c, (SendMessage, SendWidget))]

    def message_id_of(self, method: SendMessage) -> int:
        return self._message_ids[id(method)]

    def of_type(self, method_type: type) -> list[TelegramMethod]:
        return [c for c in self.calls if isinstance(c, method_type)]
