"""Статусы, решения и приватная переписка (B-06). Истории 13–16, 28–33, 46, 60.

Сид: A-001 «Новое» (ответственный — Марат Сейткали, автор — Айгерим Нурланова), A-002 «На рассмотрении»,
A-003 «В работе» (ответственный — Алия Сапарова, руководитель — Нурлан Беков), A-005 «Ожидает уточнения»
(автор — Дина Жуматова), A-009 «В работе», A-017 «Отклонено».
"""

from __future__ import annotations

import httpx
import pytest
from fastapi import FastAPI

from app.models import AppealParticipant
from tests.support import bot_headers, telegram_id_of


async def act(client: httpx.AsyncClient, headers: dict, appeal_id: int, action: str, body: dict | None = None):
    return await client.post(f"/api/v1/appeals/{appeal_id}/{action}", headers=headers, json=body)


async def card(client: httpx.AsyncClient, headers: dict, appeal_id: int) -> dict:
    return (await client.get(f"/api/v1/appeals/{appeal_id}", headers=headers)).json()


# --- путь обращения целиком --------------------------------------------------------------------


async def test_full_path_from_new_to_implemented(client, login_as, time_machine) -> None:
    """Истории 28, 29, 13, 30, 32, 15: взял, спросил, автор ответил, решение, результат."""
    head = await login_as("head_procurement")
    author = await login_as("employee_procurement")

    taken = await act(client, head, 1, "take", {"comment": "Смотрю, вернусь сегодня"})
    assert taken.status_code == 200, taken.text
    assert taken.json()["status"] == "in_review"
    first_response = taken.json()["first_response_at"]
    assert first_response and taken.json()["due_state"] == "answered"

    await time_machine.advance(hours=1)
    asked = await act(client, head, 1, "request-info", {"question": "Пришлите пример заявки"})
    assert asked.json()["status"] == "awaiting_info"
    assert "reply_clarification" in (await card(client, author, 1))["allowed_actions"]

    reply = await client.post("/api/v1/appeals/1/messages", headers=author, json={"text": "Пример во вложении"})
    assert reply.status_code == 201
    assert (await card(client, author, 1))["status"] == "in_review"

    decided = await act(client, head, 1, "start-work", {"decision": "Добавим обязательные поля в шаблон"})
    assert (decided.json()["status"], decided.json()["decision"]) == ("in_progress", "Добавим обязательные поля в шаблон")

    done = await act(client, head, 1, "implement", {"result": "Шаблон заявки обновлён", "public_result": "Обновили шаблон"})
    body = done.json()
    assert (body["status"], body["result"], body["public_result"]) == ("implemented", "Шаблон заявки обновлён", "Обновили шаблон")
    assert body["first_response_at"] == first_response, "первый ответ фиксируется один раз"
    assert body["allowed_actions"] == [] or set(body["allowed_actions"]) <= {"publish_discussion"}

    statuses = [
        (e["old_value"], e["new_value"])
        for e in (await client.get("/api/v1/appeals/1/history", headers=head)).json()
        if e["kind"] == "status_changed"
    ]
    assert statuses == [
        ("new", "in_review"), ("in_review", "awaiting_info"), ("awaiting_info", "in_review"),
        ("in_review", "in_progress"), ("in_progress", "implemented"),
    ]
    messages = (await client.get("/api/v1/appeals/1/messages", headers=author)).json()
    assert [(m["text"], m["is_clarification_question"]) for m in messages] == [
        ("Смотрю, вернусь сегодня", False), ("Пришлите пример заявки", True), ("Пример во вложении", False),
    ]


async def test_reject_requires_reason_and_author_sees_it(client, login_as) -> None:
    """Истории 31, 14."""
    head = await login_as("head_procurement")
    for body in ({}, {"reason": ""}, {"reason": "   "}):
        response = await act(client, head, 2, "reject", body)
        assert (response.status_code, response.json()["error"]["code"]) == (422, "validation_error")
    rejected = await act(client, head, 2, "reject", {"reason": "Коммерческие сроки раскрывать нельзя"})
    assert rejected.json()["status"] == "rejected"
    author_view = await card(client, await login_as("employee_procurement"), 2)
    assert author_view["rejection_reason"] == "Коммерческие сроки раскрывать нельзя"


async def test_implemented_requires_result_and_work_requires_decision(client, login_as) -> None:
    head = await login_as("head_sales")
    assert (await act(client, head, 9, "implement", {"result": " "})).status_code == 422
    assert (await act(client, head, 9, "implement", {})).status_code == 422
    assert (await act(client, await login_as("head_procurement"), 2, "start-work", {"decision": ""})).status_code == 422


async def test_praise_is_accepted_with_one_action(client, login_as) -> None:
    """История 33."""
    praise = (
        await client.post(
            "/api/v1/appeals",
            headers=await login_as("employee_sales"),
            json={"type": "praise", "category_id": 16, "priority": "low", "text": "Спасибо за новые переговорные!"},
        )
    ).json()
    head = await login_as("head_admin_office")
    assert "take" not in (await card(client, head, praise["id"]))["allowed_actions"]
    assert (await act(client, head, praise["id"], "take")).status_code == 409
    accepted = await act(client, head, praise["id"], "accept-feedback", {"comment": "Передали команде"})
    assert (accepted.json()["status"], accepted.json()["closed_reason"]) == ("closed", "feedback_accepted")


# --- запрещённые переходы ----------------------------------------------------------------------


@pytest.mark.parametrize(
    ("who", "appeal_id", "action", "body"),
    [
        ("head_procurement", 1, "implement", {"result": "x"}),  # Новое -> Реализовано
        ("head_procurement", 1, "reject", {"reason": "x"}),  # отказ только после «Взять»
        ("head_procurement", 1, "accept-feedback", None),  # не отзыв
        ("head_procurement", 2, "take", None),  # уже на рассмотрении
        ("head_accounting", 5, "start-work", {"decision": "x"}),  # ждём ответа автора
        ("head_sales", 9, "reject", {"reason": "x"}),  # уже в работе
        ("head_admin_office", 17, "take", None),  # отклонено — финальный статус
        ("head_admin_office", 17, "request-info", {"question": "x"}),
    ],
)
async def test_forbidden_transitions_return_409(client, login_as, who, appeal_id, action, body) -> None:
    response = await act(client, await login_as(who), appeal_id, action, body)
    assert response.status_code == 409, response.text
    error = response.json()["error"]
    assert error["code"] == "invalid_transition"
    assert error["details"]["action"] == action.replace("-", "_") and "allowed_actions" in error["details"]


# --- кто может менять статус -------------------------------------------------------------------


async def test_head_and_owner_act_without_becoming_assignee(client, login_as) -> None:
    """Истории 46, 60: руководитель и собственник решают по обращению, ответственный не меняется."""
    done = await act(client, await login_as("head_design"), 3, "implement", {"result": "Правило номенклатуры утверждено"})
    assert done.status_code == 200
    assert done.json()["assignee"]["full_name"] == "Алия Сапарова"

    taken = await act(client, await login_as("owner"), 7, "take")
    assert taken.status_code == 200
    assert taken.json()["assignee"]["full_name"] == "Даурен Исаев"


@pytest.mark.parametrize(("who", "status"), [("admin", 403), ("employee_procurement", 403), ("employee_sales", 403)])
async def test_admin_author_and_strangers_cannot_change_status(client, login_as, who, status) -> None:
    """Матрица: «Менять статус» — нет у сотрудника и администратора."""
    response = await act(client, await login_as(who), 1, "take")
    assert response.status_code == status


# --- приватная переписка -----------------------------------------------------------------------


@pytest.mark.parametrize(
    ("who", "can_read"),
    [
        ("employee_accounting", True),  # автор A-005
        ("head_accounting", True),  # ответственный и руководитель
        ("owner", True),
        ("admin", False),
        ("employee_sales", False),
    ],
)
async def test_private_thread_visibility(client, login_as, who, can_read) -> None:
    response = await client.get("/api/v1/appeals/5/messages", headers=await login_as(who))
    assert response.status_code == (200 if can_read else 403)
    if can_read:
        assert response.json()[0]["is_clarification_question"] is True
    post = await client.post("/api/v1/appeals/5/messages", headers=await login_as(who), json={"text": "Добрый день"})
    assert (post.status_code == 201) == can_read


async def test_participant_of_merged_duplicate_does_not_see_thread(app: FastAPI, client, login_as, clock) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        session.add(AppealParticipant(appeal_id=5, user_id=8, added_at=clock.now()))
    assert (await client.get("/api/v1/appeals/5/messages", headers=await login_as("employee_sales"))).status_code == 403


async def test_author_answers_clarification_in_bot(client, demo, login_as) -> None:
    """История 13: ответ на уточняющий вопрос прямо в боте возвращает обращение на рассмотрение."""
    response = await client.post(
        "/api/v1/appeals/5/messages",
        headers=bot_headers(telegram_id_of("employee_accounting")),
        json={"text": "Чаще всего акты сверки"},
    )
    assert response.status_code == 201
    assert response.json()["author"]["full_name"] == "Дина Жуматова"
    head = await login_as("head_accounting")
    assert (await card(client, head, 5))["status"] == "in_review"
    kinds = [e["kind"] for e in (await client.get("/api/v1/appeals/5/history", headers=head)).json()]
    assert kinds[-2:] == ["clarification_answered", "status_changed"]


async def test_first_message_from_assignee_counts_as_first_response(client, login_as) -> None:
    head = await login_as("head_procurement")
    sent = await client.post("/api/v1/appeals/1/messages", headers=head, json={"text": "Приняли, посмотрю"})
    assert sent.status_code == 201
    after = await card(client, head, 1)
    assert after["status"] == "new" and after["first_response_at"] is not None and after["due_state"] == "answered"

    author = await login_as("employee_procurement")
    await client.post("/api/v1/appeals/20/messages", headers=author, json={"text": "Дополню"})
    assert (await card(client, author, 20))["first_response_at"] is None, "сообщение автора — не ответ"


async def test_no_messages_after_final_status(client, login_as) -> None:
    response = await client.post("/api/v1/appeals/17/messages", headers=await login_as("employee_office"), json={"text": "А когда?"})
    assert (response.status_code, response.json()["error"]["code"]) == (409, "invalid_transition")
