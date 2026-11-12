"""Справочники (B-18) и покрытие контракта: каждая операция OpenAPI имеет маршрут в приложении."""

from __future__ import annotations

import contextlib
import re
from enum import StrEnum
from pathlib import Path

import httpx
import pytest
from fastapi import FastAPI
from starlette.routing import NoMatchFound

from app.domain.enums import AppealAction, AppealSource, AppealStatus, AppealType, Priority, Role

CONTRACT = Path(__file__).resolve().parents[2] / "contract" / "openapi.yaml"

# Операции незакрытых тикетов. Список только сокращается: смержили тикет — удалите его строки.
NOT_YET_IMPLEMENTED: set[tuple[str, str]] = set()


def _normalized(path: str) -> str:
    return re.sub(r"\{[^}]+\}", "{}", path)


def contract_operations() -> set[tuple[str, str]]:
    """Операции контракта. Отступы OpenAPI фиксированы, поэтому отдельный разборщик YAML не нужен."""
    operations: set[tuple[str, str]] = set()
    path: str | None = None
    for line in CONTRACT.read_text(encoding="utf-8").splitlines():
        if found := re.fullmatch(r"  (/api/v1/\S*):", line):
            path = _normalized(found[1])
        elif re.fullmatch(r"\S.*:.*", line):
            path = None
        elif path and (found := re.fullmatch(r"    (get|post|put|patch|delete):", line)):
            operations.add((found[1], path))
    return operations


def app_operations(app: FastAPI) -> set[tuple[str, str]]:
    operations = {(method, _normalized(path)) for path, item in app.openapi()["paths"].items() for method in item}
    # WebSocket в схему FastAPI не попадает; в контракте он описан как GET (запрос с Upgrade).
    with contextlib.suppress(NoMatchFound):
        operations.add(("get", _normalized(str(app.url_path_for("live_updates")))))
    return operations


def test_contract_parser_sees_the_contract() -> None:
    assert ("get", "/api/v1/dictionaries") in contract_operations()
    assert len(contract_operations()) > 50


def test_every_contract_operation_has_a_route(app: FastAPI) -> None:
    missing = contract_operations() - app_operations(app) - NOT_YET_IMPLEMENTED
    assert not missing, f"Операции контракта без маршрута: {sorted(missing)}"


async def dictionaries(client: httpx.AsyncClient) -> dict:
    response = await client.get("/api/v1/dictionaries")
    assert response.status_code == 200
    return response.json()


async def test_dictionaries_need_no_login(client) -> None:
    body = await dictionaries(client)
    assert set(body) == {"appeal_types", "priorities", "statuses", "roles", "sources", "actions", "due_filters", "timezone"}
    assert body["timezone"] == "+05:00"


@pytest.mark.parametrize(
    ("section", "enum"),
    [
        ("appeal_types", AppealType),
        ("priorities", Priority),
        ("statuses", AppealStatus),
        ("roles", Role),
        ("sources", AppealSource),
        ("actions", AppealAction),
    ],
)
async def test_codes_match_backend_enums(client, section: str, enum: type[StrEnum]) -> None:
    items = (await dictionaries(client))[section]
    assert {i["code"] for i in items} == {e.value for e in enum}
    assert all(i["label"] for i in items)


async def test_statuses_and_transitions_follow_the_lifecycle(client) -> None:
    body = await dictionaries(client)
    assert {s["code"] for s in body["statuses"] if s["is_final"]} == {"implemented", "rejected", "closed"}
    actions = {a["code"]: a for a in body["actions"]}
    assert (actions["take"]["from"], actions["take"]["to"]) == (["new"], "in_review")
    assert (actions["merge"]["from"], actions["merge"]["to"]) == (["new", "in_review"], "closed")
    assert actions["reassign"]["to"] is None
