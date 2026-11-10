"""Прогон бота против мок-сервера Prism без настоящего Telegram.

    npx -y @stoplight/prism-cli@5.15.11 mock -h 127.0.0.1 -p 4011 ../contract/openapi.yaml
    uv run python -m scripts.smoke_mock [http://127.0.0.1:4011]

Подаёт боту команды меню, запросы идут в мок по контракту, ответы бота печатаются.
"""

import asyncio
import itertools
import sys
from datetime import datetime

from aiogram.types import Chat, Message, MessageEntity, Update, User

from app import texts
from app.api import Api
from app.config import Settings
from app.fake_telegram import FakeTelegram
from app.main import build_bot, build_dispatcher

USER_ID = 100000004


async def main(base_url: str) -> int:
    settings = Settings(
        _env_file=None,
        telegram_bot_token="123456:SMOKE",
        bot_service_key="smoke-key",
        api_base_url=base_url,
        mini_app_url="https://modus.example/app",
    )
    api = Api(base_url, "smoke-key")
    telegram = FakeTelegram()
    bot = build_bot("123456:SMOKE", session=telegram)
    dp = build_dispatcher(api, settings)
    ids = itertools.count(1)
    try:
        for text in ["/start", texts.BTN_LOGIN_CODE, texts.BTN_DIGEST, texts.BTN_MY_APPEALS, texts.BTN_SUBMIT]:
            before = len(telegram.sent())
            entities = [MessageEntity(type="bot_command", offset=0, length=len(text))] if text.startswith("/") else None
            message = Message(
                message_id=next(ids),
                date=datetime.now(),
                chat=Chat(id=USER_ID, type="private"),
                from_user=User(id=USER_ID, is_bot=False, first_name="Айгерим"),
                text=text,
                entities=entities,
            )
            await dp.feed_update(bot, Update(update_id=next(ids), message=message))
            print(f"> {text}")
            for sent in telegram.sent()[before:]:
                print("  " + sent.text.replace("\n", "\n  "))
        return 0
    finally:
        await api.close()


if __name__ == "__main__":
    sys.exit(asyncio.run(main(sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:4011")))
