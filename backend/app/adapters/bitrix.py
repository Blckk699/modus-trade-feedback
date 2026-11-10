"""Адаптер Битрикс24: создание задачи через входящий вебхук (`tasks.task.add`).

Адрес вебхука содержит секрет, поэтому он и тексты исключений httpx не логируются.
"""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Protocol
from urllib.parse import urlsplit

import httpx
from pydantic import BaseModel

from app.errors import ExternalServiceError

log = logging.getLogger(__name__)


class BitrixTask(BaseModel):
    id: str
    url: str


class Bitrix24Gateway(Protocol):
    async def create_task(self, *, title: str, description: str, deadline: datetime | None) -> BitrixTask: ...


class Bitrix24Webhook:
    def __init__(
        self,
        webhook_url: str,
        *,
        responsible_id: int = 1,
        transport: httpx.AsyncBaseTransport | None = None,
        timeout: float = 20.0,
    ) -> None:
        self._webhook_url = webhook_url.rstrip("/")
        self._responsible_id = responsible_id
        self._http = httpx.AsyncClient(transport=transport, timeout=timeout)

    async def create_task(self, *, title: str, description: str, deadline: datetime | None) -> BitrixTask:
        if not self._webhook_url:
            raise ExternalServiceError(
                "Битрикс24 не настроен: не задан BITRIX24_WEBHOOK_URL", code="bitrix_unavailable"
            )
        fields: dict[str, object] = {
            "TITLE": title,
            "DESCRIPTION": description,
            "RESPONSIBLE_ID": self._responsible_id,
        }
        if deadline is not None:
            fields["DEADLINE"] = deadline.isoformat()
        try:
            response = await self._http.post(f"{self._webhook_url}/tasks.task.add.json", json={"fields": fields})
            body = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            log.warning("Bitrix24 tasks.task.add failed: %s", type(exc).__name__)
            raise ExternalServiceError("Битрикс24 недоступен", code="bitrix_unavailable") from None
        if "error" in body or response.status_code >= 400:
            log.warning("Bitrix24 rejected: %s", body.get("error"))
            raise ExternalServiceError(
                "Битрикс24 отклонил создание задачи",
                code="bitrix_error",
                details={"error": body.get("error"), "description": body.get("error_description")},
            )
        try:
            task_id = str(body["result"]["task"]["id"])
        except (KeyError, TypeError):
            raise ExternalServiceError("Битрикс24 вернул неожиданный ответ", code="bitrix_error") from None
        return BitrixTask(id=task_id, url=self.task_url(task_id))

    def task_url(self, task_id: str) -> str:
        parts = urlsplit(self._webhook_url)
        return f"{parts.scheme}://{parts.netloc}/company/personal/user/{self._responsible_id}/tasks/task/view/{task_id}/"

    async def aclose(self) -> None:
        await self._http.aclose()
