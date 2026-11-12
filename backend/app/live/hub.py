"""Шина живых обновлений в памяти процесса: открытые соединения и рассылка событий.

Событие рождается после фиксации транзакции (`app.live.capture`), получатели считаются по правам
в момент рассылки, в событии только идентификаторы. Очереди и повторной доставки нет: пропущенное
клиент перезапрашивает сам после переподключения.
"""

from __future__ import annotations

import asyncio
import contextlib
import json
import logging
from collections import Counter
from collections.abc import Iterable
from dataclasses import dataclass, field
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from starlette.websockets import WebSocket

from app.appeals import policy
from app.appeals.views import Directory, Extras, facts
from app.clock import Clock
from app.domain.enums import HistoryKind
from app.models import Appeal, AuthSession, Notification

logger = logging.getLogger(__name__)

CLOSE_BAD_MESSAGE = 4400
CLOSE_UNAUTHORIZED = 4401
CLOSE_AUTH_TIMEOUT = 4408
CLOSE_TOO_MANY = 4429
CLOSE_GOING_AWAY = 1001

MAX_CONNECTIONS_PER_USER = 10
MAX_PENDING_PER_IP = 20


@dataclass(eq=False)
class Connection:
    websocket: WebSocket
    user_id: int
    session_id: int
    expires_at: datetime

    async def send(self, payload: dict) -> bool:
        try:
            await self.websocket.send_text(json.dumps(payload, ensure_ascii=False))
            return True
        except Exception:  # noqa: BLE001 — клиент ушёл; соединение уберёт его же обработчик
            return False

    async def close(self, code: int) -> None:
        with contextlib.suppress(Exception):
            await self.websocket.close(code)


@dataclass
class Pending:
    """Что произошло в транзакции. Копится в `session.info`, уходит в шину после фиксации."""

    history: list[tuple[int, str]] = field(default_factory=list)  # (appeal_id, kind)
    messages: list[tuple[int, int]] = field(default_factory=list)  # (appeal_id, message_id)
    notifications: list[tuple[int, int]] = field(default_factory=list)  # (user_id, notification_id)
    discussions: list[tuple[int, str]] = field(default_factory=list)  # (discussion_id, changed)
    sweep: bool = False  # сессии или пользователи менялись — перепроверить открытые соединения

    def __bool__(self) -> bool:
        return bool(self.history or self.messages or self.notifications or self.discussions or self.sweep)


class LiveHub:
    def __init__(self, clock: Clock) -> None:
        self.clock = clock
        self.sessionmaker: async_sessionmaker[AsyncSession] | None = None
        self._connections: dict[int, list[Connection]] = {}
        self._pending_by_ip: Counter[str] = Counter()
        self._tasks: set[asyncio.Task] = set()

    # --- соединения ---------------------------------------------------------------------------

    def admit_pending(self, ip: str) -> bool:
        """Соединение без входа. Их число с одного адреса ограничено, чтобы не занять все сокеты."""
        if self._pending_by_ip[ip] >= MAX_PENDING_PER_IP:
            return False
        self._pending_by_ip[ip] += 1
        return True

    def release_pending(self, ip: str) -> None:
        self._pending_by_ip[ip] -= 1
        if self._pending_by_ip[ip] <= 0:
            del self._pending_by_ip[ip]

    async def add(self, connection: Connection) -> None:
        mine = self._connections.setdefault(connection.user_id, [])
        mine.append(connection)
        while len(mine) > MAX_CONNECTIONS_PER_USER:
            await mine.pop(0).close(CLOSE_TOO_MANY)

    def remove(self, connection: Connection) -> None:
        mine = self._connections.get(connection.user_id)
        if mine and connection in mine:
            mine.remove(connection)
            if not mine:
                del self._connections[connection.user_id]

    def _all(self) -> list[Connection]:
        return [c for mine in self._connections.values() for c in mine]

    async def close_all(self, code: int = CLOSE_GOING_AWAY) -> None:
        for connection in self._all():
            self.remove(connection)
            await connection.close(code)

    # --- рассылка -----------------------------------------------------------------------------

    def publish(self, pending: Pending) -> None:
        """Вызывается после фиксации транзакции, из того же цикла событий. Не ждёт и не падает."""
        if not pending or not self._connections or self.sessionmaker is None:
            return
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:  # фиксация вне цикла событий (сид, миграции) — слушателей нет
            return
        task = loop.create_task(self._deliver(pending))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)

    async def drain(self) -> None:
        """Дождаться начатых рассылок (тесты и остановка приложения)."""
        while self._tasks:
            await asyncio.gather(*list(self._tasks), return_exceptions=True)

    async def _deliver(self, pending: Pending) -> None:
        try:
            async with self.sessionmaker() as session:
                directory = await Directory.load(session)
                await self._sweep(session, directory)
                await self._appeal_events(session, directory, pending)
                await self._notification_events(session, pending)
                for discussion_id, changed in dict.fromkeys(pending.discussions):
                    payload = {"type": "discussion.updated", "discussion_id": discussion_id, "changed": changed}
                    await self._send(self._all(), payload)
        except Exception:  # noqa: BLE001 — живые обновления не должны ронять ни запрос, ни фоновую задачу
            logger.exception("Не удалось разослать живые обновления")

    async def _send(self, connections: Iterable[Connection], payload: dict) -> None:
        await asyncio.gather(*(c.send(payload) for c in connections))

    async def _sweep(self, session: AsyncSession, directory: Directory) -> None:
        """Закрывает соединения, чья сессия закрыта или истекла либо чей пользователь отключён."""
        connections = self._all()
        if not connections:
            return
        alive = await self.alive_sessions(session, {c.session_id for c in connections})
        for connection in connections:
            user = directory.users.get(connection.user_id)
            if connection.session_id not in alive or user is None or user.is_disabled:
                self.remove(connection)
                await connection.close(CLOSE_UNAUTHORIZED)

    async def alive_sessions(self, session: AsyncSession, session_ids: set[int]) -> set[int]:
        rows = await session.execute(
            select(AuthSession.id).where(
                AuthSession.id.in_(session_ids), AuthSession.revoked_at.is_(None), AuthSession.expires_at > self.clock.now()
            )
        )
        return set(rows.scalars())

    async def _appeal_events(self, session: AsyncSession, directory: Directory, pending: Pending) -> None:
        kinds: dict[int, list[str]] = {}
        for appeal_id, kind in pending.history:
            if kind not in kinds.setdefault(appeal_id, []):
                kinds[appeal_id].append(kind)
        messages: dict[int, list[int]] = {}
        for appeal_id, message_id in pending.messages:
            messages.setdefault(appeal_id, []).append(message_id)
        ids = set(kinds) | set(messages)
        if not ids:
            return
        appeals = list((await session.execute(select(Appeal).where(Appeal.id.in_(ids)))).scalars())
        for user_id, connections in list(self._connections.items()):
            user = directory.users.get(user_id)
            if user is None:
                continue
            extras = await Extras.load(session, user, appeals)
            for appeal in appeals:
                rel = policy.relations(user, facts(appeal, directory, extras))
                if not rel:
                    continue
                changed = kinds.get(appeal.id)
                if changed:
                    base = {"appeal_id": appeal.id, "number": appeal.number, "status": str(appeal.status)}
                    if HistoryKind.CREATED in changed:
                        await self._send(connections, {"type": "appeal.created", **base})
                    else:
                        await self._send(connections, {"type": "appeal.updated", **base, "changed": changed})
                if policy.can_read_messages(rel):
                    for message_id in messages.get(appeal.id, []):
                        payload = {"type": "message.created", "appeal_id": appeal.id, "message_id": message_id}
                        await self._send(connections, payload)

    async def _notification_events(self, session: AsyncSession, pending: Pending) -> None:
        for user_id in dict.fromkeys(u for u, _ in pending.notifications):
            connections = self._connections.get(user_id)
            if not connections:
                continue
            unread = await unread_count(session, user_id)
            for owner, notification_id in pending.notifications:
                if owner == user_id:
                    payload = {"type": "notification.created", "notification_id": notification_id, "unread_count": unread}
                    await self._send(connections, payload)


async def unread_count(session: AsyncSession, user_id: int) -> int:
    count = await session.scalar(
        select(func.count()).select_from(Notification).where(Notification.user_id == user_id, Notification.read_at.is_(None))
    )
    return count or 0
