"""Адаптеры внешних сервисов. Интерфейсы (Protocol) и реальные реализации; фейки — в `fakes`."""

from app.adapters.bitrix import Bitrix24Gateway, Bitrix24Webhook, BitrixTask
from app.adapters.claude import AnthropicClaude, AppealDraft, ClaudeClient, DuplicateCandidate, DuplicateMatch, MeetingDraft
from app.adapters.speech import ElevenLabsScribe, SpeechToText, Transcript
from app.adapters.telegram import TelegramBotApi, TelegramGateway

__all__ = [
    "AnthropicClaude",
    "AppealDraft",
    "Bitrix24Gateway",
    "Bitrix24Webhook",
    "BitrixTask",
    "ClaudeClient",
    "DuplicateCandidate",
    "DuplicateMatch",
    "ElevenLabsScribe",
    "MeetingDraft",
    "SpeechToText",
    "TelegramBotApi",
    "TelegramGateway",
    "Transcript",
]
