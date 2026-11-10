"""Витрина демо-данных: на экранах сразу есть что показать, в любой момент загрузки."""

from __future__ import annotations

from datetime import datetime

import pytest
from fastapi import FastAPI

from app.seed import reset_demo
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
    assert len(items) == 1
    discussion = items[0]
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
    assert created.json()["number"] == "A-023"


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
