"""Живые обновления по WebSocket (B-24).

httpx не умеет WebSocket, поэтому тест разговаривает с приложением напрямую по ASGI — в том же цикле
событий, что и остальные запросы.
"""

from __future__ import annotations

import asyncio
import json
from datetime import timedelta

import httpx
from fastapi import FastAPI

from app.live import hub as live_hub

FORM = {"type": "problem", "category_id": 1, "priority": "medium", "text": "Нет назначения оборудования."}
SECRET_TEXT = "Нет назначения оборудования"


class Socket:
    def __init__(self, app: FastAPI, ip: str = "203.0.113.5") -> None:
        self.app = app
        self.ip = ip
        self.to_app: asyncio.Queue = asyncio.Queue()
        self.from_app: asyncio.Queue = asyncio.Queue()
        self.task: asyncio.Task | None = None

    async def open(self) -> Socket:
        scope = {
            "type": "websocket",
            "asgi": {"version": "3.0"},
            "scheme": "ws",
            "http_version": "1.1",
            "path": "/api/v1/ws",
            "raw_path": b"/api/v1/ws",
            "query_string": b"",
            "root_path": "",
            "headers": [],
            "client": (self.ip, 50000),
            "server": ("testserver", 80),
            "subprotocols": [],
            "state": {},
        }
        await self.to_app.put({"type": "websocket.connect"})
        self.task = asyncio.create_task(self.app(scope, self.to_app.get, self.from_app.put))
        assert (await self._next())["type"] == "websocket.accept"
        return self

    async def _next(self, timeout: float = 5) -> dict:
        return await asyncio.wait_for(self.from_app.get(), timeout)

    async def send(self, payload: object) -> None:
        text = payload if isinstance(payload, str) else json.dumps(payload)
        await self.to_app.put({"type": "websocket.receive", "text": text})

    async def recv(self) -> dict:
        """Следующее сообщение сервера; закрытие — `{"closed": <код>}`."""
        message = await self._next()
        if message["type"] == "websocket.close":
            return {"closed": message.get("code")}
        return json.loads(message["text"])

    async def login(self, headers: dict) -> dict:
        await self.send({"type": "auth", "token": headers["Authorization"].removeprefix("Bearer ")})
        return await self.recv()

    async def events(self) -> list[dict]:
        """Всё, что сервер прислал к этому моменту (после завершения начатых рассылок)."""
        await self.app.state.live.drain()
        out = []
        while not self.from_app.empty():
            message = self.from_app.get_nowait()
            out.append({"closed": message.get("code")} if message["type"] == "websocket.close" else json.loads(message["text"]))
        return out

    async def close(self) -> None:
        await self.to_app.put({"type": "websocket.disconnect", "code": 1000})
        if self.task is not None:
            await asyncio.wait_for(self.task, 5)


async def connect(app: FastAPI, headers: dict) -> Socket:
    socket = await Socket(app).open()
    assert (await socket.login(headers))["type"] == "ready"
    return socket


def of_type(events: list[dict], type: str) -> list[dict]:
    return [e for e in events if e.get("type") == type]


async def test_auth_is_the_first_message(client, app, demo, login_as) -> None:
    owner = await login_as("owner")
    ready = await (await Socket(app).open()).login(owner)
    assert ready["type"] == "ready"
    assert set(ready) == {"type", "user_id", "unread_count", "session_expires_at"}
    assert ready["user_id"] == (await client.get("/api/v1/me", headers=owner)).json()["id"]

    assert await (await Socket(app).open()).login({"Authorization": "Bearer no-such-token"}) == {"closed": 4401}

    not_auth = await Socket(app).open()
    await not_auth.send({"type": "ping"})
    assert await not_auth.recv() == {"closed": 4401}

    for garbage in ("not json", "[1, 2]", '{"no": "type"}', json.dumps({"type": "auth", "token": "x" * 5000})):
        broken = await Socket(app).open()
        await broken.send(garbage)
        assert await broken.recv() == {"closed": 4400}, garbage[:20]


async def test_bot_service_key_is_not_a_token(app, demo, settings) -> None:
    socket = await Socket(app).open()
    await socket.send({"type": "auth", "token": settings.bot_service_key})
    assert await socket.recv() == {"closed": 4401}


async def test_silent_socket_is_closed(app, demo, monkeypatch) -> None:
    monkeypatch.setattr("app.live.router.AUTH_TIMEOUT_SECONDS", 0.05)
    socket = await Socket(app).open()
    assert await socket.recv() == {"closed": 4408}


async def test_ping_pong_and_unknown_messages(app, demo, login_as) -> None:
    socket = await connect(app, await login_as("owner"))
    await socket.send({"type": "something.new", "x": 1})  # неизвестное сервер пропускает
    await socket.send({"type": "ping"})
    assert await socket.recv() == {"type": "pong"}
    await socket.close()
    assert app.state.live._all() == []


async def test_events_reach_only_those_who_see_the_appeal(client: httpx.AsyncClient, app, demo, login_as) -> None:
    """Чужое обращение не видно: сотрудник другого отдела не получает ни одного события."""
    author_headers = await login_as("employee_sales")
    owner_headers = await login_as("owner")
    author = await connect(app, author_headers)
    stranger = await connect(app, await login_as("employee_procurement"))
    owner = await connect(app, owner_headers)
    admin = await connect(app, await login_as("admin"))

    appeal = (await client.post("/api/v1/appeals", headers=author_headers, json=FORM)).json()
    created = {"type": "appeal.created", "appeal_id": appeal["id"], "number": appeal["number"], "status": "new"}
    for socket in (author, owner, admin):
        assert of_type(await socket.events(), "appeal.created") == [created]
    assert await stranger.events() == []

    # Смена статуса: видят все трое, автору ещё и уведомление со счётчиком.
    taken = await client.post(f"/api/v1/appeals/{appeal['id']}/take", headers=owner_headers)
    assert taken.status_code == 200
    author_events = await author.events()
    updated = of_type(author_events, "appeal.updated")
    assert len(updated) == 1
    assert (updated[0]["appeal_id"], updated[0]["status"]) == (appeal["id"], taken.json()["status"])
    assert "status_changed" in updated[0]["changed"]
    assert set(updated[0]) == {"type", "appeal_id", "number", "status", "changed"}
    notified = of_type(author_events, "notification.created")
    assert notified and notified[-1]["unread_count"] >= 1
    assert set(notified[-1]) == {"type", "notification_id", "unread_count"}
    unread = (await client.get("/api/v1/notifications/unread-count", headers=author_headers)).json()["count"]
    assert notified[-1]["unread_count"] == unread
    assert of_type(await owner.events(), "appeal.updated") and of_type(await admin.events(), "appeal.updated")
    assert await stranger.events() == []

    # Переписка: автор и собственник читают, администратор — нет.
    message = await client.post(
        f"/api/v1/appeals/{appeal['id']}/messages", headers=author_headers, json={"text": "Секретный текст переписки"}
    )
    assert message.status_code == 201
    expected = [{"type": "message.created", "appeal_id": appeal["id"], "message_id": message.json()["id"]}]
    assert of_type(await author.events(), "message.created") == expected
    assert of_type(await owner.events(), "message.created") == expected
    assert of_type(await admin.events(), "message.created") == []
    assert await stranger.events() == []


async def test_events_carry_no_texts(client, app, demo, login_as) -> None:
    author_headers = await login_as("employee_sales")
    owner = await connect(app, await login_as("owner"))
    appeal = (await client.post("/api/v1/appeals", headers=author_headers, json=FORM)).json()
    await client.post(f"/api/v1/appeals/{appeal['id']}/messages", headers=author_headers, json={"text": SECRET_TEXT + "!"})
    events = await owner.events()
    assert events
    assert SECRET_TEXT not in json.dumps(events, ensure_ascii=False)


async def test_rolled_back_request_sends_nothing(client, app, demo, login_as) -> None:
    owner = await connect(app, await login_as("owner"))
    refused = await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json={**FORM, "text": ""})
    assert refused.status_code == 422
    assert await owner.events() == []


async def test_discussion_events_go_to_everyone(client, app, demo, login_as, time_machine) -> None:
    voter_headers = await login_as("employee_sales")
    watcher = await connect(app, await login_as("employee_pm"))
    published = await client.post(
        "/api/v1/appeals/1/discussion",
        headers=await login_as("head_procurement"),
        json={"public_text": "Публиковать обзор улучшений?", "deadline": (time_machine.now + timedelta(days=3)).isoformat()},
    )
    assert published.status_code == 201
    discussion = published.json()
    # Обращение сотруднику не видно, а обсуждение — да: событие обсуждения есть, события обращения нет.
    assert await watcher.events() == [{"type": "discussion.updated", "discussion_id": discussion["id"], "changed": "published"}]

    url = f"/api/v1/discussions/{discussion['id']}"
    for value in ("for", "against"):  # новый голос и изменённый
        assert (await client.put(f"{url}/vote", headers=voter_headers, json={"value": value})).status_code == 200
        assert await watcher.events() == [{"type": "discussion.updated", "discussion_id": discussion["id"], "changed": "vote"}]
    assert (await client.delete(f"{url}/vote", headers=voter_headers)).status_code == 200
    assert [e["changed"] for e in await watcher.events()] == ["vote"]
    assert (await client.post(f"{url}/comments", headers=voter_headers, json={"text": "Поддерживаю"})).status_code == 201
    assert [e["changed"] for e in await watcher.events()] == ["comment"]


async def test_logout_and_disabling_close_the_socket(client, app, demo, login_as) -> None:
    employee_headers = await login_as("employee_sales")
    leaving = await connect(app, employee_headers)
    assert (await client.post("/api/v1/auth/logout", headers=employee_headers)).status_code == 204
    assert await leaving.events() == [{"closed": 4401}]

    head_headers = await login_as("head_procurement")
    head = await connect(app, head_headers)
    head_id = (await client.get("/api/v1/me", headers=head_headers)).json()["id"]
    bystander = await connect(app, await login_as("owner"))
    disabled = await client.patch(f"/api/v1/admin/users/{head_id}", headers=await login_as("admin"), json={"is_disabled": True})
    assert disabled.status_code == 200
    assert {"closed": 4401} in await head.events()
    assert {"closed": 4401} not in await bystander.events()


async def test_expired_session_closes_the_socket(client, app, demo, login_as, time_machine) -> None:
    socket = await connect(app, await login_as("owner"))
    await time_machine.advance(days=400)
    await socket.send({"type": "ping"})
    assert await socket.recv() == {"closed": 4401}


async def test_connection_limits(app, demo, login_as, monkeypatch) -> None:
    monkeypatch.setattr(live_hub, "MAX_CONNECTIONS_PER_USER", 2)
    monkeypatch.setattr(live_hub, "MAX_PENDING_PER_IP", 1)
    headers = await login_as("owner")
    first = await connect(app, headers)
    second = await connect(app, headers)
    third = await connect(app, headers)
    assert await first.events() == [{"closed": 4429}]  # закрывается самое старое
    assert await second.events() == [] and await third.events() == []

    waiting = await Socket(app, ip="198.51.100.7").open()  # открыт, но ещё не вошёл
    refused = await Socket(app, ip="198.51.100.7").open()
    assert await refused.recv() == {"closed": 4429}
    assert (await waiting.login(headers))["type"] == "ready"
    assert (await (await Socket(app, ip="198.51.100.7").open()).login(headers))["type"] == "ready"


async def test_background_job_events_are_delivered(client, app, demo, login_as, time_machine) -> None:
    """Эскалация идёт из фоновой задачи, а не из запроса — событие всё равно доходит."""
    author_headers = await login_as("employee_sales")
    appeal = (await client.post("/api/v1/appeals", headers=author_headers, json=FORM)).json()
    owner = await connect(app, await login_as("owner"))
    await time_machine.advance(days=3, step=timedelta(minutes=30))
    updated = [e for e in of_type(await owner.events(), "appeal.updated") if e["appeal_id"] == appeal["id"]]
    assert any("escalated" in e["changed"] for e in updated), (updated, await owner.events())
