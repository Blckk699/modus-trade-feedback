"""Общие обсуждения и лента реализованного (B-11). Истории 18, 20–22, 38, 47."""

from __future__ import annotations

from datetime import timedelta

import httpx
import pytest

# A-002: предложение сотрудника закупок, «На рассмотрении», руководитель закупок — ответственный.
APPEAL = 2
AUTHOR = "employee_procurement"
AUTHOR_NAME = "Карина Шаймерденова"
HEAD = "head_procurement"
SECRET_TEXT = "Приватная реплика только для автора"


async def publish(client: httpx.AsyncClient, headers: dict, time_machine, appeal: int = APPEAL) -> httpx.Response:
    return await client.post(
        f"/api/v1/appeals/{appeal}/discussion",
        headers=headers,
        json={"public_text": "Публиковать обзор улучшений?", "deadline": (time_machine.now + timedelta(days=3)).isoformat()},
    )


@pytest.fixture
async def discussion(client, login_as, time_machine) -> dict:
    response = await publish(client, await login_as(HEAD), time_machine)
    assert response.status_code == 201
    return response.json()


async def test_not_public_before_and_private_stays_private_after(client, login_as, time_machine) -> None:
    """Истории 17, 22: вынос открывает только публичную формулировку, не карточку и не переписку."""
    outsider = await login_as("employee_sales")
    head = await login_as(HEAD)
    await client.post(f"/api/v1/appeals/{APPEAL}/messages", headers=head, json={"text": SECRET_TEXT})

    assert (await client.get("/api/v1/discussions", headers=outsider)).json()["total"] == 0
    assert (await client.get(f"/api/v1/appeals/{APPEAL}", headers=outsider)).status_code == 403

    created = (await publish(client, head, time_machine)).json()

    listed = await client.get("/api/v1/discussions", headers=outsider)
    assert [d["id"] for d in listed.json()["items"]] == [created["id"]]
    assert SECRET_TEXT not in listed.text
    original = (await client.get(f"/api/v1/appeals/{APPEAL}", headers=head)).json()["text"]
    assert original not in listed.text
    assert (await client.get(f"/api/v1/appeals/{APPEAL}", headers=outsider)).status_code == 403
    assert (await client.get(f"/api/v1/appeals/{APPEAL}/messages", headers=outsider)).status_code == 403
    comments = await client.get(f"/api/v1/discussions/{created['id']}/comments", headers=outsider)
    assert comments.json() == []


@pytest.mark.parametrize("who", ["admin", "employee_sales", AUTHOR])
async def test_only_processors_publish(client, login_as, time_machine, who) -> None:
    assert (await publish(client, await login_as(who), time_machine)).status_code == 403


async def test_publish_rules(client, login_as, time_machine, discussion) -> None:
    head = await login_as(HEAD)
    assert (await publish(client, head, time_machine)).status_code == 409
    past = await client.post(
        "/api/v1/appeals/1/discussion",
        headers=head,
        json={"public_text": "Вопрос", "deadline": (time_machine.now - timedelta(hours=1)).isoformat()},
    )
    assert past.status_code == 422
    history = (await client.get(f"/api/v1/appeals/{APPEAL}/history", headers=head)).json()
    assert "discussion_published" in [e["kind"] for e in history]


async def test_name_shown_only_with_consent(client, login_as, discussion) -> None:
    """История 18: без согласия — подразделение, согласие даёт только автор."""
    url = f"/api/v1/discussions/{discussion['id']}"
    reader = await login_as("employee_sales")
    author = await login_as(AUTHOR)
    assert discussion["author_name_consent"] == "pending"
    assert discussion["author_display"] == "Отдел «Закупки»"

    assert (await client.post(f"{url}/name-consent", headers=reader, json={"show_name": True})).status_code == 403
    assert (await client.post(f"{url}/name-consent", headers=await login_as(HEAD), json={"show_name": True})).status_code == 403

    shown = await client.post(f"{url}/name-consent", headers=author, json={"show_name": True})
    assert (shown.json()["author_name_consent"], shown.json()["author_display"]) == ("shown", AUTHOR_NAME)
    assert (await client.get(url, headers=reader)).json()["author_display"] == AUTHOR_NAME

    hidden = await client.post(f"{url}/name-consent", headers=author, json={"show_name": False})
    assert (hidden.json()["author_name_consent"], hidden.json()["author_display"]) == ("hidden", "Отдел «Закупки»")
    assert (await client.get(url, headers=reader)).json()["can_set_name_consent"] is False
    assert (await client.get(url, headers=author)).json()["can_set_name_consent"] is True


async def test_author_receives_name_consent_request(client, login_as, discussion) -> None:
    items = (await client.get("/api/v1/notifications", headers=await login_as(AUTHOR))).json()["items"]
    assert "name_consent_request" in [n["kind"] for n in items]


async def test_one_vote_per_user_changeable_until_deadline(client, login_as, time_machine, discussion) -> None:
    """История 21."""
    url = f"/api/v1/discussions/{discussion['id']}/vote"
    voter = await login_as("employee_sales")
    other = await login_as("admin")

    first = (await client.put(url, headers=voter, json={"value": "for"})).json()
    assert (first["votes_for"], first["votes_against"], first["my_vote"]) == (1, 0, "for")
    again = (await client.put(url, headers=voter, json={"value": "against"})).json()
    assert (again["votes_for"], again["votes_against"], again["my_vote"]) == (0, 1, "against")
    assert (await client.put(url, headers=other, json={"value": "for"})).json()["votes_for"] == 1
    removed = (await client.delete(url, headers=voter)).json()
    assert (removed["votes_against"], removed["my_vote"]) == (0, None)

    await time_machine.advance(days=4)
    late = await client.put(url, headers=voter, json={"value": "for"})
    assert (late.status_code, late.json()["error"]["code"]) == (409, "voting_closed")
    assert (await client.delete(url, headers=other)).status_code == 409
    assert (await client.get(url.removesuffix("/vote"), headers=voter)).json()["can_vote"] is False


async def test_comments_are_public_and_close_with_voting(client, login_as, time_machine, discussion) -> None:
    """История 22."""
    url = f"/api/v1/discussions/{discussion['id']}/comments"
    writer = await login_as("employee_sales")
    posted = await client.post(url, headers=writer, json={"text": "  Поддерживаю  "})
    assert (posted.status_code, posted.json()["text"]) == (201, "Поддерживаю")
    assert (await client.post(url, headers=writer, json={"text": "   "})).status_code == 422
    assert [c["text"] for c in (await client.get(url, headers=await login_as("admin"))).json()] == ["Поддерживаю"]
    assert (await client.get(url.removesuffix("/comments"), headers=writer)).json()["comments_count"] == 1
    head = await login_as(HEAD)
    messages = (await client.get(f"/api/v1/appeals/{APPEAL}/messages", headers=head)).json()
    assert "Поддерживаю" not in [m["text"] for m in messages]

    await time_machine.advance(days=4)
    assert (await client.post(url, headers=writer, json={"text": "Поздно"})).status_code == 409


@pytest.mark.parametrize("who", ["admin", "employee_sales", AUTHOR, "head_sales"])
async def test_only_department_head_or_owner_closes(client, login_as, discussion, who) -> None:
    response = await client.post(
        f"/api/v1/discussions/{discussion['id']}/close", headers=await login_as(who), json={"outcome": "Итог"}
    )
    assert response.status_code == 403


async def test_head_records_outcome_in_discussion_and_appeal(client, login_as, discussion) -> None:
    """История 47."""
    url = f"/api/v1/discussions/{discussion['id']}"
    head = await login_as(HEAD)
    voter = await login_as("employee_sales")
    assert (await client.get(url, headers=head)).json()["can_close"] is True
    assert (await client.get(url, headers=voter)).json()["can_close"] is False
    assert (await client.post(f"{url}/close", headers=head, json={"outcome": "  "})).status_code == 422

    closed = (await client.post(f"{url}/close", headers=head, json={"outcome": "Большинство за"})).json()
    assert (closed["status"], closed["outcome"], closed["can_vote"], closed["can_close"]) == ("closed", "Большинство за", False, False)
    assert closed["closed_at"] is not None

    history = (await client.get(f"/api/v1/appeals/{APPEAL}/history", headers=head)).json()
    event = next(e for e in history if e["kind"] == "discussion_closed")
    assert event["comment"] == "Большинство за"
    assert (await client.post(f"{url}/close", headers=head, json={"outcome": "Ещё раз"})).status_code == 409
    assert (await client.put(f"{url}/vote", headers=voter, json={"value": "for"})).status_code == 409
    notifications = (await client.get("/api/v1/notifications", headers=await login_as(AUTHOR))).json()["items"]
    assert "discussion_closed" in [n["kind"] for n in notifications]


async def test_list_filters_by_status(client, login_as, discussion) -> None:
    head = await login_as(HEAD)
    await client.post(f"/api/v1/discussions/{discussion['id']}/close", headers=head, json={"outcome": "Итог"})
    assert (await client.get("/api/v1/discussions?status=open", headers=head)).json()["total"] == 0
    assert (await client.get("/api/v1/discussions?status=closed", headers=head)).json()["total"] == 1


async def implement(client: httpx.AsyncClient, head: dict, appeal: int, **public) -> None:
    await client.post(f"/api/v1/appeals/{appeal}/start-work", headers=head, json={"decision": "Делаем"})
    response = await client.post(
        f"/api/v1/appeals/{appeal}/implement", headers=head, json={"result": "Внутренний итог", **public}
    )
    assert response.json()["status"] == "implemented"


async def feed_item(client: httpx.AsyncClient, headers: dict, appeal: int) -> dict:
    items = (await client.get("/api/v1/feed/implemented?page_size=200", headers=headers)).json()["items"]
    return next(i for i in items if i["appeal_id"] == appeal)


async def test_feed_shows_public_wording_and_name_only_with_consent(client, login_as, discussion) -> None:
    """История 20."""
    head = await login_as(HEAD)
    reader = await login_as("employee_sales")
    before = (await client.get("/api/v1/feed/implemented?page_size=200", headers=reader)).json()["items"]
    assert APPEAL not in [i["appeal_id"] for i in before]

    await implement(client, head, APPEAL, public_result="Обзор выходит раз в квартал")
    item = await feed_item(client, reader, APPEAL)
    assert item["public_summary"] == "Публиковать обзор улучшений?"
    assert item["result"] == "Обзор выходит раз в квартал"
    assert item["author_display"] == "Отдел «Закупки»"
    assert item["discussion_id"] == discussion["id"]

    author = await login_as(AUTHOR)
    await client.post(f"/api/v1/discussions/{discussion['id']}/name-consent", headers=author, json={"show_name": True})
    assert (await feed_item(client, reader, APPEAL))["author_display"] == AUTHOR_NAME


async def test_feed_without_discussion_falls_back(client, login_as) -> None:
    head = await login_as(HEAD)
    await implement(client, head, APPEAL, public_summary="Что предложили")
    item = await feed_item(client, await login_as("admin"), APPEAL)
    assert (item["public_summary"], item["result"], item["discussion_id"]) == ("Что предложили", "Внутренний итог", None)
    assert item["author_display"] == "Отдел «Закупки»"
