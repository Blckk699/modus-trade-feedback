"""Очередь уведомлений для бота и счётчик непрочитанного (B-08). Истории 12, 19, 25, 40, 45.

Сид: A-001 «Новое» (ответственный — Марат Сейткали id 3, автор — Айгерим Нурланова id 4),
A-005 «Ожидает уточнения» (ответственный — Ольга Петрова id 5, автор — Дина Жуматова id 6).
"""

from __future__ import annotations

import httpx
from fastapi import FastAPI
from sqlalchemy import select, update

from app.models import Appeal, AppealParticipant, Notification, User
from app.notifications import service as notify
from tests.support import telegram_id_of

BOT = {"X-Service-Key": "test-service-key"}
FORM = {"type": "problem", "category_id": 1, "priority": "medium", "text": "Нет назначения оборудования в заявке."}


async def inbox(app: FastAPI, user_id: int) -> list[Notification]:
    async with app.state.sessionmaker() as session:
        rows = await session.execute(select(Notification).where(Notification.user_id == user_id).order_by(Notification.id))
        return list(rows.scalars())


async def pending(client: httpx.AsyncClient) -> list[dict]:
    response = await client.get("/api/v1/bot/notifications/pending", headers=BOT)
    assert response.status_code == 200, response.text
    return response.json()


# --- какие события порождают уведомления и кому -------------------------------------------------


async def test_new_appeal_notifies_assignee_and_author(app, client, login_as) -> None:
    """Истории 25 и 9."""
    created = (await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json=FORM)).json()
    assignee = await inbox(app, 3)
    assert [n.kind for n in assignee] == ["appeal_assigned"]
    assert created["number"] in assignee[0].text and assignee[0].path == f"/appeals/{created['id']}"
    author = await inbox(app, 8)
    assert [n.kind for n in author] == ["appeal_created"] and "Марат Сейткали" in author[0].text


async def test_bot_submission_gets_no_duplicate_confirmation(app, client, demo) -> None:
    headers = {**BOT, "X-Telegram-Id": str(telegram_id_of("employee_sales"))}
    await client.post("/api/v1/appeals", headers=headers, json={**FORM, "source": "bot"})
    assert await inbox(app, 8) == []
    assert [n.kind for n in await inbox(app, 3)] == ["appeal_assigned"]


async def test_status_change_notifies_author_not_actor(app, client, login_as) -> None:
    """История 12."""
    head = await login_as("head_procurement")
    await client.post("/api/v1/appeals/1/take", headers=head)
    await client.post("/api/v1/appeals/1/reject", headers=head, json={"reason": "Шаблон менять не будем"})
    author = await inbox(app, 4)
    assert [n.kind for n in author] == ["status_changed", "status_changed"]
    assert "отклонено" in author[1].text and "Шаблон менять не будем" in author[1].text
    assert await inbox(app, 3) == []


async def test_clarification_round_trip(app, client, login_as) -> None:
    """История 13: вопрос приходит автору с кнопкой «Ответить», ответ — ответственному."""
    head = await login_as("head_procurement")
    await client.post("/api/v1/appeals/1/take", headers=head)
    await client.post("/api/v1/appeals/1/request-info", headers=head, json={"question": "Какой объект?"})
    question = (await inbox(app, 4))[-1]
    assert question.kind == "clarification_requested" and "Какой объект?" in question.text
    assert [b["type"] for b in question.buttons] == ["reply_clarification", "open_appeal"]

    await client.post("/api/v1/appeals/1/messages", headers=await login_as("employee_procurement"), json={"text": "Склад №2"})
    answer = (await inbox(app, 3))[-1]
    assert answer.kind == "clarification_answered" and "Склад №2" in answer.text


async def test_merged_participant_gets_main_appeal_statuses(app, client, login_as, clock) -> None:
    """История 19."""
    async with app.state.sessionmaker() as session, session.begin():
        session.add(AppealParticipant(appeal_id=1, user_id=8, added_at=clock.now()))
    await client.post("/api/v1/appeals/1/take", headers=await login_as("head_procurement"))
    assert [n.kind for n in await inbox(app, 8)] == ["status_changed"]


async def test_reassign_notifies_new_assignee(app, client, login_as) -> None:
    await client.post("/api/v1/appeals/1/reassign", headers=await login_as("owner"), json={"assignee_id": 13, "reason": "IT"})
    assert [n.kind for n in await inbox(app, 13)] == ["appeal_assigned"]


async def test_messages_notify_the_other_side(app, client, login_as) -> None:
    await client.post("/api/v1/appeals/1/messages", headers=await login_as("head_procurement"), json={"text": "Уточню у продаж"})
    assert [n.kind for n in await inbox(app, 4)] == ["message_received"]
    await client.post("/api/v1/appeals/1/messages", headers=await login_as("employee_procurement"), json={"text": "Спасибо"})
    assert [n.kind for n in await inbox(app, 3)] == ["message_received"]


async def test_escalation_and_consent_notifications(app, demo, clock) -> None:
    """Шаги эскалации (B-07) и запрос согласия (B-11) вызывают эти функции."""
    async with app.state.sessionmaker() as session, session.begin():
        appeal = await session.get(Appeal, 7)
        tz = app.state.settings.tz
        await notify.deadline_reminder(session, appeal, clock.now(), tz)
        await notify.escalation_head(session, appeal, 19, clock.now())
        await notify.name_consent_request(session, appeal, 12, clock.now())
    assert [n.kind for n in await inbox(app, 13)] == ["deadline_reminder"]
    assert [n.kind for n in await inbox(app, 19)] == ["escalation_head"]
    consent = (await inbox(app, 6))[-1]
    assert consent.kind == "name_consent_request" and consent.path == "/discussions/12"
    assert [b["type"] for b in consent.buttons] == ["name_consent_show", "name_consent_hide"]


# --- доставка ботом ------------------------------------------------------------------------------


async def test_bot_takes_queue_and_acknowledges(client, login_as) -> None:
    await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json=FORM)
    queue = await pending(client)
    assert {n["kind"] for n in queue} == {"appeal_assigned", "appeal_created"}
    assigned = next(n for n in queue if n["kind"] == "appeal_assigned")
    assert assigned["recipient"]["telegram_id"] == telegram_id_of("head_procurement")
    assert assigned["appeal"]["number"] == "A-021" and assigned["buttons"][0]["type"] == "open_appeal"

    for n in queue:
        response = await client.post(f"/api/v1/bot/notifications/{n['id']}/ack", headers=BOT, json={"telegram_message_id": 555})
        assert response.status_code == 204
    assert await pending(client) == [], "подтверждённое не доставляется повторно"


async def test_failed_delivery_is_retried_later(client, login_as, time_machine) -> None:
    await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json=FORM)
    first, second = await pending(client)
    await client.post(f"/api/v1/bot/notifications/{first['id']}/fail", headers=BOT, json={"error": "timeout"})
    await client.post(f"/api/v1/bot/notifications/{second['id']}/fail", headers=BOT, json={"error": "blocked", "permanent": True})
    assert await pending(client) == []
    await time_machine.advance(minutes=1)
    retried = await pending(client)
    assert [n["id"] for n in retried] == [first["id"]] and retried[0]["attempts"] == 1


async def test_bot_queue_requires_service_key(app, client, login_as) -> None:
    assert (await client.get("/api/v1/bot/notifications/pending")).status_code == 401
    assert (await client.get("/api/v1/bot/notifications/pending", headers={"X-Service-Key": "nope"})).status_code == 401
    user_headers = await login_as("owner")
    assert (await client.get("/api/v1/bot/notifications/pending", headers=user_headers)).status_code == 401


async def test_recipients_without_telegram_are_skipped(app, client, login_as) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        await session.execute(update(User).where(User.id == 3).values(telegram_id=None))
    await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json=FORM)
    assert [n["kind"] for n in await pending(client)] == ["appeal_created"]


# --- счётчик непрочитанного ------------------------------------------------------------------------


async def test_unread_counter_and_mark_read(client, login_as) -> None:
    head = await login_as("head_procurement")
    for _ in range(2):
        await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json=FORM)
    assert (await client.get("/api/v1/notifications/unread-count", headers=head)).json() == {"count": 2}

    listing = (await client.get("/api/v1/appeals", headers=head, params={"q": "A-021"})).json()
    assert listing["items"][0]["has_unread"] is True

    after = await client.post("/api/v1/notifications/read", headers=head, json={"appeal_id": 21})
    assert after.json() == {"count": 1}
    notifications = (await client.get("/api/v1/notifications", headers=head)).json()
    assert [n["is_read"] for n in notifications["items"]] == [False, True]
    assert (await client.post("/api/v1/notifications/read", headers=head, json={"all": True})).json() == {"count": 0}
    assert (await client.get("/api/v1/notifications", headers=head, params={"unread_only": True})).json()["total"] == 0


async def test_user_text_is_escaped_for_telegram_html(app, client, login_as) -> None:
    """Пользовательские фрагменты экранируются: бот шлёт текст с parse_mode=HTML."""
    created = (
        await client.post(
            "/api/v1/appeals",
            headers=await login_as("employee_sales"),
            json={**FORM, "summary": "Счёт <b>ООО «Рога & Копыта»</b>", "text": "a < b & c"},
        )
    ).json()
    head = await login_as("head_procurement")
    await client.post(f"/api/v1/appeals/{created['id']}/take", headers=head)
    await client.post(f"/api/v1/appeals/{created['id']}/request-info", headers=head, json={"question": "Это <script> & что?"})
    texts = [n.text for n in await inbox(app, 3) + await inbox(app, 8)]
    joined = "\n".join(texts)
    assert "&lt;b&gt;ООО «Рога &amp; Копыта»&lt;/b&gt;" in joined
    assert "Это &lt;script&gt; &amp; что?" in joined
    assert "<script>" not in joined and "<b>ООО" not in joined
    assert all(t.count("<b>") == t.count("</b>") for t in texts), "своя разметка — только номер обращения"
