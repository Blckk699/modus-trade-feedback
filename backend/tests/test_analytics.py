"""Сводка и аналитика (B-13). Истории 52–58, 61. Числа сверяются с сид-данными."""

from __future__ import annotations

from collections import Counter
from datetime import datetime, timedelta

import pytest

from app.domain.enums import AppealStatus
from app.seed import data
from tests.support import TZ

SUMMARY = "/api/v1/analytics/summary"
DIGEST = "/api/v1/analytics/digest"
HEAD = "head_procurement"
PROCUREMENT = {"Межотдельное взаимодействие", "Информационная прозрачность", "Прозрачность результатов"}


async def summary(client, headers, **params) -> dict:
    response = await client.get(SUMMARY, headers=headers, params=params)
    assert response.status_code == 200, response.text
    return response.json()


async def notifications_of(client, headers) -> list[dict]:
    return (await client.get("/api/v1/notifications?page_size=200", headers=headers)).json()["items"]


@pytest.mark.parametrize("who", ["employee_sales", "admin"])
async def test_others_get_403(client, login_as, who) -> None:
    headers = await login_as(who)
    assert (await client.get(SUMMARY, headers=headers)).status_code == 403
    assert (await client.get(DIGEST, headers=headers)).status_code == 403


async def test_company_numbers_match_seed(client, login_as) -> None:
    """История 56: числа сверены с декларативным описанием сида, а не с запросами приложения."""
    body = await summary(client, await login_as("owner"))
    statuses = Counter(a.status for a in data.APPEALS)
    final = sum(n for s, n in statuses.items() if AppealStatus(s).is_final)
    assert (body["scope"], body["department"], body["total"]) == ("company", None, 20)
    assert body["closed_count"] == final
    assert body["closed_share"] == pytest.approx(final / 20)
    assert {i["status"]: i["count"] for i in body["by_status"]} == {s.value: statuses.get(s, 0) for s in AppealStatus}
    assert sum(i["count"] for i in body["by_type"]) == 20
    assert sum(i["count"] for i in body["by_category"]) == 20
    assert body["avg_first_response_hours"] is not None


async def test_department_scope_for_head(client, login_as) -> None:
    """Истории 52, 53: руководитель видит только своё подразделение."""
    head = await login_as(HEAD)
    body = await summary(client, head)
    expected = sum(a.category in PROCUREMENT for a in data.APPEALS)
    assert (body["scope"], body["department"]["name"], body["total"]) == ("department", "Закупки", expected)
    assert {i["category"]["name"] for i in body["by_category"]} <= PROCUREMENT
    assert (await client.get(SUMMARY, headers=head, params={"department_id": 2})).status_code == 403


async def test_owner_filters(client, login_as) -> None:
    """История 61 и фильтры экрана."""
    owner = await login_as("owner")
    all_appeals = await summary(client, owner)
    procurement = await summary(client, owner, department_id=1)
    assert procurement["department"]["id"] == 1 and procurement["total"] < all_appeals["total"]
    assert (await summary(client, owner, category_id=1))["total"] == 1
    only_new = await summary(client, owner, status="new")
    assert {i["status"] for i in only_new["by_status"] if i["count"]} == {"new"}
    overdue = await summary(client, owner, due="overdue")
    assert overdue["total"] == len(all_appeals["overdue"])


async def test_stuck_shows_assignee_and_business_days(client, login_as, time_machine) -> None:
    """История 57: зависшее — шаг эскалации 3, с ответственным и рабочими днями просрочки."""
    owner = await login_as("owner")
    await time_machine.advance(days=14, step=timedelta(hours=6))
    body = await summary(client, owner)
    assert body["stuck"], "на сиде за две недели должны быть зависшие"
    for item in body["stuck"]:
        assert item["escalation_level"] == 3
        assert item["assignee"]["full_name"]
        assert item["days_overdue"] >= 2
    assert {i["appeal"]["id"] for i in body["stuck"]} <= {i["appeal"]["id"] for i in body["overdue"]}


async def test_repeated_topics_from_merges(client, login_as) -> None:
    """Истории 37, 58: счётчик строится по склеенным обращениям."""
    head = await login_as(HEAD)
    owner = await login_as("owner")
    created = await client.post(
        "/api/v1/appeals",
        headers=await login_as("employee_sales"),
        json={"type": "problem", "category_id": 1, "priority": "medium", "text": "Нет назначения оборудования."},
    )
    assert (await summary(client, owner))["repeated_topics"] == []
    await client.post(f"/api/v1/appeals/{created.json()['id']}/merge", headers=head, json={"main_appeal_id": 1})
    topics = (await summary(client, owner))["repeated_topics"]
    assert [(t["appeal"]["id"], t["participants_count"]) for t in topics] == [(1, 2)]


async def test_new_last_24h_and_load(client, login_as) -> None:
    owner = await login_as("owner")
    created = await client.post(
        "/api/v1/appeals",
        headers=await login_as("employee_sales"),
        json={"type": "problem", "category_id": 1, "priority": "medium", "text": "Новая проблема"},
    )
    body = await summary(client, owner)
    assert created.json()["id"] in [a["id"] for a in body["new_last_24h"]]
    load = body["assignee_load"]
    assert [i["open_count"] for i in load] == sorted((i["open_count"] for i in load), reverse=True)
    assert any(i["assignee"]["full_name"] == "Марат Сейткали" for i in load)


async def test_digest_uses_claude_text_escaped(client, login_as, fake_claude) -> None:
    fake_claude.digest_text = "Всё <хорошо> & спокойно"
    response = await client.get(DIGEST, headers=await login_as("owner"))
    body = response.json()
    assert (body["scope"], body["department"]) == ("company", None)
    assert body["text"] == "Всё &lt;хорошо&gt; &amp; спокойно"
    facts = fake_claude.calls_to("write_digest")[0].args["facts"]
    assert "Новое за сутки" in facts and "<b>" not in facts


async def test_digest_falls_back_to_template_without_ai(client, login_as, fake_claude) -> None:
    """Сводка работает при недоступном Claude и в том же формате HTML."""
    fake_claude.fail = True
    head = await login_as(HEAD)
    body = (await client.get(DIGEST, headers=head)).json()
    assert body["scope"] == "department"
    assert body["department"]["name"] == "Закупки"
    assert body["text"].startswith("<b>Сводка на ")
    for section in ("Новое за сутки", "Зависло", "Закрыто за неделю"):
        assert section in body["text"]


def next_morning(now: datetime, hour: int = 9, minute: int = 0) -> datetime:
    local = now.astimezone(TZ)
    moment = local.replace(hour=hour, minute=minute, second=0, microsecond=0)
    return moment if moment > local else moment + timedelta(days=1)


async def digests(client, headers) -> list[dict]:
    return [n for n in await notifications_of(client, headers) if n["kind"] == "digest"]


async def test_daily_digest_reaches_owner_and_heads_once(client, login_as, time_machine) -> None:
    """Истории 52, 54: ежедневно в 9:00, один раз в сутки, сотруднику — нет."""
    owner = await login_as("owner")
    head = await login_as(HEAD)
    employee = await login_as("employee_sales")
    await time_machine.travel_to(next_morning(time_machine.now) - timedelta(minutes=5))
    assert await digests(client, owner) == []

    await time_machine.advance(minutes=10, step=timedelta(minutes=1))
    assert len(await digests(client, owner)) == 1
    assert len(await digests(client, head)) == 1
    assert await digests(client, employee) == []
    await time_machine.advance(minutes=30, step=timedelta(minutes=1))
    assert len(await digests(client, owner)) == 1


async def test_digest_time_comes_from_admin_setting(client, login_as, time_machine) -> None:
    """Время берётся из настроек администратора без перезапуска."""
    owner = await login_as("owner")
    admin = await login_as("admin")
    assert (await client.patch("/api/v1/admin/settings", headers=admin, json={"digest_time": "18:30"})).status_code == 200
    await time_machine.travel_to(next_morning(time_machine.now) + timedelta(minutes=5))
    await time_machine.advance(minutes=2, step=timedelta(minutes=1))
    assert await digests(client, owner) == []
    await time_machine.travel_to(next_morning(time_machine.now, 18, 30) - timedelta(minutes=2))
    await time_machine.advance(minutes=10, step=timedelta(minutes=1))
    assert len(await digests(client, owner)) == 1


async def test_digest_not_sent_long_after_planned_time(client, login_as, time_machine) -> None:
    """Сервер простаивал утром: утреннюю сводку вечером не шлём."""
    owner = await login_as("owner")
    await time_machine.travel_to(next_morning(time_machine.now, 15, 0))
    await time_machine.advance(minutes=3, step=timedelta(minutes=1))
    assert await digests(client, owner) == []


async def test_unassigned_queue_is_visible_to_owner(client, login_as, fake_claude) -> None:
    """Нераспределённые не эскалируются, поэтому собственник видит их отдельным счётчиком."""
    owner = await login_as("owner")
    before = (await summary(client, owner))["unassigned_count"]
    created = await client.post(
        "/api/v1/appeals",
        headers=await login_as("employee_sales"),
        json={"type": "problem", "category_id": None, "priority": "medium", "text": "Непонятно, к кому относится"},
    )
    assert created.json()["assignee"] is None
    assert (await summary(client, owner))["unassigned_count"] == before + 1

    fake_claude.fail = True
    text = (await client.get(DIGEST, headers=owner)).json()["text"]
    assert f"В очереди нераспределённых: {before + 1}" in text
    head_text = (await client.get(DIGEST, headers=await login_as(HEAD))).json()["text"]
    assert "нераспределённых" not in head_text


async def test_saved_digest_time_beats_environment(client, app, login_as, time_machine) -> None:
    """B-19: время из system_settings (в сиде 09:00), а не DIGEST_TIME из окружения."""
    from datetime import time

    app.state.settings.digest_time = time(7, 0)
    owner = await login_as("owner")
    await time_machine.travel_to(next_morning(time_machine.now, 6, 58))
    await time_machine.advance(minutes=20, step=timedelta(minutes=1))
    assert await digests(client, owner) == []
    await time_machine.travel_to(next_morning(time_machine.now) - timedelta(minutes=2))
    await time_machine.advance(minutes=10, step=timedelta(minutes=1))
    assert len(await digests(client, owner)) == 1


async def test_repeats_from_the_same_author_are_counted(client, login_as) -> None:
    """B-25: автор основного обращения написал о том же ещё дважды — тема повторяется, хотя участников нет."""
    author = await login_as("employee_procurement")  # автор A-001
    head = await login_as(HEAD)
    owner = await login_as("owner")
    form = {"type": "problem", "category_id": 1, "priority": "medium", "text": "Нет назначения оборудования."}
    for _ in range(2):
        created = await client.post("/api/v1/appeals", headers=author, json=form)
        merged = await client.post(f"/api/v1/appeals/{created.json()['id']}/merge", headers=head, json={"main_appeal_id": 1})
        assert merged.status_code == 200, merged.text

    topics = (await summary(client, owner))["repeated_topics"]
    assert [(t["appeal"]["id"], t["participants_count"]) for t in topics] == [(1, 3)]
    # Фильтр по статусу прячет закрытые повторы из выборки, но не из счётчика.
    filtered = (await summary(client, owner, status="new"))["repeated_topics"]
    assert [(t["appeal"]["id"], t["participants_count"]) for t in filtered] == [(1, 3)]


async def test_departments_table_is_by_executor_not_author(client, login_as) -> None:
    """B-25 п.3: обращение сотрудника продаж в категорию закупок считается за закупками."""
    owner = await login_as("owner")
    before = {(d["department"] or {}).get("name"): d for d in (await summary(client, owner))["by_department"]}
    created = await client.post(
        "/api/v1/appeals",
        headers=await login_as("employee_sales"),
        json={"type": "problem", "category_id": 1, "priority": "medium", "text": "Нет назначения оборудования."},
    )
    assert created.status_code == 201
    body = await summary(client, owner)
    after = {(d["department"] or {}).get("name"): d for d in body["by_department"]}
    assert after["Закупки"]["total"] == before["Закупки"]["total"] + 1
    assert after["Закупки"]["open_count"] == before["Закупки"]["open_count"] + 1
    assert after.get("Продажи", {}).get("total") == before.get("Продажи", {}).get("total")
    assert sum(d["total"] for d in body["by_department"]) == body["total"]
    assert sum(d["overdue_count"] for d in body["by_department"]) == len(body["overdue"])
    overdue = [d["overdue_count"] for d in body["by_department"]]
    assert overdue == sorted(overdue, reverse=True), "сначала подразделения с просрочкой"

    # Руководитель видит только своё подразделение.
    mine = (await summary(client, await login_as(HEAD)))["by_department"]
    assert [d["department"]["name"] for d in mine] == ["Закупки"]


async def test_last_week_is_compared_with_previous(client, login_as, time_machine) -> None:
    """B-25 п.4: те же цифры за прошлые семь дней."""
    owner = await login_as("owner")
    author = await login_as("employee_sales")
    form = {"type": "problem", "category_id": 1, "priority": "medium", "text": "Нет назначения оборудования."}
    start = (await summary(client, owner))["last_week"]

    old = (await client.post("/api/v1/appeals", headers=author, json=form)).json()
    assert (await client.post(f"/api/v1/appeals/{old['id']}/take", headers=owner, json={})).status_code == 200
    await client.post(f"/api/v1/appeals/{old['id']}/reject", headers=owner, json={"reason": "Вне плана"})
    await time_machine.advance(days=8)
    fresh = (await client.post("/api/v1/appeals", headers=author, json=form)).json()
    assert fresh["status"] == "new"

    body = await summary(client, owner)
    last, previous = body["last_week"], body["previous_week"]
    assert last["to"] == body["generated_at"] and last["from"] == previous["to"]
    assert (datetime.fromisoformat(last["to"]) - datetime.fromisoformat(last["from"])) == timedelta(days=7)
    assert last["created_count"] == 1, "за последнюю неделю подано только свежее"
    # Обращение, поданное, взятое и отклонённое восемь дней назад, целиком ушло в прошлую неделю.
    assert previous["created_count"] >= 1 and previous["closed_count"] >= 1
    assert previous["avg_first_response_hours"] is not None
    assert last["closed_count"] == 0 and last["avg_first_response_hours"] is None
    assert start["created_count"] >= 1, "до сдвига времени свежие обращения сида были в текущей неделе"
    assert set(last) == {
        "from", "to", "created_count", "closed_count", "implemented_count", "overdue_count", "avg_first_response_hours"
    }
