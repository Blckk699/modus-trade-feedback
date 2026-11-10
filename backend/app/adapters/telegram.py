"""Адаптер Telegram Bot API: служебная отправка сообщения от имени бота.

Пользовательские уведомления по спеке идут через бот (очередь уведомлений B-08, бот сам их забирает).
Этот адаптер нужен бэкенду для прямых служебных вызовов Bot API. Проверка подписи данных
Mini App и Telegram Login (B-03) — чистый HMAC по токену бота и в адаптер не входит.

Токен бота входит в адрес запроса, поэтому ни адрес, ни текст исключения httpx не логируются.
"""

from __future__ import annotations

import logging
from typing import Protocol

import httpx

from app.errors import ExternalServiceError

log = logging.getLogger(__name__)


class TelegramGateway(Protocol):
    async def send_message(self, chat_id: int, text: str) -> int:
        """Отправляет текст, возвращает message_id."""
        ...


class TelegramBotApi:
    def __init__(
        self,
        token: str,
        *,
        base_url: str = "https://api.telegram.org",
        transport: httpx.AsyncBaseTransport | None = None,
        timeout: float = 15.0,
    ) -> None:
        self._token = token
        self._base_url = base_url.rstrip("/")
        self._http = httpx.AsyncClient(transport=transport, timeout=timeout)

    async def _call(self, method: str, payload: dict) -> dict:
        if not self._token:
            raise ExternalServiceError("Telegram не настроен: не задан TELEGRAM_BOT_TOKEN", code="telegram_unavailable")
        try:
            response = await self._http.post(f"{self._base_url}/bot{self._token}/{method}", json=payload)
            body = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            log.warning("Telegram %s failed: %s", method, type(exc).__name__)
            raise ExternalServiceError("Telegram недоступен", code="telegram_unavailable") from None
        if not body.get("ok"):
            log.warning("Telegram %s rejected: %s", method, body.get("description"))
            raise ExternalServiceError(
                "Telegram отклонил запрос", code="telegram_error", details={"description": body.get("description")}
            )
        return body["result"]

    async def send_message(self, chat_id: int, text: str) -> int:
        result = await self._call("sendMessage", {"chat_id": chat_id, "text": text})
        return int(result["message_id"])

    async def aclose(self) -> None:
        await self._http.aclose()
