"""Клиент API бэкенда. Бот действует от имени пользователя: X-Service-Key + X-Telegram-Id."""

from dataclasses import dataclass
from typing import Any

import logging

import httpx

log = logging.getLogger(__name__)

# Подписи из примера GET /dictionaries в контракте — запасной вариант, если справочник недоступен.
FALLBACK_DICTIONARIES: dict[str, Any] = {
    "appeal_types": [
        {"code": "problem", "label": "Проблема"},
        {"code": "suggestion", "label": "Предложение"},
        {"code": "praise", "label": "Положительный отзыв"},
    ],
    "priorities": [
        {"code": "high", "label": "Высокий"},
        {"code": "medium", "label": "Средний"},
        {"code": "low", "label": "Низкий"},
    ],
    "statuses": [
        {"code": "new", "label": "Новое"},
        {"code": "in_review", "label": "На рассмотрении"},
        {"code": "awaiting_info", "label": "Ожидает уточнения"},
        {"code": "in_progress", "label": "В работе"},
        {"code": "implemented", "label": "Реализовано"},
        {"code": "rejected", "label": "Отклонено"},
        {"code": "closed", "label": "Закрыто"},
    ],
}

UNAVAILABLE_MESSAGE = "Сервис временно недоступен. Попробуйте ещё раз через минуту."


class ApiError(Exception):
    """Ошибка API в формате контракта: ветвиться по `code`, показывать `message`."""

    def __init__(self, status: int, code: str, message: str, details: Any = None):
        super().__init__(f"{status} {code}: {message}")
        self.status = status
        self.code = code
        self.message = message
        self.details = details


@dataclass(frozen=True)
class LoginCode:
    code: str
    expires_at: str
    ttl_seconds: int


class Api:
    """Тонкий клиент над httpx. Транспорт подменяется в тестах."""

    def __init__(
        self,
        base_url: str,
        service_key: str,
        timeout: float = 15.0,
        transport: httpx.AsyncBaseTransport | None = None,
    ):
        self._http = httpx.AsyncClient(
            base_url=base_url.rstrip("/"),
            headers={"X-Service-Key": service_key, "Accept": "application/json"},
            timeout=timeout,
            transport=transport,
        )
        self._dictionaries: dict[str, Any] | None = None

    async def close(self) -> None:
        await self._http.aclose()

    async def request(
        self,
        method: str,
        path: str,
        *,
        telegram_id: int | None = None,
        json: Any = None,
        params: dict[str, Any] | None = None,
        files: dict[str, Any] | None = None,
        data: dict[str, Any] | None = None,
    ) -> Any:
        headers = {"X-Telegram-Id": str(telegram_id)} if telegram_id is not None else {}
        try:
            response = await self._http.request(
                method, path, headers=headers, json=json, params=params, files=files, data=data
            )
        except httpx.HTTPError as exc:
            raise ApiError(0, "unavailable", UNAVAILABLE_MESSAGE) from exc
        if response.is_success:
            return response.json() if response.content else None
        raise _error_from(response)

    # ---- пользовательские маршруты от имени пользователя

    async def me(self, telegram_id: int) -> dict[str, Any]:
        return await self.request("GET", "/api/v1/me", telegram_id=telegram_id)

    async def issue_login_code(self, telegram_id: int) -> LoginCode:
        data = await self.request("POST", "/api/v1/auth/login-codes", telegram_id=telegram_id)
        return LoginCode(code=data["code"], expires_at=data["expires_at"], ttl_seconds=data["ttl_seconds"])

    async def digest(self, telegram_id: int) -> dict[str, Any]:
        return await self.request("GET", "/api/v1/analytics/digest", telegram_id=telegram_id)

    async def draft_from_text(self, telegram_id: int, text: str, forwarded_from: str | None) -> dict[str, Any]:
        body = {"text": text, "forwarded_from": forwarded_from}
        return await self.request("POST", "/api/v1/drafts/text", telegram_id=telegram_id, json=body)

    async def draft_from_voice(
        self,
        telegram_id: int,
        filename: str,
        content: bytes,
        content_type: str,
        duration_seconds: int | None = None,
    ) -> dict[str, Any]:
        files = {"file": (filename, content, content_type)}
        # Длительность из Telegram: по ней бэкенд отсекает аудио длиннее 5 минут (audio_too_long).
        data = {"duration_seconds": str(duration_seconds)} if duration_seconds is not None else None
        return await self.request("POST", "/api/v1/drafts/voice", telegram_id=telegram_id, files=files, data=data)

    async def create_appeal(self, telegram_id: int, body: dict[str, Any]) -> dict[str, Any]:
        return await self.request("POST", "/api/v1/appeals", telegram_id=telegram_id, json=body)

    async def categories(self, telegram_id: int) -> list[dict[str, Any]]:
        return await self.request("GET", "/api/v1/categories", telegram_id=telegram_id)

    async def my_appeals(self, telegram_id: int, page_size: int = 10) -> dict[str, Any]:
        params = {"scope": "mine", "sort": "created_desc", "page_size": page_size}
        return await self.request("GET", "/api/v1/appeals", telegram_id=telegram_id, params=params)

    async def post_message(self, telegram_id: int, appeal_id: int, text: str) -> dict[str, Any]:
        path = f"/api/v1/appeals/{appeal_id}/messages"
        return await self.request("POST", path, telegram_id=telegram_id, json={"text": text})

    async def set_name_consent(self, telegram_id: int, discussion_id: int, show_name: bool) -> dict[str, Any]:
        path = f"/api/v1/discussions/{discussion_id}/name-consent"
        return await self.request("POST", path, telegram_id=telegram_id, json={"show_name": show_name})

    # ---- очередь уведомлений: только сервисный ключ

    async def pending_notifications(self, limit: int = 50) -> list[dict[str, Any]]:
        return await self.request("GET", "/api/v1/bot/notifications/pending", params={"limit": limit})

    async def ack_notification(self, notification_id: int, telegram_message_id: int | None) -> None:
        path = f"/api/v1/bot/notifications/{notification_id}/ack"
        await self.request("POST", path, json={"telegram_message_id": telegram_message_id})

    async def fail_notification(self, notification_id: int, error: str, permanent: bool) -> None:
        path = f"/api/v1/bot/notifications/{notification_id}/fail"
        await self.request("POST", path, json={"error": error[:500], "permanent": permanent})

    async def dictionaries(self) -> dict[str, Any]:
        """Подписи перечислений. Справочник не меняется, поэтому читается один раз.

        Если справочник недоступен, бот не падает: берёт подписи из контракта и попробует снова в следующий раз.
        """
        if self._dictionaries is None:
            try:
                self._dictionaries = await self.request("GET", "/api/v1/dictionaries")
            except ApiError as exc:
                log.warning("GET /dictionaries failed, using built-in labels: %s", exc)
                return FALLBACK_DICTIONARIES
        return self._dictionaries


def _error_from(response: httpx.Response) -> ApiError:
    try:
        error = response.json()["error"]
        return ApiError(response.status_code, error["code"], error["message"], error.get("details"))
    except (ValueError, KeyError, TypeError):
        return ApiError(response.status_code, "internal_error", UNAVAILABLE_MESSAGE)
