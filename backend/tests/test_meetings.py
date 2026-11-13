"""Режим «совещание» (B-12). Истории 48–51, 62. Расшифровка и извлечение подменены на границе адаптеров."""

from __future__ import annotations

from datetime import timedelta

import httpx
import pytest

from app.adapters.claude import MeetingDraft
from app.adapters.fakes import FakeClaude, FakeSpeech

HEAD = "head_procurement"
TRANSCRIPT = "Олжас: поставщик снова задержал спецификацию."
QUOTE = "поставщик снова задержал спецификацию"


def draft(summary: str = "Задержка спецификаций поставщиком", category: str | None = "Межотдельное взаимодействие") -> MeetingDraft:
    return MeetingDraft(type="problem", category=category, priority="high", summary=summary, proposed_solution=None, quote=QUOTE)


@pytest.fixture(autouse=True)
def storage(app, tmp_path) -> None:
    app.state.settings.attachments_dir = str(tmp_path)


@pytest.fixture
def adapters(fake_speech: FakeSpeech, fake_claude: FakeClaude) -> None:
    fake_speech.text = TRANSCRIPT
    fake_claude.meeting_drafts = [draft(), draft("Перейти на один мессенджер", None)]


async def upload(client: httpx.AsyncClient, headers: dict, content: bytes = b"audio") -> httpx.Response:
    return await client.post(
        "/api/v1/meetings", headers=headers, files={"file": ("plan.mp3", content, "audio/mpeg")}, data={"title": "Планёрка"}
    )


async def processed(client: httpx.AsyncClient, headers: dict, time_machine) -> dict:
    created = await upload(client, headers)
    assert created.status_code == 202
    await time_machine.run_due()
    return (await client.get(f"/api/v1/meetings/{created.json()['id']}", headers=headers)).json()


@pytest.mark.parametrize("who", ["employee_sales", "admin"])
async def test_only_head_and_owner_upload(client, login_as, who) -> None:
    headers = await login_as(who)
    assert (await upload(client, headers)).status_code == 403
    assert (await client.get("/api/v1/meetings", headers=headers)).status_code == 403


async def test_upload_returns_processing_without_blocking(client, login_as, fake_speech, adapters) -> None:
    """Обработка идёт в фоне: сразу `processing`, сервисы ещё не вызывались."""
    response = await upload(client, await login_as("owner"))
    body = response.json()
    assert (response.status_code, body["status"], body["transcript"], body["drafts"]) == (202, "processing", None, [])
    assert body["title"] == "Планёрка"
    assert fake_speech.calls == []


async def test_after_processing_transcript_and_drafts_with_quotes(client, login_as, time_machine, adapters) -> None:
    """Истории 48, 49."""
    meeting = await processed(client, await login_as(HEAD), time_machine)
    assert (meeting["status"], meeting["transcript"]) == ("ready", TRANSCRIPT)
    first = meeting["drafts"][0]
    assert (first["status"], first["type"], first["category"]["name"], first["quote"]) == ("pending", "problem", "Межотдельное взаимодействие", QUOTE)
    assert first["summary"] == "Задержка спецификаций поставщиком"
    assert meeting["drafts"][1]["category"] is None


async def test_nothing_created_without_confirmation(client, login_as, time_machine, adapters) -> None:
    owner = await login_as("owner")
    before = (await client.get("/api/v1/appeals?page_size=200", headers=owner)).json()["total"]
    await processed(client, await login_as(HEAD), time_machine)
    assert (await client.get("/api/v1/appeals?page_size=200", headers=owner)).json()["total"] == before


async def test_confirm_creates_routed_appeal_with_meeting_source(client, login_as, time_machine, adapters) -> None:
    """Истории 50, 51: автор по умолчанию — загрузивший, обычная маршрутизация."""
    head = await login_as(HEAD)
    meeting = await processed(client, head, time_machine)
    url = f"/api/v1/meetings/{meeting['id']}/drafts/{meeting['drafts'][0]['id']}"
    appeal = await client.post(f"{url}/confirm", headers=head)
    body = appeal.json()
    assert (appeal.status_code, body["source"], body["author"]["full_name"]) == (201, "meeting", "Олжас Мукашев")
    assert body["assignee"]["full_name"] == "Олжас Мукашев"
    assert body["first_response_due_at"] is not None
    assert QUOTE in body["text"]

    again = await client.post(f"{url}/confirm", headers=head)
    assert again.status_code == 409
    current = (await client.get(f"/api/v1/meetings/{meeting['id']}", headers=head)).json()["drafts"][0]
    assert (current["status"], current["appeal"]["id"]) == ("confirmed", body["id"])


async def test_author_can_be_any_employee_and_edits_apply(client, login_as, time_machine, adapters) -> None:
    """Истории 50, 51: автор получает статусы по своему вопросу."""
    head = await login_as(HEAD)
    meeting = await processed(client, head, time_machine)
    url = f"/api/v1/meetings/{meeting['id']}/drafts/{meeting['drafts'][0]['id']}"
    patched = await client.patch(url, headers=head, json={"author_id": 8, "priority": "low", "summary": "Правка сути"})
    assert (patched.json()["author"]["id"], patched.json()["priority"], patched.json()["summary"]) == (8, "low", "Правка сути")
    assert (await client.patch(url, headers=head, json={"author_id": 9999})).status_code == 422
    assert (await client.patch(url, headers=head, json={"category_id": 9999})).status_code == 422
    assert (await client.patch(url, headers=head, json={"summary": "   "})).status_code == 422

    appeal = (await client.post(f"{url}/confirm", headers=head, json={"text": "Итоговый текст"})).json()
    assert (appeal["author"]["id"], appeal["priority"], appeal["summary"], appeal["text"]) == (8, "low", "Правка сути", "Итоговый текст")
    mine = (await client.get("/api/v1/notifications", headers=await login_as("employee_sales"))).json()["items"]
    assert appeal["id"] in [n["appeal"]["id"] for n in mine if n["appeal"]]


async def test_discard_creates_nothing(client, login_as, time_machine, adapters) -> None:
    head = await login_as(HEAD)
    owner = await login_as("owner")
    meeting = await processed(client, head, time_machine)
    before = (await client.get("/api/v1/appeals?page_size=200", headers=owner)).json()["total"]
    url = f"/api/v1/meetings/{meeting['id']}/drafts/{meeting['drafts'][0]['id']}"
    discarded = await client.post(f"{url}/discard", headers=head)
    assert (discarded.status_code, discarded.json()["status"], discarded.json()["appeal"]) == (200, "discarded", None)
    assert (await client.post(f"{url}/confirm", headers=head)).status_code == 409
    assert (await client.patch(url, headers=head, json={"priority": "low"})).status_code == 409
    assert (await client.get("/api/v1/appeals?page_size=200", headers=owner)).json()["total"] == before


@pytest.mark.parametrize("who", ["owner", "head_sales", "employee_sales"])
async def test_meeting_is_private_to_uploader(client, login_as, time_machine, adapters, who) -> None:
    meeting = await processed(client, await login_as(HEAD), time_machine)
    headers = await login_as(who)
    base = f"/api/v1/meetings/{meeting['id']}"
    assert (await client.get(base, headers=headers)).status_code == 403
    assert (await client.post(f"{base}/drafts/{meeting['drafts'][0]['id']}/confirm", headers=headers)).status_code == 403


async def test_list_counts_drafts(client, login_as, time_machine, adapters) -> None:
    head = await login_as(HEAD)
    meeting = await processed(client, head, time_machine)
    await client.post(f"/api/v1/meetings/{meeting['id']}/drafts/{meeting['drafts'][0]['id']}/discard", headers=head)
    rows = (await client.get("/api/v1/meetings", headers=head)).json()
    assert [(m["id"], m["drafts_total"], m["drafts_pending"]) for m in rows] == [(meeting["id"], 2, 1)]
    assert (await client.get("/api/v1/meetings", headers=await login_as("owner"))).json() == []


async def test_empty_file_rejected(client, login_as) -> None:
    response = await upload(client, await login_as(HEAD), b"")
    assert (response.status_code, response.json()["error"]["code"]) == (422, "audio_empty")


async def test_service_outage_retries_then_marks_failed(client, login_as, time_machine, fake_speech, adapters) -> None:
    head = await login_as(HEAD)
    fake_speech.fail = True
    created = (await upload(client, head)).json()
    url = f"/api/v1/meetings/{created['id']}"

    await time_machine.run_due()
    assert (await client.get(url, headers=head)).json()["status"] == "processing"
    await time_machine.advance(timedelta(minutes=10), step=timedelta(minutes=1))
    failed = (await client.get(url, headers=head)).json()
    assert failed["status"] == "failed"
    assert failed["error"]
    assert failed["drafts"] == []


async def test_retry_succeeds_after_transient_failure(client, login_as, time_machine, fake_speech, adapters) -> None:
    head = await login_as(HEAD)
    fake_speech.fail = True
    created = (await upload(client, head)).json()
    await time_machine.run_due()
    fake_speech.fail = False
    await time_machine.advance(timedelta(minutes=3), step=timedelta(minutes=1))
    meeting = (await client.get(f"/api/v1/meetings/{created['id']}", headers=head)).json()
    assert (meeting["status"], len(meeting["drafts"])) == ("ready", 2)


async def test_unexpected_error_marks_failed_after_last_attempt(client, login_as, time_machine, fake_speech, adapters, monkeypatch) -> None:
    """Неожиданная ошибка не оставляет запись «обрабатывается» навсегда."""

    async def broken(*args, **kwargs):
        raise RuntimeError("неожиданный сбой")

    monkeypatch.setattr(fake_speech, "transcribe", broken)
    head = await login_as(HEAD)
    created = (await upload(client, head)).json()
    url = f"/api/v1/meetings/{created['id']}"

    await time_machine.run_due()
    assert (await client.get(url, headers=head)).json()["status"] == "processing"
    await time_machine.advance(timedelta(minutes=10), step=timedelta(minutes=1))
    body = (await client.get(url, headers=head)).json()
    assert (body["status"], body["drafts"]) == ("failed", [])
    assert "неожиданный" not in body["error"]
