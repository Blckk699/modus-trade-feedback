"""Прогон бота против мок-сервера Prism (или бэкенда) без настоящего Telegram.

    npx -y @stoplight/prism-cli@5.15.11 mock -h 127.0.0.1 -p 4011 ../contract/openapi.yaml
    uv run python -m scripts.smoke_mock [http://127.0.0.1:4011]

Подаёт боту команды меню и подачу обращения, запросы идут по контракту, ответы бота печатаются.
"""

import asyncio
import sys

from app import texts
from tests.support import BotHarness


def show(h: BotHarness, before: int, title: str) -> int:
    print(f"> {title}")
    for call in h.telegram.calls[before:]:
        text = getattr(call, "text", None)
        if text:
            print("  " + text.replace("\n", "\n  "))
    return len(h.telegram.calls)


async def main(base_url: str) -> int:
    h = BotHarness(real_api_url=base_url)
    try:
        n = 0
        for text in ["/start", texts.BTN_LOGIN_CODE, texts.BTN_DIGEST, texts.BTN_MY_APPEALS, texts.BTN_SUBMIT]:
            await h.send_text(text)
            n = show(h, n, text)
        await h.send_forward("Опять в заявке на камеры не написали, для какого объекта", chat_title="Закупки — продажи")
        n = show(h, n, "пересланное сообщение")
        card = h.telegram.sent()[-1]
        await h.press(card, texts.BTN_DRAFT_PRIORITY)
        await h.press(h.telegram.calls[-2], "Высокий")
        n = show(h, n, "Приоритет → Высокий")
        await h.press(card, texts.BTN_DRAFT_SEND)
        show(h, n, texts.BTN_DRAFT_SEND)
        return 0
    finally:
        await h.close()


if __name__ == "__main__":
    sys.exit(asyncio.run(main(sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:4011")))
