"""Удаление вложений и уменьшенные копии картинок.

A-001 (обращение 1): автор — Карина Шаймерденова (employee_procurement), подразделение «Закупки».
"""

from __future__ import annotations

import io

import httpx
import pytest
from PIL import Image

APPEAL = 1
AUTHOR = "employee_procurement"
HEAD = "head_procurement"


def png(size: tuple[int, int] = (1600, 900), *, mode: str = "RGB", color="navy") -> bytes:
    buffer = io.BytesIO()
    Image.new(mode, size, color).save(buffer, "PNG")
    return buffer.getvalue()


async def upload(client: httpx.AsyncClient, headers: dict, name: str, content: bytes, type: str, appeal: int = APPEAL) -> dict:
    response = await client.post(f"/api/v1/appeals/{appeal}/attachments", headers=headers, files={"file": (name, content, type)})
    assert response.status_code == 201, response.text
    return response.json()


async def card(client: httpx.AsyncClient, headers: dict, appeal: int = APPEAL) -> dict:
    return (await client.get(f"/api/v1/appeals/{appeal}", headers=headers)).json()


@pytest.fixture
def storage(app, tmp_path):
    app.state.settings.attachments_dir = str(tmp_path)
    return tmp_path


async def test_uploader_deletes_own_file(client, login_as, storage) -> None:
    author = await login_as(AUTHOR)
    attachment = await upload(client, author, "скан.pdf", b"%PDF-1", "application/pdf")
    assert (attachment["can_delete"], attachment["preview_url"]) == (True, None)
    assert [p for p in storage.rglob("*") if p.is_file()]

    deleted = await client.delete(f"/api/v1/attachments/{attachment['id']}", headers=author)
    assert (deleted.status_code, deleted.content) == (204, b"")
    assert (await card(client, author))["attachments"] == []
    assert (await client.get(attachment["download_url"], headers=author)).status_code == 404
    assert (await client.delete(f"/api/v1/attachments/{attachment['id']}", headers=author)).status_code == 404
    assert not [p for p in storage.rglob("*") if p.is_file()], "файл убран из хранилища"

    history = (await client.get(f"/api/v1/appeals/{APPEAL}/history", headers=author)).json()
    last = history[-1]
    assert (last["kind"], last["field"], last["old_value"], last["comment"]) == (
        "attachment_removed", "attachment", "скан.pdf", "Файл удалён"
    )


@pytest.mark.parametrize(("who", "allowed"), [(HEAD, True), ("owner", True), ("admin", False), ("employee_sales", False)])
async def test_who_can_delete_someone_elses_file(client, login_as, storage, who, allowed) -> None:
    """Руководитель подразделения обращения и собственник — да; администратор и посторонний — нет."""
    attachment = await upload(client, await login_as(AUTHOR), "скан.pdf", b"%PDF-1", "application/pdf")
    headers = await login_as(who)
    listed = await client.get(f"/api/v1/appeals/{APPEAL}/attachments", headers=headers)
    if listed.status_code == 200:
        assert listed.json()[0]["can_delete"] is allowed
    response = await client.delete(f"/api/v1/attachments/{attachment['id']}", headers=headers)
    assert response.status_code == (204 if allowed else 403)
    assert len((await card(client, await login_as(AUTHOR)))["attachments"]) == (0 if allowed else 1)


async def test_assignee_deletes_and_author_cannot_delete_assignees_file(client, login_as, storage) -> None:
    author = await login_as(AUTHOR)
    assignee_id = (await card(client, author))["assignee"]["id"]
    users = (await client.get("/api/v1/users", headers=await login_as("admin"))).json()
    assert next(u for u in users if u["id"] == assignee_id)["role"] != "admin"
    assignee = await login_as_id(client, login_as, assignee_id)

    mine = await upload(client, author, "от автора.txt", b"1", "text/plain")
    theirs = await upload(client, assignee, "от ответственного.txt", b"2", "text/plain")
    by_author = {a["id"]: a["can_delete"] for a in (await card(client, author))["attachments"]}
    assert by_author == {mine["id"]: True, theirs["id"]: False}
    assert (await client.delete(f"/api/v1/attachments/{theirs['id']}", headers=author)).status_code == 403
    assert (await client.delete(f"/api/v1/attachments/{mine['id']}", headers=assignee)).status_code == 204


async def login_as_id(client, login_as, user_id: int) -> dict:
    """Заголовки демо-пользователя по его id."""
    from app.seed import data

    for user in data.USERS:
        headers = await login_as(user.key)
        if (await client.get("/api/v1/me", headers=headers)).json()["id"] == user_id:
            return headers
    raise AssertionError(f"нет демо-пользователя {user_id}")


async def test_nothing_is_deleted_after_the_appeal_is_finished(client, login_as, storage) -> None:
    """A-002 отклоняет руководитель закупок; после этого файл не удаляет даже тот, кто его загрузил."""
    head = await login_as(HEAD)
    attachment = await upload(client, head, "скан.pdf", b"%PDF-1", "application/pdf", appeal=2)
    assert attachment["can_delete"] is True
    rejected = await client.post("/api/v1/appeals/2/reject", headers=head, json={"reason": "Вне плана"})
    assert rejected.json()["status"] == "rejected"
    assert (await card(client, head, 2))["attachments"][0]["can_delete"] is False
    for headers in (head, await login_as("owner")):
        assert (await client.delete(f"/api/v1/attachments/{attachment['id']}", headers=headers)).status_code == 403
    assert (await client.get(attachment["download_url"], headers=head)).status_code == 200


async def test_image_gets_a_small_preview(client, login_as, storage) -> None:
    author = await login_as(AUTHOR)
    original = png()
    attachment = await upload(client, author, "фото.png", original, "image/png")
    assert attachment["preview_url"] == f"/api/v1/attachments/{attachment['id']}?preview=1"

    preview = await client.get(attachment["preview_url"], headers=author)
    assert (preview.status_code, preview.headers["content-type"]) == (200, "image/jpeg")
    image = Image.open(io.BytesIO(preview.content))
    assert (image.format, image.size) == ("JPEG", (480, 270))
    again = await client.get(attachment["preview_url"], headers=author)
    assert again.content == preview.content, "вторая выдача — та же готовая копия"

    full = await client.get(attachment["download_url"], headers=author)
    assert full.content == original, "сам файл не меняется"
    assert (await client.get(attachment["preview_url"], headers=await login_as("employee_sales"))).status_code == 403
    assert (await client.get(attachment["preview_url"])).status_code == 401

    assert (await client.delete(f"/api/v1/attachments/{attachment['id']}", headers=author)).status_code == 204
    assert not [p for p in storage.rglob("*") if p.is_file()], "копия удаляется вместе с файлом"


async def test_transparent_image_is_put_on_white(client, login_as, storage) -> None:
    author = await login_as(AUTHOR)
    attachment = await upload(client, author, "логотип.png", png((200, 100), mode="RGBA", color=(0, 0, 0, 0)), "image/png")
    preview = await client.get(attachment["preview_url"], headers=author)
    image = Image.open(io.BytesIO(preview.content))
    assert image.size == (200, 100), "маленькая картинка не растягивается"
    assert image.convert("RGB").getpixel((10, 10))[0] > 240


async def test_no_preview_for_other_files_and_broken_images(client, login_as, storage) -> None:
    author = await login_as(AUTHOR)
    document = await upload(client, author, "скан.pdf", b"%PDF-1", "application/pdf")
    assert document["preview_url"] is None
    response = await client.get(f"{document['download_url']}?preview=1", headers=author)
    assert (response.status_code, response.json()["error"]["code"]) == (404, "not_found")

    broken = await upload(client, author, "битая.jpg", b"not an image at all", "image/jpeg")
    assert broken["preview_url"] is not None
    assert (await client.get(broken["preview_url"], headers=author)).status_code == 404
    assert (await client.get(broken["download_url"], headers=author)).status_code == 200


async def test_file_stays_on_disk_if_deletion_is_rolled_back(app, client, login_as, storage, clock) -> None:
    """Файл убирается только после фиксации: откат транзакции оставляет и запись, и файл."""
    from app.appeals import service
    from app.models import Appeal, Attachment, User

    author = await login_as(AUTHOR)
    attachment = await upload(client, author, "скан.pdf", b"%PDF-1", "application/pdf")
    async with app.state.sessionmaker() as session:
        row = await session.get(Attachment, attachment["id"])
        appeal = await session.get(Appeal, APPEAL)
        user = await session.get(User, row.uploaded_by_id)
        await service.delete_attachment(session, appeal, row, user, app.state.settings, clock.now())
        await session.rollback()
    assert (await client.get(attachment["download_url"], headers=author)).content == b"%PDF-1"
