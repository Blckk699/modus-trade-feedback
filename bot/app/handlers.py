"""Меню бота: запуск, код входа, сводка, переход в Mini App."""

import html
import logging
from typing import Any

from aiogram import Bot, F, Router
from aiogram.filters import Command, CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.types import MenuButtonWebApp, Message, WebAppInfo

from app import keyboards, texts
from app.api import Api, ApiError
from app.config import Settings

log = logging.getLogger(__name__)
async def start(message: Message, bot: Bot, state: FSMContext, me: dict[str, Any], settings: Settings) -> None:
    await state.set_state(None)
    if settings.mini_app_url:
        # Кнопка меню чата открывает Mini App с initData — вход без экрана входа.
        await bot.set_chat_menu_button(
            chat_id=message.chat.id,
            menu_button=MenuButtonWebApp(text=texts.BTN_OPEN_APP, web_app=WebAppInfo(url=settings.mini_app_url)),
        )
    first_name = html.escape(message.from_user.first_name if message.from_user else me["full_name"])
    await message.answer(
        texts.greeting(first_name, has_mini_app=bool(settings.mini_app_url)),
        reply_markup=keyboards.main_menu(me, settings.mini_app_url),
    )


async def login_code(message: Message, api: Api) -> None:
    try:
        code = await api.issue_login_code(message.from_user.id)
    except ApiError as exc:
        await message.answer(html.escape(exc.message))
        return
    await message.answer(texts.login_code(html.escape(code.code), code.ttl_seconds))


async def submit_hint(message: Message, state: FSMContext) -> None:
    await state.set_state(None)
    await message.answer(texts.SUBMIT_HINT)


async def my_appeals(message: Message, me: dict[str, Any], settings: Settings) -> None:
    if not settings.mini_app_url:
        await message.answer(texts.MINI_APP_NOT_CONFIGURED, reply_markup=keyboards.main_menu(me, settings.mini_app_url))
        return
    await message.answer(
        texts.MY_APPEALS,
        reply_markup=keyboards.open_mini_app(texts.MY_APPEALS_BUTTON, settings.mini_app_url),
    )


async def digest(message: Message, api: Api) -> None:
    try:
        data = await api.digest(message.from_user.id)
    except ApiError as exc:
        await message.answer(html.escape(exc.message))
        return
    # Текст сводки бэкенд отдаёт готовым Telegram HTML.
    await message.answer(data["text"])


async def fallback(message: Message, me: dict[str, Any], settings: Settings) -> None:
    await message.answer(texts.USE_MENU, reply_markup=keyboards.main_menu(me, settings.mini_app_url))


def build_router() -> Router:
    """Свой роутер на каждый диспетчер: aiogram не даёт подключить один роутер дважды."""
    router = Router(name="menu")
    router.message.register(start, CommandStart())
    router.message.register(login_code, Command("code"))
    router.message.register(login_code, F.text == texts.BTN_LOGIN_CODE)
    router.message.register(submit_hint, Command("new"))
    router.message.register(submit_hint, F.text == texts.BTN_SUBMIT)
    router.message.register(my_appeals, Command("appeals"))
    router.message.register(my_appeals, F.text == texts.BTN_MY_APPEALS)
    router.message.register(digest, Command("digest"))
    router.message.register(digest, F.text == texts.BTN_DIGEST)
    return router


def build_fallback_router() -> Router:
    """Подключается последним: всё, что не разобрали меню и черновики."""
    router = Router(name="fallback")
    router.message.register(fallback)
    return router
