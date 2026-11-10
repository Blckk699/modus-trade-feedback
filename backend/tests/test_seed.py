"""Сид демо-данных (B-02): компания из датасета, двадцать обращений, даты от момента загрузки."""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

import pytest
from fastapi import FastAPI
from sqlalchemy import func, select

from app.domain.enums import FINAL_STATUSES, Role
from app.models import Appeal, Category, DeadlineRule, Department, HistoryEvent, Message, SystemSetting, User
from app.seed import Account, AccountsFileError, data, load_accounts, reset_demo
from tests.support import TZ

KNOWN_KEYS = {u.key for u in data.USERS}

# Разные моменты загрузки: будни, пятница вечером, выходные, раннее утро понедельника.
LOAD_MOMENTS = [
    datetime(2026, 11, 9, 10, 0, tzinfo=TZ),
    datetime(2026, 11, 13, 19, 30, tzinfo=TZ),
    datetime(2026, 11, 14, 12, 0, tzinfo=TZ),
    datetime(2026, 11, 15, 23, 0, tzinfo=TZ),
    datetime(2026, 11, 16, 0, 30, tzinfo=TZ),
]


async def seed(app: FastAPI, now: datetime, accounts: dict[str, Account] | None = None):
    async with app.state.sessionmaker() as session, session.begin():
        return await reset_demo(session, now, TZ, accounts or {})


async def count(app: FastAPI, model) -> int:
    async with app.state.sessionmaker() as session:
        return await session.scalar(select(func.count()).select_from(model))


async def test_company_from_dataset(app: FastAPI) -> None:
    await seed(app, LOAD_MOMENTS[0])
    async with app.state.sessionmaker() as session:
        departments = (await session.execute(select(Department))).scalars().all()
        roles = set((await session.execute(select(User.role))).scalars())
        categories = (await session.execute(select(Category))).scalars().all()
        rules = dict((await session.execute(select(DeadlineRule.priority, DeadlineRule.business_days))).all())
        digest = await session.get(SystemSetting, "digest_time")

    assert sorted(d.name for d in departments) == sorted(data.DEPARTMENTS)
    assert all(d.head_id is not None for d in departments), "у каждого подразделения есть руководитель"
    assert roles == set(Role), "есть все четыре роли, включая собственника и администратора"
    assert len(categories) == 18 and all(c.responsible_id for c in categories)
    assert any(c.deputy_id for c in categories), "есть категории с заместителем для маршрутизации"
    assert rules == {"high": 1, "medium": 3, "low": 5}
    assert digest.value == "09:00"


async def test_twenty_appeals_keep_dataset_fields(app: FastAPI) -> None:
    await seed(app, LOAD_MOMENTS[0])
    async with app.state.sessionmaker() as session:
        rows = (
            await session.execute(
                select(Appeal, Category.name).join(Category, Appeal.category_id == Category.id).order_by(Appeal.id)
            )
        ).all()

    assert [a.number for a, _ in rows] == [f"A-{i:03d}" for i in range(1, 21)]
    for (appeal, category), expected in zip(rows, data.APPEALS, strict=True):
        assert (appeal.type, category, appeal.priority, appeal.status, appeal.text) == (
            expected.type, expected.category, expected.priority, expected.status, expected.text,
        ), appeal.number
        assert appeal.assignee_id is not None


@pytest.mark.parametrize("now", LOAD_MOMENTS, ids=lambda d: d.strftime("%a-%H%M"))
async def test_dates_are_relative_to_load_moment(app: FastAPI, now: datetime) -> None:
    await seed(app, now)
    async with app.state.sessionmaker() as session:
        appeals = (await session.execute(select(Appeal))).scalars().all()
        latest_event = await session.scalar(select(func.max(HistoryEvent.created_at)))

    overdue = [
        a for a in appeals
        if a.first_response_at is None and a.first_response_due_at and a.first_response_due_at < now
        and a.status not in FINAL_STATUSES
    ]
    answered = [a for a in appeals if a.first_response_at is not None]
    assert len(overdue) >= 3, [a.number for a in overdue]
    assert len(answered) >= 5
    assert all(a.escalation_level >= 1 for a in overdue)
    assert all(a.created_at <= now and a.updated_at <= now for a in appeals)
    assert latest_event <= now
    praise = next(a for a in appeals if a.type == "praise")
    assert praise.first_response_due_at is None and praise.closed_reason == "feedback_accepted"


async def test_status_details_from_dataset(app: FastAPI) -> None:
    await seed(app, LOAD_MOMENTS[0])
    async with app.state.sessionmaker() as session:
        by_number = {a.number: a for a in (await session.execute(select(Appeal))).scalars()}
        questions = (await session.execute(select(Message).where(Message.is_clarification_question))).scalars().all()

    assert by_number["A-017"].rejection_reason.startswith("Сейчас нет подходящего помещения")
    assert by_number["A-004"].result and by_number["A-004"].implemented_at
    assert by_number["A-003"].decision
    assert {m.appeal_id for m in questions} == {by_number["A-005"].id, by_number["A-013"].id}


async def test_reset_twice_creates_no_duplicates(app: FastAPI) -> None:
    await seed(app, LOAD_MOMENTS[0])
    first = {m.__name__: await count(app, m) for m in (User, Department, Category, Appeal, HistoryEvent, Message)}
    await seed(app, LOAD_MOMENTS[1])
    second = {m.__name__: await count(app, m) for m in (User, Department, Category, Appeal, HistoryEvent, Message)}
    assert first == second
    async with app.state.sessionmaker() as session:
        assert (await session.get(Appeal, 1)).number == "A-001", "идентификаторы снова с единицы"


async def test_accounts_link_roles_and_report_missing(app: FastAPI) -> None:
    accounts = {"owner": Account(111), "employee_procurement": Account(222, "Тестовый Сотрудник")}
    report = await seed(app, LOAD_MOMENTS[0], accounts)

    async with app.state.sessionmaker() as session:
        owner = (await session.execute(select(User).where(User.seed_key == "owner"))).scalar_one()
        employee = (await session.execute(select(User).where(User.seed_key == "employee_procurement"))).scalar_one()
    assert owner.telegram_id == 111
    assert (employee.telegram_id, employee.full_name) == (222, "Тестовый Сотрудник")
    assert report.roles_without_login == [Role.HEAD, Role.ADMIN]
    text = "\n".join(report.lines())
    assert "«Администратор» никто не сможет войти" in text
    assert "111" not in text and "222" not in text, "Telegram ID не печатаются"


async def test_without_accounts_file_every_role_is_reported(app: FastAPI) -> None:
    report = await seed(app, LOAD_MOMENTS[0])
    assert report.roles_without_login == list(Role)
    assert report.appeals == 20


def test_accounts_file_parsing(tmp_path: Path) -> None:
    assert load_accounts(tmp_path / "нет.json", KNOWN_KEYS) == {}

    path = tmp_path / "accounts.json"
    path.write_text(json.dumps({"owner": 5, "admin": {"telegram_id": 6, "full_name": "Анна"}}))
    assert load_accounts(path, KNOWN_KEYS) == {"owner": Account(5), "admin": Account(6, "Анна")}

    for bad in ({"chief": 1}, {"owner": "123"}, {"owner": 0}, {"owner": 7, "admin": 7}, ["owner"]):
        path.write_text(json.dumps(bad))
        with pytest.raises(AccountsFileError):
            load_accounts(path, KNOWN_KEYS)
