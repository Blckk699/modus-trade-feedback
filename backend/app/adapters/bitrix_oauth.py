"""Адаптер входа через Битрикс24 (OAuth локального приложения портала).

Два вызова: обмен авторизационного кода на токен и `user.current`. Токен портала живёт только внутри
одного вызова `current_user` и никуда не сохраняется. Секрет приложения, коды, токены и тексты
исключений httpx (в них полный адрес запроса) не логируются.
"""

from __future__ import annotations

import logging
from typing import Any, Protocol
from urllib.parse import urlsplit

import httpx
from pydantic import BaseModel

from app.errors import ExternalServiceError, InvalidBitrixAuth

log = logging.getLogger(__name__)


class BitrixProfile(BaseModel):
    """Сотрудник портала, как его вернул `user.current`."""

    id: int
    email: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    position: str | None = None

    @property
    def full_name(self) -> str:
        return " ".join(part for part in (self.first_name, self.last_name) if part)


class Bitrix24OAuth(Protocol):
    async def current_user(self, code: str) -> BitrixProfile:
        """Кто вошёл на портале с этим кодом. Портал отклонил код или ответ не от нашего портала —
        `InvalidBitrixAuth`; портал не ответил — `ExternalServiceError` с кодом `bitrix_unavailable`."""
        ...


def _unavailable() -> ExternalServiceError:
    return ExternalServiceError("Битрикс24 недоступен", code="bitrix_unavailable")


def _text(value: Any) -> str | None:
    text = str(value).strip() if value is not None else ""
    return text or None


class Bitrix24OAuthClient:
    def __init__(
        self,
        *,
        client_id: str,
        client_secret: str,
        portal: str,
        token_url: str,
        transport: httpx.AsyncBaseTransport | None = None,
        timeout: float = 15.0,
    ) -> None:
        self._client_id = client_id
        self._client_secret = client_secret
        self._portal = portal.strip().lower()
        self._token_url = token_url
        self._http = httpx.AsyncClient(transport=transport, timeout=timeout)

    async def _get(self, step: str, url: str, params: dict[str, str]) -> dict[str, Any]:
        try:
            response = await self._http.get(url, params=params)
        except httpx.HTTPError as exc:
            log.warning("Bitrix24 %s failed: %s", step, type(exc).__name__)
            raise _unavailable() from None
        if response.status_code >= 500:
            log.warning("Bitrix24 %s failed: HTTP %s", step, response.status_code)
            raise _unavailable()
        try:
            body = response.json()
        except ValueError:
            log.warning("Bitrix24 %s returned not JSON: HTTP %s", step, response.status_code)
            raise _unavailable() from None
        if not isinstance(body, dict) or response.status_code >= 400 or "error" in body:
            # Код ошибки портала (например invalid_grant) секретов не содержит; описание не пишем.
            error = body.get("error") if isinstance(body, dict) else None
            log.warning("Bitrix24 %s rejected: HTTP %s %s", step, response.status_code, str(error)[:60])
            raise InvalidBitrixAuth()
        return body

    async def current_user(self, code: str) -> BitrixProfile:
        if not (self._client_id and self._client_secret and self._portal):
            raise _unavailable()
        token = await self._get(
            "token",
            self._token_url,
            {
                "grant_type": "authorization_code",
                "client_id": self._client_id,
                "client_secret": self._client_secret,
                "code": code,
            },
        )
        access_token = token.get("access_token")
        endpoint = token.get("client_endpoint")
        if not isinstance(access_token, str) or not access_token or not isinstance(endpoint, str):
            raise InvalidBitrixAuth()
        # Токен отправляем только на свой портал: адрес из ответа сверяется с настройкой.
        parts = urlsplit(endpoint)
        if parts.scheme != "https" or (parts.hostname or "").lower() != self._portal or parts.port not in (None, 443):
            log.warning("Bitrix24 token is for another portal")
            raise InvalidBitrixAuth()
        body = await self._get("user.current", f"{endpoint.rstrip('/')}/user.current", {"auth": access_token})
        result = body.get("result")
        try:
            user_id = int(result["ID"])
        except (KeyError, TypeError, ValueError):
            raise InvalidBitrixAuth() from None
        return BitrixProfile(
            id=user_id,
            email=_text(result.get("EMAIL")),
            first_name=_text(result.get("NAME")),
            last_name=_text(result.get("LAST_NAME")),
            position=_text(result.get("WORK_POSITION")),
        )

    async def aclose(self) -> None:
        await self._http.aclose()
