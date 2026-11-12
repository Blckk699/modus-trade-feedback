"""Контейнер зависимостей: часы и адаптеры внешних сервисов.

Живёт в `app.state.services`. HTTP-обработчики получают его через зависимости из `app.api.deps`,
фоновые задачи — через `JobContext.services`. Тест подменяет любой элемент одной строкой:

    app.state.services.claude = FakeClaude()
"""

from __future__ import annotations

from dataclasses import dataclass, fields

from app.adapters.bitrix import Bitrix24Gateway, Bitrix24Webhook
from app.adapters.bitrix_oauth import Bitrix24OAuth, Bitrix24OAuthClient
from app.adapters.claude import AnthropicClaude, ClaudeClient
from app.adapters.speech import ElevenLabsScribe, SpeechToText
from app.adapters.telegram import TelegramBotApi, TelegramGateway
from app.clock import Clock, SystemClock
from app.config import Settings


@dataclass
class Services:
    clock: Clock
    claude: ClaudeClient
    speech: SpeechToText
    telegram: TelegramGateway
    bitrix: Bitrix24Gateway
    bitrix_oauth: Bitrix24OAuth

    async def aclose(self) -> None:
        for f in fields(self):
            close = getattr(getattr(self, f.name), "aclose", None)
            if close is not None:
                await close()


def build_services(settings: Settings) -> Services:
    return Services(
        clock=SystemClock(),
        claude=AnthropicClaude(settings.anthropic_api_key, settings.claude_model),
        speech=ElevenLabsScribe(
            settings.elevenlabs_api_key,
            model_id=settings.elevenlabs_stt_model,
            language_code=settings.elevenlabs_language or None,
        ),
        telegram=TelegramBotApi(settings.telegram_bot_token),
        bitrix=Bitrix24Webhook(settings.bitrix24_webhook_url, responsible_id=settings.bitrix24_responsible_id),
        bitrix_oauth=Bitrix24OAuthClient(
            client_id=settings.bitrix24_client_id.strip(),
            client_secret=settings.bitrix24_client_secret.strip(),
            portal=settings.bitrix24_portal_host,
            token_url=settings.bitrix24_token_url,
        ),
    )
