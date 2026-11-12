"""WebSocket `/api/v1/ws`: вход первым сообщением, пинг, закрытие по истечении сессии.

Протокол описан в контракте (`contract/openapi.yaml`, раздел live).
"""

from __future__ import annotations

import asyncio
import json

from fastapi import APIRouter
from starlette.websockets import WebSocket, WebSocketDisconnect

from app.auth.service import session_by_token
from app.errors import AppError
from app.live.hub import (
    CLOSE_AUTH_TIMEOUT,
    CLOSE_BAD_MESSAGE,
    CLOSE_TOO_MANY,
    CLOSE_UNAUTHORIZED,
    Connection,
    LiveHub,
    unread_count,
)

router = APIRouter(tags=["live"])

AUTH_TIMEOUT_SECONDS = 10
MAX_MESSAGE_BYTES = 4096
IDLE_CHECK_SECONDS = 60


class _BadMessage(Exception):
    pass


async def _receive(websocket: WebSocket, timeout: float) -> dict:
    """Следующее сообщение клиента. `TimeoutError` — тишина, `_BadMessage` — не наш формат."""
    message = await asyncio.wait_for(websocket.receive(), timeout)
    if message["type"] == "websocket.disconnect":
        raise WebSocketDisconnect(message.get("code", 1000))
    text = message.get("text")
    if text is None or len(text.encode("utf-8")) > MAX_MESSAGE_BYTES:
        raise _BadMessage
    try:
        data = json.loads(text)
    except ValueError as error:
        raise _BadMessage from error
    if not isinstance(data, dict) or not isinstance(data.get("type"), str):
        raise _BadMessage
    return data


async def _authenticate(websocket: WebSocket, hub: LiveHub) -> Connection | None:
    """Ждёт `auth`, отвечает `ready`. При отказе сам закрывает соединение и возвращает None."""
    try:
        data = await _receive(websocket, AUTH_TIMEOUT_SECONDS)
    except TimeoutError:
        await websocket.close(CLOSE_AUTH_TIMEOUT)
        return None
    except _BadMessage:
        await websocket.close(CLOSE_BAD_MESSAGE)
        return None
    token = data.get("token")
    if data["type"] != "auth" or not isinstance(token, str) or not token:
        await websocket.close(CLOSE_UNAUTHORIZED)
        return None
    async with hub.sessionmaker() as session:
        try:
            auth, user = await session_by_token(session, token, hub.clock.now())
        except AppError:
            await websocket.close(CLOSE_UNAUTHORIZED)
            return None
        unread = await unread_count(session, user.id)
    connection = Connection(websocket, user.id, auth.id, auth.expires_at)
    # Сначала `ready`, потом подписка: до него событий быть не должно.
    await connection.send(
        {
            "type": "ready",
            "user_id": user.id,
            "unread_count": unread,
            "session_expires_at": auth.expires_at.astimezone(websocket.app.state.settings.tz).isoformat(),
        }
    )
    await hub.add(connection)
    return connection


@router.websocket("/ws")
async def live_updates(websocket: WebSocket) -> None:
    hub: LiveHub = websocket.app.state.live
    ip = websocket.client.host if websocket.client else "unknown"
    await websocket.accept()
    if not hub.admit_pending(ip):
        await websocket.close(CLOSE_TOO_MANY)
        return
    try:
        connection = await _authenticate(websocket, hub)
    except WebSocketDisconnect:
        return
    finally:
        hub.release_pending(ip)
    if connection is None:
        return
    try:
        while True:
            remaining = (connection.expires_at - hub.clock.now()).total_seconds()
            if remaining <= 0:
                await connection.close(CLOSE_UNAUTHORIZED)
                return
            try:
                data = await _receive(websocket, min(remaining, IDLE_CHECK_SECONDS))
            except TimeoutError:
                continue
            except _BadMessage:
                await connection.close(CLOSE_BAD_MESSAGE)
                return
            if data["type"] == "ping":
                async with hub.sessionmaker() as session:
                    alive = await hub.alive_sessions(session, {connection.session_id})
                if not alive:
                    await connection.close(CLOSE_UNAUTHORIZED)
                    return
                await connection.send({"type": "pong"})
            # Остальные типы пропускаем: клиент может быть новее сервера.
    except WebSocketDisconnect:
        return
    finally:
        hub.remove(connection)
