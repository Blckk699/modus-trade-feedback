"""Опознание сотрудника: перед каждым обновлением бот спрашивает GET /me от имени пользователя."""

import html
import logging
from collections.abc import Awaitable, Callable
from typing import Any

from aiogram import BaseMiddleware
from aiogram.types import CallbackQuery, Message, ReplyKeyboardRemove, TelegramObject

from app import texts
from app.api import Api, ApiError

log = logging.getLogger(__name__)

ACCESS_DENIED_CODES = {"user_not_registered", "user_disabled"}


class IdentifyUser(BaseMiddleware):
    """Кладёт `me` в данные обработчика. Постороннему отвечает отказом из API и дальше не пускает."""

    def __init__(self, api: Api):
        self.api = api

    async def __call__(
        self,
        handler: Callable[[TelegramObject, dict[str, Any]], Awaitable[Any]],
        event: TelegramObject,
        data: dict[str, Any],
    ) -> Any:
        user = data.get("event_from_user")
        if user is None or user.is_bot:
            return None
        try:
            data["me"] = await self.api.me(user.id)
        except ApiError as exc:
            if exc.code in ACCESS_DENIED_CODES:
                await _reply(event, exc.message, remove_keyboard=True)
            else:
                log.warning("GET /me failed for update: %s", exc)
                await _reply(event, texts.API_UNAVAILABLE)
            return None
        return await handler(event, data)


async def _reply(event: TelegramObject, text: str, remove_keyboard: bool = False) -> None:
    markup = ReplyKeyboardRemove() if remove_keyboard else None
    if isinstance(event, Message):
        await event.answer(html.escape(text), reply_markup=markup)
    elif isinstance(event, CallbackQuery):  # alert — простой текст, без HTML
        await event.answer(text[:200], show_alert=True)
