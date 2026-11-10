"""Обращение: создание через форму, список, карточка, история, вложения (B-04).

Истории 6–11, 17, 42, 59, 63. Видимость — строка «Видеть обращения» матрицы доступа:
сотрудник — свои, ответственный — назначенные, руководитель — своего подразделения,
администратор и собственник — все.
"""

from __future__ import annotations

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import update

from app.models import AppealParticipant, Department
from tests.support import bot_headers, telegram_id_of

FORM = {
    "type": "problem",
    "category_id": 1,
    "priority": "medium",
    "text": "Поставщик дважды прислал счёт без спецификации, бухгалтерия не может его провести.",
    "proposed_solution": "Не принимать счёт без спецификации",
}


async def numbers(client: httpx.AsyncClient, headers: dict, **params) -> list[str]:
    response = await client.get("/api/v1/appeals", headers=headers, params={"page_size": 200, **params})
    assert response.status_code == 200, response.text
    return sorted(item["number"] for item in response.json()["items"])


# --- создание -------------------------------------------------------------------------------


async def test_employee_creates_appeal_through_form(client, login_as) -> None:
    """Истории 6, 8, 9, 63: форма с предлагаемым решением, сразу виден номер и статус."""
    headers = await login_as("employee_accounting")
    response = await client.post("/api/v1/appeals", headers=headers, json=FORM)
    assert response.status_code == 201, response.text
    appeal = response.json()
    assert appeal["number"] == "A-021"
    assert (appeal["status"], appeal["source"], appeal["access"]) == ("new", "form", "full")
    assert appeal["proposed_solution"] == FORM["proposed_solution"]
    assert appeal["summary"], "краткая суть подставляется из текста"
    assert appeal["author"]["full_name"] == "Дина Жуматова"
    assert appeal["viewer_relations"] == ["author"]
    assert "send_message" in appeal["allowed_actions"] and "take" not in appeal["allowed_actions"]

    second = await client.post("/api/v1/appeals", headers=await login_as("owner"), json={**FORM, "type": "praise"})
    assert second.json()["number"] == "A-022"


async def test_bot_submits_confirmed_draft_with_forward_source(client, demo) -> None:
    body = {**FORM, "source": "bot", "forwarded_from": "Чат «Закупки — продажи»"}
    response = await client.post("/api/v1/appeals", headers=bot_headers(telegram_id_of("employee_sales")), json=body)
    assert response.status_code == 201
    assert (response.json()["source"], response.json()["forwarded_from"]) == ("bot", body["forwarded_from"])


async def test_create_validates_fields(client, login_as) -> None:
    headers = await login_as("employee_sales")
    no_text = await client.post("/api/v1/appeals", headers=headers, json={**FORM, "text": ""})
    assert no_text.status_code == 422
    assert no_text.json()["error"]["details"]["fields"][0]["field"] == "text"
    bad_category = await client.post("/api/v1/appeals", headers=headers, json={**FORM, "category_id": 999})
    assert (bad_category.status_code, bad_category.json()["error"]["code"]) == (422, "validation_error")
    meeting_source = await client.post("/api/v1/appeals", headers=headers, json={**FORM, "source": "meeting"})
    assert meeting_source.status_code == 422, "источник «совещание» — только через подтверждение черновика"


# --- видимость --------------------------------------------------------------------------------


async def test_employee_sees_only_own_appeals(client, login_as) -> None:
    """Истории 10, 17: свои обращения, чужие не видны."""
    headers = await login_as("employee_procurement")
    assert await numbers(client, headers) == ["A-001", "A-002", "A-004", "A-020"]
    foreign = await client.get("/api/v1/appeals/7", headers=headers)
    assert (foreign.status_code, foreign.json()["error"]["code"]) == (403, "forbidden")
    assert (await client.get("/api/v1/appeals/7/history", headers=headers)).status_code == 403


async def test_assignee_sees_assigned_appeals(client, login_as) -> None:
    headers = await login_as("employee_it")
    assert await numbers(client, headers) == ["A-007", "A-012"]
    assert await numbers(client, headers, scope="assigned") == ["A-007", "A-012"]
    assert await numbers(client, headers, scope="mine") == []


async def test_head_sees_department_appeals(client, login_as) -> None:
    """История 42: руководитель видит обращения категорий своего подразделения."""
    headers = await login_as("head_accounting")
    assert await numbers(client, headers) == ["A-005", "A-008"]
    assert await numbers(client, headers, scope="department") == ["A-005", "A-008"]
    assert (await client.get("/api/v1/appeals/1", headers=headers)).status_code == 403


@pytest.mark.parametrize("who", ["admin", "owner"])
async def test_admin_and_owner_see_everything(client, login_as, who) -> None:
    """История 59: собственник открывает любое обращение и его историю."""
    headers = await login_as(who)
    assert len(await numbers(client, headers)) == 20
    assert (await client.get("/api/v1/appeals/17/history", headers=headers)).status_code == 200


async def test_scope_restrictions(client, login_as) -> None:
    employee = await login_as("employee_sales")
    assert (await client.get("/api/v1/appeals", headers=employee, params={"scope": "unassigned"})).status_code == 403
    assert (await client.get("/api/v1/appeals", headers=employee, params={"scope": "department"})).status_code == 403
    admin = await login_as("admin")
    response = await client.post("/api/v1/appeals", headers=employee, json={**FORM, "category_id": None})
    assert response.json()["assignee"] is None
    assert await numbers(client, admin, scope="unassigned") == [response.json()["number"]]


async def test_missing_appeal_is_404(client, login_as) -> None:
    response = await client.get("/api/v1/appeals/999", headers=await login_as("owner"))
    assert (response.status_code, response.json()["error"]["code"]) == (404, "not_found")


async def test_participant_sees_main_appeal_without_foreign_text(app: FastAPI, client, login_as, clock) -> None:
    """История 19: автор присоединённого повтора видит статус основного, но не чужой текст и имя."""
    async with app.state.sessionmaker() as session, session.begin():
        session.add(AppealParticipant(appeal_id=3, user_id=8, added_at=clock.now()))  # Сергей Ким -> A-003
    headers = await login_as("employee_sales")
    card = (await client.get("/api/v1/appeals/3", headers=headers)).json()
    assert (card["access"], card["status"]) == ("participant", "in_progress")
    assert card["text"] is None and card["author"] is None and card["attachments"] == []
    assert card["participants_count"] == 2
    assert card["allowed_actions"] == [] and card["viewer_relations"] == ["participant"]
    assert "A-003" in await numbers(client, headers, scope="mine")
    assert (await client.get("/api/v1/appeals/3/history", headers=headers)).status_code == 403


# --- фильтры и сортировка ---------------------------------------------------------------------


async def test_filters_find_overdue_and_narrow_list(client, login_as) -> None:
    """История 43 и проверочный сценарий 5: фильтр по подразделению, категории, статусу и сроку."""
    owner = await login_as("owner")
    assert await numbers(client, owner, due="overdue") == ["A-001", "A-007", "A-011"]
    assert await numbers(client, owner, status=["rejected", "closed"]) == ["A-017", "A-018"]
    assert await numbers(client, owner, department_id=1) == ["A-001", "A-002", "A-020"]
    assert await numbers(client, owner, category_id=4) == ["A-004", "A-016"]
    assert await numbers(client, owner, type="praise") == ["A-018"]
    assert await numbers(client, owner, due="no_deadline") == ["A-018"]
    assert await numbers(client, owner, q="спецификац") == ["A-003", "A-013"]


async def test_queue_sorted_by_due_with_pagination(client, login_as) -> None:
    """История 26: очередь по сроку, самое срочное первым."""
    owner = await login_as("owner")
    response = await client.get(
        "/api/v1/appeals", headers=owner, params={"status": ["new"], "sort": "due_asc", "page_size": 2}
    )
    body = response.json()
    assert body["total"] == 5 and len(body["items"]) == 2
    dues = [item["first_response_due_at"] for item in body["items"]]
    assert dues == sorted(dues)
    assert body["items"][0]["due_state"] == "overdue"


# --- карточка и история -----------------------------------------------------------------------


async def test_card_shows_deadline_relations_and_actions(client, login_as) -> None:
    """Истории 9, 27: ответственный видит срок и что можно сделать."""
    card = (await client.get("/api/v1/appeals/1", headers=await login_as("head_procurement"))).json()
    assert card["due_state"] == "overdue" and card["escalation_level"] >= 1
    assert set(card["viewer_relations"]) == {"assignee", "department_head"}
    assert {"take", "reassign", "merge", "publish_discussion"} <= set(card["allowed_actions"])

    admin = (await client.get("/api/v1/appeals/1", headers=await login_as("admin"))).json()
    assert admin["allowed_actions"] == ["reassign"], "администратор не меняет статус и не пишет в переписку"


async def test_rejected_and_implemented_show_reason_and_result(client, login_as) -> None:
    """Истории 14, 15."""
    rejected = (await client.get("/api/v1/appeals/17", headers=await login_as("employee_office"))).json()
    assert rejected["rejection_reason"].startswith("Сейчас нет подходящего помещения")
    implemented = (await client.get("/api/v1/appeals/4", headers=await login_as("employee_procurement"))).json()
    assert implemented["result"] == "Запланирован пробный обучающий семинар."


async def test_history_records_every_change_with_author_and_time(client, login_as, tmp_path, app) -> None:
    """История 11."""
    app.state.settings.attachments_dir = str(tmp_path)
    headers = await login_as("employee_sales")
    appeal = (await client.post("/api/v1/appeals", headers=headers, json=FORM)).json()
    await client.post(
        f"/api/v1/appeals/{appeal['id']}/attachments", headers=headers, files={"file": ("скан.pdf", b"%PDF-1", "application/pdf")}
    )
    history = (await client.get(f"/api/v1/appeals/{appeal['id']}/history", headers=headers)).json()
    assert [e["kind"] for e in history] == ["created", "assigned", "deadline_set", "attachment_added"]
    assert all(e["created_at"] for e in history)
    assert [e["actor"] and e["actor"]["full_name"] for e in history] == ["Сергей Ким", None, None, "Сергей Ким"]

    seeded = (await client.get("/api/v1/appeals/17/history", headers=await login_as("owner"))).json()
    assert [e["kind"] for e in seeded][-1] == "status_changed"
    assert seeded[-1]["new_value"] == "rejected"


# --- вложения ----------------------------------------------------------------------------------


async def test_attachments_are_served_only_to_those_who_see_the_appeal(app, client, login_as, tmp_path) -> None:
    """История 7."""
    app.state.settings.attachments_dir = str(tmp_path)
    author = await login_as("employee_procurement")
    uploaded = await client.post(
        "/api/v1/appeals/1/attachments", headers=author, files={"file": ("пример.txt", "заявка без параметров".encode(), "text/plain")}
    )
    assert uploaded.status_code == 201, uploaded.text
    attachment = uploaded.json()
    assert attachment["download_url"] == f"/api/v1/attachments/{attachment['id']}"

    own = await client.get(attachment["download_url"], headers=author)
    assert own.status_code == 200 and own.content == "заявка без параметров".encode()
    assert (await client.get(attachment["download_url"], headers=await login_as("owner"))).status_code == 200
    assert (await client.get(attachment["download_url"], headers=await login_as("employee_sales"))).status_code == 403

    card = (await client.get("/api/v1/appeals/1", headers=author)).json()
    assert [a["filename"] for a in card["attachments"]] == ["пример.txt"]


async def test_attachment_rules(app, client, login_as, tmp_path) -> None:
    app.state.settings.attachments_dir = str(tmp_path)
    app.state.settings.attachment_max_bytes = 10
    author = await login_as("employee_procurement")
    too_big = await client.post("/api/v1/appeals/1/attachments", headers=author, files={"file": ("big.bin", b"x" * 11)})
    assert (too_big.status_code, too_big.json()["error"]["code"]) == (413, "file_too_large")
    assert list(tmp_path.rglob("*.*")) == [] and not any(p.is_file() for p in tmp_path.rglob("*"))

    admin = await client.post("/api/v1/appeals/1/attachments", headers=await login_as("admin"), files={"file": ("a", b"1")})
    assert admin.status_code == 403
    closed = await client.post("/api/v1/appeals/4/attachments", headers=author, files={"file": ("a", b"1")})
    assert closed.status_code == 403, "к реализованному обращению файлы не прикладываются"


# --- справочники ------------------------------------------------------------------------------


async def test_dictionaries_for_form(client, login_as) -> None:
    headers = await login_as("employee_sales")
    categories = (await client.get("/api/v1/categories", headers=headers)).json()
    assert len(categories) == 18 and categories[0]["responsible"]["full_name"] == "Марат Сейткали"
    departments = (await client.get("/api/v1/departments", headers=headers)).json()
    assert len(departments) == 8 and all(d["head"] for d in departments)

    users = (await client.get("/api/v1/users", headers=headers, params={"department_id": 1})).json()
    assert {u["full_name"] for u in users} == {"Марат Сейткали", "Айгерим Нурланова"}
    assert all(u["telegram_id"] is None for u in users), "чужой Telegram ID скрыт"
    admin_view = (await client.get("/api/v1/users", headers=await login_as("admin"), params={"department_id": 1})).json()
    assert all(u["telegram_id"] for u in admin_view)


# --- правки по ревью ---------------------------------------------------------------------------------


async def test_participant_search_does_not_match_hidden_text(app: FastAPI, client, login_as, clock) -> None:
    """Участник повтора находит основное обращение по номеру и сути, но не по скрытому тексту."""
    async with app.state.sessionmaker() as session, session.begin():
        session.add(AppealParticipant(appeal_id=3, user_id=8, added_at=clock.now()))
    participant = await login_as("employee_sales")
    assert "A-003" not in await numbers(client, participant, q="спецификации"), "слово только в тексте A-003"
    assert "A-003" in await numbers(client, participant, q="обозначения")
    assert "A-003" in await numbers(client, participant, q="A-003")
    assert "A-003" in await numbers(client, await login_as("owner"), q="спецификации")


@pytest.mark.parametrize("who", ["head_design", "owner"])
async def test_head_and_owner_can_attach_files(app, client, login_as, tmp_path, who) -> None:
    """A-003: ответственный — Алия Сапарова, руководитель подразделения — Нурлан Беков."""
    app.state.settings.attachments_dir = str(tmp_path)
    response = await client.post("/api/v1/appeals/3/attachments", headers=await login_as(who), files={"file": ("план.pdf", b"%PDF")})
    assert response.status_code == 201, response.text
    card = (await client.get("/api/v1/appeals/3", headers=await login_as(who))).json()
    assert "upload_attachment" in card["allowed_actions"]


async def test_head_zone_follows_department_head_not_role(app, client, login_as) -> None:
    """Зона руководителя — подразделения, где он записан руководителем (Department.head_id)."""
    async with app.state.sessionmaker() as session, session.begin():
        await session.execute(update(Department).where(Department.id == 4).values(head_id=7))  # Проектирование -> Тимур Абенов

    new_head = await login_as("head_sales")
    assert "A-003" in await numbers(client, new_head)
    assert "A-003" in await numbers(client, new_head, scope="department")

    former = await login_as("head_design")
    assert await numbers(client, former) == ["A-014"], "осталось только то, где он ответственный"
    assert (await client.get("/api/v1/appeals", headers=former, params={"scope": "department"})).status_code == 403
    me = (await client.get("/api/v1/me", headers=former)).json()
    assert me["permissions"]["can_view_department"] is False and me["permissions"]["analytics_scope"] == "none"
