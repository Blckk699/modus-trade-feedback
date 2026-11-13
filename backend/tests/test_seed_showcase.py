"""Витрина демо-данных: на экранах сразу есть что показать, в любой момент загрузки."""

from __future__ import annotations

from datetime import datetime

import pytest
from fastapi import FastAPI

from app.seed import reset_demo
from app.seed.showcase_more import APPEALS, FIRST_NUMBER
from tests.support import TZ, telegram_id_of

API = "/api/v1"
LOAD_MOMENTS = [
    datetime(2026, 11, 9, 10, 0, tzinfo=TZ),
    datetime(2026, 11, 14, 12, 0, tzinfo=TZ),
    datetime(2026, 11, 16, 0, 30, tzinfo=TZ),
]


async def seed(app: FastAPI, now: datetime) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        await reset_demo(session, now, TZ, {}, showcase=True)


@pytest.fixture
async def showcase(app: FastAPI, demo, clock) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        from app.seed import data
        from app.seed.accounts import Account

        accounts = {u.key: Account(telegram_id_of(u.key)) for u in data.USERS}
        await reset_demo(session, clock.now(), TZ, accounts, showcase=True)


@pytest.mark.parametrize("moment", LOAD_MOMENTS)
async def test_loads_at_any_moment(app: FastAPI, moment: datetime) -> None:
    await seed(app, moment)
    await seed(app, moment)  # повторная загрузка не падает и не плодит дубли


async def test_open_discussion_with_votes_and_comments(client, login_as, showcase) -> None:
    headers = await login_as("employee_sales")
    items = (await client.get(f"{API}/discussions", headers=headers)).json()["items"]
    assert sorted(i["status"] for i in items) == ["closed", "open"]
    discussion = next(i for i in items if i["status"] == "open")
    assert (discussion["status"], discussion["can_vote"], discussion["votes_for"], discussion["votes_against"]) == ("open", True, 4, 1)
    assert discussion["comments_count"] == 2
    assert discussion["appeal"]["number"] == "A-012"


async def test_feed_has_implemented_items(client, login_as, showcase) -> None:
    feed = (await client.get(f"{API}/feed/implemented", headers=await login_as("employee_sales"))).json()
    assert feed["total"] >= 2


async def test_merged_duplicates_counted_on_main(client, login_as, showcase) -> None:
    owner = await login_as("owner")
    main = (await client.get(f"{API}/appeals/3", headers=owner)).json()
    assert main["participants_count"] == 3
    duplicate = (await client.get(f"{API}/appeals/21", headers=owner)).json()
    assert (duplicate["status"], duplicate["closed_reason"], duplicate["merged_into"]["number"]) == ("closed", "merged", "A-003")
    participant = (await client.get(f"{API}/appeals/3", headers=await login_as("employee_procurement"))).json()
    assert (participant["access"], participant["text"]) == ("participant", None)


async def test_new_appeals_continue_numbering(client, login_as, showcase) -> None:
    created = await client.post(
        f"{API}/appeals",
        headers=await login_as("employee_sales"),
        json={"type": "problem", "category_id": 1, "priority": "medium", "text": "Новое"},
    )
    assert created.status_code == 201, created.text
    assert created.json()["number"] == f"A-{FIRST_NUMBER + len(APPEALS):03d}"


async def test_overdue_with_escalation_present(client, login_as, showcase) -> None:
    items = (await client.get(f"{API}/appeals", headers=await login_as("owner"), params={"due": "overdue", "page_size": 200})).json()["items"]
    assert items and any(a["escalation_level"] >= 1 for a in items)


async def test_meeting_ready_with_pending_drafts(client, login_as, showcase) -> None:
    head = await login_as("head_procurement")
    rows = (await client.get(f"{API}/meetings", headers=head)).json()
    assert [(m["status"], m["drafts_total"], m["drafts_pending"]) for m in rows] == [("ready", 3, 3)]
    meeting = (await client.get(f"{API}/meetings/{rows[0]['id']}", headers=head)).json()
    assert all(d["quote"] in meeting["transcript"] for d in meeting["drafts"])
    confirmed = await client.post(f"{API}/meetings/{rows[0]['id']}/drafts/{meeting['drafts'][0]['id']}/confirm", headers=head)
    assert (confirmed.status_code, confirmed.json()["source"]) == (201, "meeting")


async def test_second_part_shows_every_feature(client, login_as, showcase) -> None:
    """Вторая часть витрины: все статусы и подразделения, переписка, передачи, Битрикс24, закрытое обсуждение."""
    owner = await login_as("owner")
    items = (await client.get(f"{API}/appeals", headers=owner, params={"scope": "all", "page_size": 200})).json()["items"]
    extra = [i for i in items if int(i["number"][2:]) >= FIRST_NUMBER]
    assert len(extra) == len(APPEALS) >= 15
    assert {i["status"] for i in extra} == {"new", "in_review", "awaiting_info", "in_progress", "implemented", "rejected", "closed"}
    assert {i["type"] for i in extra} == {"problem", "suggestion", "praise"}
    assert len({i["department"]["name"] for i in extra}) == 8, "все подразделения"
    assert len({i["assignee"]["id"] for i in extra}) >= 6, "нагрузка распределена по ответственным"
    generated = (await client.get(f"{API}/analytics/summary", headers=owner)).json()["generated_at"]
    assert all(i["updated_at"] <= generated for i in extra), "события витрины не уходят в будущее"

    by_summary = {i["summary"]: i for i in extra}
    talk = by_summary["Договоры на поставку СКУД по три дня ждут визы юриста"]
    card = (await client.get(f"{API}/appeals/{talk['id']}", headers=owner)).json()
    assert card["bitrix_task"]["task_id"] == "1412" and card["decision"]
    messages = (await client.get(f"{API}/appeals/{talk['id']}/messages", headers=owner)).json()
    assert len(messages) >= 5 and len({m["author"]["id"] for m in messages}) == 2

    waiting = by_summary["Заявки от клиентов на выезд инженера теряются в общем чате"]
    asked = (await client.get(f"{API}/appeals/{waiting['id']}/messages", headers=owner)).json()
    assert asked[-1]["is_clarification_question"] is True and waiting["status"] == "awaiting_info"

    moved = by_summary["В каталоге нет аналогов снятых с производства камер"]
    kinds = [e["kind"] for e in (await client.get(f"{API}/appeals/{moved['id']}/history", headers=owner)).json()]
    assert "reassigned" in kinds and "bitrix_task_created" in kinds
    recategorized = by_summary["Счета на предоплату выставляются на следующий день"]
    history = (await client.get(f"{API}/appeals/{recategorized['id']}/history", headers=owner)).json()
    assert [(e["old_value"], e["new_value"]) for e in history if e["field"] == "category"] == [("Договорная работа", "Документооборот")]

    stuck = by_summary["Монтажники выезжают на объект без утверждённой схемы"]
    assert (stuck["due_state"], stuck["escalation_level"]) == ("overdue", 3)
    rejected = (await client.get(f"{API}/appeals/{by_summary['Нет доступа к закупочным ценам при подборе оборудования']['id']}", headers=owner)).json()
    assert rejected["rejection_reason"]

    closed = next(d for d in (await client.get(f"{API}/discussions", headers=owner)).json()["items"] if d["status"] == "closed")
    assert closed["outcome"] and (closed["votes_for"], closed["votes_against"]) == (6, 1) and closed["comments_count"] == 3

    summary = (await client.get(f"{API}/analytics/summary", headers=owner)).json()
    assert len([row for row in summary["assignee_load"] if row["open_count"] > 0]) >= 6
    assert len(summary["by_department"]) >= 8
    feed = (await client.get(f"{API}/feed/implemented", headers=await login_as("employee_sales"))).json()
    assert feed["total"] >= 5


@pytest.mark.parametrize("moment", LOAD_MOMENTS)
async def test_overdue_examples_stand_on_their_step_at_any_moment(app: FastAPI, moment: datetime) -> None:
    """В любой день сброса шаг эскалации в витрине совпадает с положенным: фоновая проверка ничего не сдвинет."""
    from sqlalchemy import select

    from app.appeals.escalation import due_level
    from app.models import Appeal

    await seed(app, moment)
    async with app.state.sessionmaker() as session:
        appeals = list(await session.scalars(select(Appeal).where(Appeal.number >= f"A-{FIRST_NUMBER:03d}")))
    escalated = [a for a in appeals if a.escalation_level]
    assert sorted(a.escalation_level for a in escalated) == [2, 3]
    for appeal in escalated:
        assert due_level(appeal.first_response_due_at, moment, TZ) == appeal.escalation_level, appeal.number
        assert appeal.created_at < moment and appeal.updated_at <= moment
