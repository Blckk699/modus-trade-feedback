"""Сборка и запуск бота. `uv run python -m app`."""

import asyncio
import logging
import sys

from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.types import BotCommand, MenuButtonWebApp, WebAppInfo

from app import drafts, handlers, notifications, texts
from app.api import Api
from app.config import Settings
from app.middleware import IdentifyUser

COMMANDS = [
    BotCommand(command="start", description="Меню"),
    BotCommand(command="new", description=texts.BTN_SUBMIT),
    BotCommand(command="appeals", description=texts.BTN_MY_APPEALS),
    BotCommand(command="digest", description=texts.BTN_DIGEST),
    BotCommand(command="code", description=texts.BTN_LOGIN_CODE),
]


def build_dispatcher(api: Api, settings: Settings) -> Dispatcher:
    dp = Dispatcher(api=api, settings=settings)
    identify = IdentifyUser(api)
    dp.message.outer_middleware(identify)
    dp.callback_query.outer_middleware(identify)
    dp.include_router(handlers.build_router())
    dp.include_router(notifications.build_router())  # ответ на вопрос — раньше нового черновика
    dp.include_router(drafts.build_router())
    dp.include_router(handlers.build_fallback_router())
    return dp


def build_bot(token: str, **kwargs) -> Bot:
    return Bot(token=token, default=DefaultBotProperties(parse_mode=ParseMode.HTML), **kwargs)


async def setup_menu_button(bot: Bot, settings: Settings) -> None:
    """Кнопка меню «Открыть» для всех чатов сразу, а не только после /start (тот ставит её в своём чате)."""
    if settings.mini_app_url:
        button = MenuButtonWebApp(text=texts.BTN_OPEN_APP, web_app=WebAppInfo(url=settings.mini_app_url))
        await bot.set_chat_menu_button(menu_button=button)


async def run(settings: Settings) -> None:
    api = Api(settings.api_base_url, settings.bot_service_key.get_secret_value(), settings.api_timeout_seconds)
    bot = build_bot(settings.telegram_bot_token.get_secret_value())
    dp = build_dispatcher(api, settings)
    poller = asyncio.create_task(notifications.poll_forever(bot, api, settings))
    try:
        await bot.set_my_commands(COMMANDS)
        await setup_menu_button(bot, settings)
        await dp.start_polling(bot)
    finally:
        poller.cancel()
        await api.close()
        await bot.session.close()


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    settings = Settings()
    missing = settings.missing()
    if missing:
        print(texts.NOT_CONFIGURED.format(names=", ".join(missing)), file=sys.stderr)
        return 2
    asyncio.run(run(settings))
    return 0
