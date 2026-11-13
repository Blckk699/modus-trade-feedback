"""Сквозные сценарии на сид-данных через HTTP API: главная проверка перед сдачей.

Шесть проверочных сценариев из датасета организаторов и демо-сценарий из десяти шагов (SPEC.md).
Внешние сервисы подменены на границе адаптеров, всё остальное — настоящие маршруты и база.
"""

from __future__ import annotations

from datetime import timedelta

import pytest

from app.adapters.claude import AppealDraft, DuplicateMatch, MeetingDraft
from tests.support import bot_headers, telegram_id_of

API = "/api/v1"
FORM = {"type": "problem", "category_id": 1, "priority": "medium", "text": "В заявках не хватает назначения изделия."}
HEAD = "head_procurement"
HEAD_ID = 3
DEPUTY = "employee_procurement"
A_001, A_002, A_017, A_020 = 1, 2, 17, 20


@pytest.fixture(autouse=True)
def storage(app, tmp_path) -> None:
    app.state.settings.attachments_dir = str(tmp_path)


async def ok(response, status: int = 200) -> dict | list:
    assert response.status_code == status, response.text
    return response.json()


async def card(client, headers, appeal_id: int) -> dict:
    return await ok(await client.get(f"{API}/appeals/{appeal_id}", headers=headers))


async def act(client, headers, appeal_id: int, action: str, body: dict | None = None) -> dict:
    return await ok(await client.post(f"{API}/appeals/{appeal_id}/{action}", headers=headers, json=body or {}))


async def kinds(client, headers) -> list[str]:
    items = (await ok(await client.get(f"{API}/notifications?page_size=200", headers=headers)))["items"]
    return [n["kind"] for n in items]


async def listed(client, headers, **params) -> dict:
    return await ok(await client.get(f"{API}/appeals", headers=headers, params={"page_size": 200, **params}))


# ---------------------------------------------------- шесть проверочных сценариев организаторов


async def test_scenario_1_create_appeal_with_file(client, login_as) -> None:
    """Создать обращение: тип, категория, описание, тестовый файл."""
    author = await login_as("employee_sales")
    created = await ok(await client.post(f"{API}/appeals", headers=author, json=FORM), 201)
    assert (created["type"], created["category"]["id"], created["status"]) == ("problem", 1, "new")
    assert created["number"].startswith("A-")
    await ok(
        await client.post(
            f"{API}/appeals/{created['id']}/attachments", headers=author, files={"file": ("пример.txt", b"test", "text/plain")}
        ),
        201,
    )
    assert [a["filename"] for a in (await card(client, author, created["id"]))["attachments"]] == ["пример.txt"]


async def test_scenario_2_routing_with_deputy_and_admin_queue(client, login_as) -> None:
    """Ответственный по категории, альтернатива при отсутствии, очередь без ответственного."""
    author = await login_as("employee_sales")
    admin = await login_as("admin")
    first = await ok(await client.post(f"{API}/appeals", headers=author, json=FORM), 201)
    assert first["assignee"]["id"] == HEAD_ID and first["first_response_due_at"]

    await ok(await client.patch(f"{API}/admin/users/{HEAD_ID}", headers=admin, json={"is_absent": True}))
    second = await ok(await client.post(f"{API}/appeals", headers=author, json=FORM), 201)
    assert second["assignee"]["full_name"] == "Карина Шаймерденова"

    orphan = await ok(await client.post(f"{API}/appeals", headers=author, json={**FORM, "category_id": None}), 201)
    assert orphan["assignee"] is None
    assert orphan["id"] in [a["id"] for a in (await listed(client, admin, scope="unassigned"))["items"]]
    assigned = await act(client, admin, orphan["id"], "reassign", {"assignee_id": 13, "reason": "Вопрос про IT"})
    assert assigned["assignee"]["id"] == 13


async def test_scenario_3_status_clarification_and_history(client, login_as) -> None:
    """Смена статуса, уточнение, история комментариев."""
    head = await login_as(HEAD)
    author = await login_as(DEPUTY)
    assert (await act(client, head, A_001, "take", {"comment": "Смотрю"}))["status"] == "in_review"
    assert (await act(client, head, A_001, "request-info", {"question": "Какие поля нужны?"}))["status"] == "awaiting_info"
    await ok(await client.post(f"{API}/appeals/{A_001}/messages", headers=author, json={"text": "Назначение и параметры"}), 201)
    assert (await card(client, author, A_001))["status"] == "in_review"

    messages = await ok(await client.get(f"{API}/appeals/{A_001}/messages", headers=author))
    assert [m["text"] for m in messages] == ["Смотрю", "Какие поля нужны?", "Назначение и параметры"]
    history = [e["kind"] for e in await ok(await client.get(f"{API}/appeals/{A_001}/history", headers=head))]
    assert {"status_changed", "clarification_requested", "clarification_answered"} <= set(history)


async def test_scenario_4_author_sees_outcome_and_reasoned_rejection(client, login_as) -> None:
    """Автор видит состояние и итог, в том числе мотивированный отказ."""
    head = await login_as(HEAD)
    author = await login_as(DEPUTY)
    seeded = await card(client, await login_as("employee_office"), A_017)
    assert seeded["status"] == "rejected" and "помещения" in seeded["rejection_reason"]

    await ok(await client.post(f"{API}/appeals/{A_002}/reject", headers=head, json={"reason": ""}), 422)
    rejected = await act(client, head, A_002, "reject", {"reason": "Коммерческие сроки раскрывать нельзя"})
    assert rejected["status"] == "rejected"
    assert (await card(client, author, A_002))["rejection_reason"] == "Коммерческие сроки раскрывать нельзя"
    assert "status_changed" in await kinds(client, author)


async def test_scenario_5_filters_find_overdue(client, login_as, time_machine) -> None:
    """Фильтры по подразделению, категории, статусу и сроку, поиск просроченных."""
    owner = await login_as("owner")
    assert (await listed(client, owner))["total"] == 20
    assert 0 < (await listed(client, owner, department_id=1))["total"] < 20
    assert (await listed(client, owner, category_id=1))["total"] == 1
    assert all(a["status"] == "new" for a in (await listed(client, owner, status="new"))["items"])

    await time_machine.advance(days=14, step=timedelta(hours=6))
    overdue = await listed(client, owner, due="overdue")
    assert overdue["total"] > 0
    assert all(a["due_state"] == "overdue" for a in overdue["items"])


async def test_scenario_6_summary_metrics(client, login_as) -> None:
    """Сводка: количество по типам, доля закрытых, среднее время первого ответа."""
    body = await ok(await client.get(f"{API}/analytics/summary", headers=await login_as("owner")))
    assert sum(i["count"] for i in body["by_type"]) == body["total"] == 20
    assert body["closed_share"] == pytest.approx(body["closed_count"] / 20)
    assert body["avg_first_response_hours"] > 0


# ---------------------------------------------------- демо-сценарий из десяти шагов


async def test_demo_story(client, login_as, time_machine, fake_claude, fake_speech, fake_bitrix) -> None:
    owner = await login_as("owner")
    head = await login_as(HEAD)
    admin = await login_as("admin")
    procurement = await login_as(DEPUTY)
    sales = await login_as("employee_sales")
    bot_author = bot_headers(telegram_id_of("employee_sales"))

    # 1. Утренняя сводка собственника в боте и на экране.
    digest = await ok(await client.get(f"{API}/analytics/digest", headers=bot_headers(telegram_id_of("owner"))))
    assert digest["scope"] == "company" and digest["text"]
    assert (await ok(await client.get(f"{API}/analytics/summary", headers=owner)))["total"] == 20

    # 2. Сотрудник наговаривает голосовое боту и подтверждает черновик.
    fake_speech.text = "В заявках снова нет назначения изделия"
    fake_claude.draft = AppealDraft(
        type="problem", category="Межотдельное взаимодействие", priority="medium", summary="Нет назначения в заявках", proposed_solution=None
    )
    draft = await ok(
        await client.post(f"{API}/drafts/voice", headers=bot_author, files={"file": ("v.ogg", b"OggS", "audio/ogg")})
    )
    assert draft["summary"] == "Нет назначения в заявках"
    fake_claude.duplicates = [DuplicateMatch(id=str(A_001), reason="Тот же недостаток заявок")]
    voiced = await ok(
        await client.post(
            f"{API}/appeals",
            headers=bot_author,
            json={"type": "problem", "category_id": 1, "priority": "medium", "text": fake_speech.text, "source": "bot"},
        ),
        201,
    )
    await time_machine.run_due()

    # 3. Ответственный видит подсказку о повторе и склеивает обращения.
    similar = await ok(await client.get(f"{API}/appeals/{voiced['id']}/similar", headers=head))
    assert [(s["similar_appeal"]["id"], s["can_merge"]) for s in similar] == [(A_001, True)]
    main = await act(client, head, voiced["id"], "merge", {"main_appeal_id": A_001})
    assert main["participants_count"] == 2
    participant_view = await card(client, sales, A_001)
    assert (participant_view["access"], participant_view["text"]) == ("participant", None)

    # 4. Уточняющий вопрос из приложения, ответ автора в боте.
    await act(client, head, A_001, "take")
    await act(client, head, A_001, "request-info", {"question": "Какие поля нужны?"})
    await ok(
        await client.post(
            f"{API}/appeals/{A_001}/messages", headers=bot_headers(telegram_id_of(DEPUTY)), json={"text": "Назначение и параметры"}
        ),
        201,
    )
    assert (await card(client, head, A_001))["status"] == "in_review"
    assert "status_changed" in await kinds(client, sales)

    # 5. Вынос предложения на обсуждение, голосование.
    deadline = (time_machine.now + timedelta(days=3)).isoformat()
    published = await ok(
        await client.post(
            f"{API}/appeals/{A_020}/discussion", headers=head, json={"public_text": "Публиковать обзор улучшений?", "deadline": deadline}
        ),
        201,
    )
    assert published["author_display"] == "Отдел «Закупки»"
    url = f"{API}/discussions/{published['id']}"
    assert (await ok(await client.put(f"{url}/vote", headers=sales, json={"value": "for"})))["votes_for"] == 1
    assert (await ok(await client.post(f"{url}/name-consent", headers=procurement, json={"show_name": True})))["author_display"]
    closed = await ok(await client.post(f"{url}/close", headers=head, json={"outcome": "Большинство за"}))
    assert closed["status"] == "closed"

    # 6. Задача в Битрикс24, «Реализовано», запись в общей ленте.
    await act(client, head, A_020, "take")
    await act(client, head, A_020, "start-work", {"decision": "Делаем квартальный обзор"})
    bitrix = await client.post(f"{API}/appeals/{A_020}/bitrix-task", headers=head)
    assert bitrix.status_code in (200, 201), bitrix.text
    assert len(fake_bitrix.tasks) == 1
    await act(client, head, A_020, "implement", {"result": "Первый обзор выпущен", "public_result": "Выпускаем обзор раз в квартал"})
    feed = (await ok(await client.get(f"{API}/feed/implemented?page_size=200", headers=sales)))["items"]
    item = next(i for i in feed if i["appeal_id"] == A_020)
    assert (item["public_summary"], item["result"]) == ("Публиковать обзор улучшений?", "Выпускаем обзор раз в квартал")

    # 7. Мотивированный отказ на примере A-017.
    assert (await card(client, await login_as("employee_office"), A_017))["rejection_reason"]

    # 8. Просроченное обращение: напоминание, руководитель, блок «Зависло».
    urgent = await ok(await client.post(f"{API}/appeals", headers=sales, json={**FORM, "category_id": 3, "priority": "high"}), 201)
    responsible = urgent["assignee"]["id"]
    assert responsible
    await time_machine.advance(days=7, step=timedelta(hours=3))
    assert (await card(client, owner, urgent["id"]))["escalation_level"] == 3
    summary = await ok(await client.get(f"{API}/analytics/summary", headers=owner))
    assert urgent["id"] in [s["appeal"]["id"] for s in summary["stuck"]]
    assert "escalation_head" in await kinds(client, await login_as("head_design"))

    # 9. Запись совещания превращается в черновики с цитатами.
    fake_claude.meeting_drafts = [
        MeetingDraft(type="problem", category="Межотдельное взаимодействие", priority="low", summary="Задержка спецификаций", proposed_solution=None, quote="снова задержали")
    ]
    meeting = await ok(
        await client.post(f"{API}/meetings", headers=head, files={"file": ("m.mp3", b"audio", "audio/mpeg")}, data={"title": "Планёрка"}),
        202,
    )
    await time_machine.run_due()
    ready = await ok(await client.get(f"{API}/meetings/{meeting['id']}", headers=head))
    assert (ready["status"], ready["drafts"][0]["quote"]) == ("ready", "снова задержали")
    from_meeting = await ok(
        await client.post(f"{API}/meetings/{meeting['id']}/drafts/{ready['drafts'][0]['id']}/confirm", headers=head), 201
    )
    assert from_meeting["source"] == "meeting"

    # 10. Администратор меняет ответственного у категории и срок ответа.
    await ok(await client.patch(f"{API}/admin/categories/1", headers=admin, json={"responsible_id": 13}))
    await ok(await client.put(f"{API}/admin/deadline-rules", headers=admin, json=[{"priority": "medium", "business_days": 2}]))
    after = await ok(await client.post(f"{API}/appeals", headers=sales, json=FORM), 201)
    assert after["assignee"]["id"] == 13
