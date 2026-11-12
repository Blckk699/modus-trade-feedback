"""Поиск и склейка повторов (B-10). Истории 19, 34–37."""

from __future__ import annotations

import json

import httpx
import pytest

from app.adapters.claude import DuplicateMatch

# Категория 1 «Межотдельное взаимодействие» закреплена за руководителем закупок, как и A-001 и A-002.
FORM = {"type": "problem", "category_id": 1, "priority": "medium", "text": "Секретный текст автора о сроках согласования."}
HEAD = "head_procurement"
A_001, A_002, A_003, A_004 = 1, 2, 3, 4  # A-003 «В работе», A-004 «Реализовано»
REASON = "Оба обращения о сроках согласования."


async def submit(client: httpx.AsyncClient, headers: dict, form: dict = FORM) -> dict:
    response = await client.post("/api/v1/appeals", headers=headers, json=form)
    assert response.status_code == 201
    return response.json()


async def submit_with_suggestions(client, login_as, time_machine, fake_claude, *similar: int, author: str = "employee_sales") -> dict:
    fake_claude.duplicates = [DuplicateMatch(id=str(i), reason=REASON) for i in similar]
    created = await submit(client, await login_as(author))
    await time_machine.run_due()
    return created


async def similar_of(client: httpx.AsyncClient, headers: dict, appeal_id: int) -> list[dict]:
    response = await client.get(f"/api/v1/appeals/{appeal_id}/similar", headers=headers)
    assert response.status_code == 200
    return response.json()


async def merge(client: httpx.AsyncClient, headers: dict, appeal_id: int, main: int) -> httpx.Response:
    return await client.post(f"/api/v1/appeals/{appeal_id}/merge", headers=headers, json={"main_appeal_id": main})


async def test_new_appeal_is_compared_with_open_and_suggestion_saved(client, login_as, time_machine, fake_claude) -> None:
    """История 34: подсказка с объяснением сходства."""
    created = await submit_with_suggestions(client, login_as, time_machine, fake_claude, A_001)
    call = fake_claude.calls_to("find_duplicates")[0]
    candidates = {c.id for c in call.args["candidates"]}
    assert str(A_001) in candidates and str(created["id"]) not in candidates
    rows = await similar_of(client, await login_as(HEAD), created["id"])
    assert [(r["similar_appeal"]["number"], r["explanation"], r["can_merge"]) for r in rows] == [("A-001", REASON, True)]


async def test_submission_survives_ai_outage(client, login_as, time_machine, fake_claude) -> None:
    """Подача через форму не зависит от AI-сервиса."""
    fake_claude.fail = True
    created = await submit(client, await login_as("employee_sales"))
    await time_machine.run_due()
    assert await similar_of(client, await login_as(HEAD), created["id"]) == []


async def test_suggestions_limited_to_viewer_zone(client, login_as, time_machine, fake_claude) -> None:
    """A-003 — чужое подразделение: руководитель закупок его не видит, собственник видит."""
    created = await submit_with_suggestions(client, login_as, time_machine, fake_claude, A_001, A_003)
    head = await similar_of(client, await login_as(HEAD), created["id"])
    assert [r["similar_appeal"]["id"] for r in head] == [A_001]
    owner = await similar_of(client, await login_as("owner"), created["id"])
    assert [r["similar_appeal"]["id"] for r in owner] == [A_001, A_003]


@pytest.mark.parametrize("who", ["employee_sales", "admin"])
async def test_author_and_admin_get_no_suggestions(client, login_as, time_machine, fake_claude, who) -> None:
    created = await submit_with_suggestions(client, login_as, time_machine, fake_claude, A_001)
    assert await similar_of(client, await login_as(who), created["id"]) == []


async def test_dismiss_removes_and_never_returns(client, login_as, time_machine, fake_claude) -> None:
    """История 36."""
    created = await submit_with_suggestions(client, login_as, time_machine, fake_claude, A_001)
    head = await login_as(HEAD)
    suggestion = (await similar_of(client, head, created["id"]))[0]
    url = f"/api/v1/duplicate-suggestions/{suggestion['id']}/dismiss"
    assert (await client.post(url, headers=await login_as("employee_sales"))).status_code == 403
    assert (await client.post(url, headers=head)).status_code == 204
    assert await similar_of(client, head, created["id"]) == []
    assert (await client.post("/api/v1/duplicate-suggestions/9999/dismiss", headers=head)).status_code == 404


async def test_merge_closes_duplicate_and_adds_author_as_participant(client, login_as, time_machine, fake_claude) -> None:
    """Истории 35, 37, 19."""
    created = await submit_with_suggestions(client, login_as, time_machine, fake_claude, A_001)
    head = await login_as(HEAD)
    before = (await client.get(f"/api/v1/appeals/{A_001}", headers=head)).json()["participants_count"]

    merged = await merge(client, head, created["id"], A_001)
    assert merged.status_code == 200
    assert (merged.json()["id"], merged.json()["participants_count"]) == (A_001, before + 1)

    duplicate = (await client.get(f"/api/v1/appeals/{created['id']}", headers=head)).json()
    assert (duplicate["status"], duplicate["closed_reason"], duplicate["merged_into"]["id"]) == ("closed", "merged", A_001)
    kinds = [e["kind"] for e in (await client.get(f"/api/v1/appeals/{created['id']}/history", headers=head)).json()]
    assert "merged" in kinds


async def test_participant_gets_main_statuses_but_no_foreign_text_or_name(client, login_as, time_machine, fake_claude) -> None:
    """Истории 19, 17: статусы основного приходят, чужой текст и имя закрыты."""
    created = await submit_with_suggestions(client, login_as, time_machine, fake_claude, A_001)
    head = await login_as(HEAD)
    participant = await login_as("employee_sales")
    await merge(client, head, created["id"], A_001)

    items = (await client.get("/api/v1/notifications", headers=participant)).json()["items"]
    assert "appeal_merged" in [n["kind"] for n in items]

    card = await client.get(f"/api/v1/appeals/{A_001}", headers=participant)
    body = card.json()
    assert (card.status_code, body["access"], body["text"], body["author"]) == (200, "participant", None, None)
    assert (await client.get(f"/api/v1/appeals/{A_001}/messages", headers=participant)).status_code == 403

    await client.post(f"/api/v1/appeals/{A_001}/take", headers=head, json={})
    kinds = [n["kind"] for n in (await client.get("/api/v1/notifications", headers=participant)).json()["items"]]
    assert "status_changed" in kinds


async def test_merge_rejected_outside_allowed_statuses(client, login_as) -> None:
    owner = await login_as("owner")

    def refusal(response) -> tuple:
        error = response.json().get("error", {})
        return response.status_code, error.get("code"), (error.get("details") or {}).get("reason")

    # Повтор уже в работе — его не присоединяют; основное завершено — к нему не присоединяют.
    assert refusal(await merge(client, owner, A_003, A_001)) == (409, "merge_not_allowed", "duplicate_status")
    assert refusal(await merge(client, owner, A_001, A_004)) == (409, "merge_not_allowed", "main_finished")
    assert refusal(await merge(client, owner, A_001, A_001)) == (409, "merge_not_allowed", "same_appeal")


async def test_duplicate_joins_main_that_is_in_progress_or_awaits_info(client, login_as) -> None:
    """B-25: по основному уже работают или ждут уточнения, а о том же пишут снова — повтор присоединяется."""
    owner = await login_as("owner")
    author = await login_as("employee_sales")
    card = (await client.get(f"/api/v1/appeals/{A_003}", headers=owner)).json()
    assert card["status"] == "in_progress"
    first = await submit(client, author, FORM)
    joined = await merge(client, owner, first["id"], A_003)
    assert (joined.status_code, joined.json()["id"], joined.json()["status"]) == (200, A_003, "in_progress")

    main = await submit(client, author, FORM)
    assert (await client.post(f"/api/v1/appeals/{main['id']}/take", headers=owner, json={})).status_code == 200
    asked = await client.post(f"/api/v1/appeals/{main['id']}/request-info", headers=owner, json={"question": "Какой склад?"})
    assert asked.json()["status"] == "awaiting_info"
    second = await submit(client, await login_as("employee_procurement"), FORM)
    joined = await merge(client, owner, second["id"], main["id"])
    assert (joined.status_code, joined.json()["status"]) == (200, "awaiting_info")
    assert joined.json()["participants_count"] > main["participants_count"]
    closed = (await client.get(f"/api/v1/appeals/{second['id']}", headers=owner)).json()
    assert (closed["status"], closed["closed_reason"]) == ("closed", "merged")


async def test_merge_requires_rights_on_both_appeals(client, login_as) -> None:
    """Истории 35, 44: администратор и руководитель чужой зоны склеить не могут."""
    assert (await merge(client, await login_as("admin"), A_001, A_002)).status_code == 403
    assert (await merge(client, await login_as("head_sales"), A_001, A_002)).status_code == 403
    assert (await merge(client, await login_as(HEAD), A_001, 9999)).status_code == 404
    assert (await merge(client, await login_as("head_procurement"), A_001, A_002)).status_code == 200


async def test_praise_cannot_be_merged(client, login_as) -> None:
    """Отзыв принимается одним действием, склейки у него нет."""
    praise = await submit(client, await login_as("employee_sales"), {**FORM, "type": "praise"})
    owner = await login_as("owner")
    assert "merge" not in (await client.get(f"/api/v1/appeals/{praise['id']}", headers=owner)).json()["allowed_actions"]
    for duplicate, main in ((praise["id"], A_001), (A_001, praise["id"])):
        response = await merge(client, owner, duplicate, main)
        assert (response.status_code, response.json()["error"]["code"]) == (409, "merge_not_allowed")


async def test_author_sees_only_the_number_of_similar_appeals(client, login_as, time_machine, fake_claude) -> None:
    """B-25 п.6: «Похожие уже рассматриваются: N» — без чужих номеров, текстов и имён."""
    created = await submit_with_suggestions(client, login_as, time_machine, fake_claude, A_001, A_002)
    author = await login_as("employee_sales")
    card = (await client.get(f"/api/v1/appeals/{created['id']}", headers=author)).json()
    assert created.get("similar_count", 0) == 0, "сразу после подачи подсказок ещё нет"
    assert card["similar_count"] == 2
    assert (await client.get(f"/api/v1/appeals/{created['id']}/similar", headers=author)).json() == []
    for foreign in ("A-001", "A-002", "Айгерим"):
        assert foreign not in json.dumps(card, ensure_ascii=False)

    # «Это другое» и завершение похожего уменьшают число.
    head = await login_as(HEAD)
    suggestions = (await client.get(f"/api/v1/appeals/{created['id']}/similar", headers=head)).json()
    dismissed = await client.post(f"/api/v1/duplicate-suggestions/{suggestions[0]['id']}/dismiss", headers=head)
    assert dismissed.status_code == 204
    assert (await client.get(f"/api/v1/appeals/{created['id']}", headers=author)).json()["similar_count"] == 1
