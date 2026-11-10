"""Загрузка демо-данных. `reset_demo` стирает данные приложения и загружает компанию из датасета заново.

Даты обращений отсчитываются от момента загрузки (`now`), поэтому в любой день есть просроченные
обращения и обращения с временем первого ответа. Повторный запуск не создаёт дублей: перед загрузкой
таблицы очищаются, идентификаторы начинаются с 1.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, tzinfo

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.business_days import add_business_days, business_days_between, subtract_business_days
from app.domain.enums import AppealStatus, AppealType, ClosedReason, HistoryKind, Role
from app.models import (
    Appeal,
    Base,
    Category,
    DeadlineRule,
    Department,
    HistoryEvent,
    Message,
    PeriodicTask,
    SystemSetting,
    User,
)
from app.seed import data
from app.seed.accounts import Account

ROLE_LABELS = {
    Role.OWNER: "Собственник",
    Role.ADMIN: "Администратор",
    Role.HEAD: "Руководитель подразделения",
    Role.EMPLOYEE: "Сотрудник",
}

# Не трогаем расписание периодических задач: оно не демо-данные.
_KEEP_TABLES = {PeriodicTask.__tablename__}


@dataclass
class SeedReport:
    departments: int = 0
    users: int = 0
    categories: int = 0
    appeals: int = 0
    # Демо-пользователи, за которыми закреплён реальный Telegram: ключ -> имя.
    linked: dict[str, str] = field(default_factory=dict)
    # Роли, под которыми никто не сможет войти: ни у одного пользователя роли нет Telegram ID.
    roles_without_login: list[Role] = field(default_factory=list)

    def lines(self) -> list[str]:
        out = [
            f"Загружено: подразделений {self.departments}, сотрудников {self.users}, "
            f"категорий {self.categories}, обращений {self.appeals}.",
        ]
        if self.linked:
            out.append("Telegram закреплён за: " + ", ".join(f"{name} ({key})" for key, name in self.linked.items()) + ".")
        else:
            out.append("Файл аккаунтов не найден или пуст: ни за кем не закреплён Telegram.")
        for role in self.roles_without_login:
            out.append(f"ВНИМАНИЕ: под ролью «{ROLE_LABELS[role]}» никто не сможет войти — нет Telegram ID.")
        if self.roles_without_login:
            out.append("Dev-вход с выбором пользователя работает и без файла аккаунтов, если DEV_LOGIN_ENABLED=true.")
        return out


async def wipe(session: AsyncSession) -> None:
    tables = [t.name for t in Base.metadata.sorted_tables if t.name not in _KEEP_TABLES]
    quoted = ", ".join(f'"{name}"' for name in tables)
    await session.execute(text(f"TRUNCATE {quoted} RESTART IDENTITY CASCADE"))


async def is_empty(session: AsyncSession) -> bool:
    return (await session.scalar(select(func.count()).select_from(User))) == 0


async def reset_demo(session: AsyncSession, now: datetime, tz: tzinfo, accounts: dict[str, Account]) -> SeedReport:
    """Стирает данные приложения и загружает демо-компанию. Коммит — за вызывающим."""
    await wipe(session)
    return await load_demo(session, now, tz, accounts)


async def load_demo(session: AsyncSession, now: datetime, tz: tzinfo, accounts: dict[str, Account]) -> SeedReport:
    report = SeedReport()

    departments: dict[str, Department] = {}
    for name in data.DEPARTMENTS:
        departments[name] = Department(name=name)
        session.add(departments[name])
    await session.flush()

    users: dict[str, User] = {}
    for su in data.USERS:
        account = accounts.get(su.key)
        user = User(
            telegram_id=account.telegram_id if account else None,
            full_name=(account.full_name if account and account.full_name else su.full_name),
            position=su.position,
            role=su.role,
            department_id=departments[su.department].id if su.department else None,
            is_absent=False,
            is_disabled=False,
            seed_key=su.key,
            created_at=now - timedelta(days=60),
        )
        session.add(user)
        users[su.key] = user
        await session.flush()  # id по порядку списка
        if account:
            report.linked[su.key] = user.full_name
    for su in data.USERS:
        if su.is_head:
            departments[su.department].head_id = users[su.key].id

    categories: dict[str, Category] = {}
    for sc in data.CATEGORIES:
        category = Category(
            name=sc.name,
            department_id=departments[sc.department].id,
            responsible_id=users[sc.responsible].id if sc.responsible else None,
            deputy_id=users[sc.deputy].id if sc.deputy else None,
            is_active=True,
        )
        session.add(category)
        categories[sc.name] = category
    for priority, days in data.DEADLINE_RULES.items():
        session.add(DeadlineRule(priority=priority, business_days=days))
    for key, value in data.SETTINGS.items():
        session.add(SystemSetting(key=key, value=value))
    await session.flush()

    for sa in data.APPEALS:
        await _add_appeal(session, sa, now, tz, users, categories)

    report.departments = len(departments)
    report.users = len(users)
    report.categories = len(categories)
    report.appeals = len(data.APPEALS)
    with_login = {u.role for u in users.values() if u.telegram_id is not None}
    report.roles_without_login = [role for role in Role if role not in with_login]
    return report


async def _add_appeal(
    session: AsyncSession,
    sa: data.SeedAppeal,
    now: datetime,
    tz: tzinfo,
    users: dict[str, User],
    categories: dict[str, Category],
) -> None:
    category = categories[sa.category]
    author = users[sa.author]
    assignee_id = category.responsible_id
    created = subtract_business_days(now, sa.created_days_ago, tz) - timedelta(hours=sa.created_hours_earlier)
    is_praise = sa.type == AppealType.PRAISE

    due = None
    if not is_praise:
        due = add_business_days(created, data.DEADLINE_RULES[sa.priority], tz)
    first_response = created + timedelta(hours=sa.first_response_after_hours) if sa.first_response_after_hours else None
    if first_response and first_response >= now:
        raise ValueError(f"{sa.number}: первый ответ позже момента загрузки, поправьте сид")

    escalation = 0
    if due and first_response is None and due < now:
        escalation = min(3, 1 + business_days_between(due, now, tz))

    appeal = Appeal(
        number=sa.number,
        type=sa.type,
        category_id=category.id,
        priority=sa.priority,
        status=sa.status,
        author_id=author.id,
        assignee_id=assignee_id,
        text=sa.text,
        summary=sa.summary,
        proposed_solution=sa.proposed_solution,
        source=sa.source,
        first_response_due_at=due,
        first_response_at=first_response,
        escalation_level=escalation,
        decision=sa.decision,
        rejection_reason=sa.rejection_reason,
        result=sa.result,
        public_summary=sa.public_summary,
        closed_reason=ClosedReason.FEEDBACK_ACCEPTED if sa.status == AppealStatus.CLOSED else None,
        created_at=created,
        updated_at=created,
    )
    session.add(appeal)
    await session.flush()

    events: list[HistoryEvent] = []

    def event(at: datetime, kind: HistoryKind, actor: int | None, **kw: str | None) -> None:
        events.append(HistoryEvent(appeal_id=appeal.id, actor_id=actor, kind=kind, created_at=at, **kw))

    def status(at: datetime, old: AppealStatus, new: AppealStatus, comment: str | None = None) -> None:
        event(at, HistoryKind.STATUS_CHANGED, assignee_id, field="status", old_value=old, new_value=new, comment=comment)

    source_label = {"bot": "через бота", "form": "через форму"}[sa.source]
    event(created, HistoryKind.CREATED, author.id, comment=f"Подано {source_label}")
    assignee_name = next(u.full_name for u in users.values() if u.id == assignee_id)
    event(created, HistoryKind.ASSIGNED, None, field="assignee", new_value=assignee_name,
          comment=f"По правилу категории «{category.name}»")
    if due:
        event(created, HistoryKind.DEADLINE_SET, None, field="first_response_due_at", new_value=due.isoformat())

    last = created
    if first_response:
        last = first_response
        if is_praise:
            status(first_response, AppealStatus.NEW, AppealStatus.CLOSED, "Положительный отзыв принят")
        else:
            status(first_response, AppealStatus.NEW, AppealStatus.IN_REVIEW)

    if sa.question:
        asked = first_response + timedelta(minutes=10)
        session.add(Message(appeal_id=appeal.id, author_id=assignee_id, text=sa.question,
                            is_clarification_question=True, created_at=asked))
        event(asked, HistoryKind.CLARIFICATION_REQUESTED, assignee_id)  # текст вопроса — только в переписке
        status(asked, AppealStatus.IN_REVIEW, AppealStatus.AWAITING_INFO)
        last = asked

    if sa.decision:
        decided = first_response + timedelta(hours=2)
        status(decided, AppealStatus.IN_REVIEW, AppealStatus.IN_PROGRESS, sa.decision)
        last = decided

    if sa.status == AppealStatus.IMPLEMENTED:
        finished = add_business_days(created, sa.finished_after_days, tz)
        status(finished, AppealStatus.IN_PROGRESS, AppealStatus.IMPLEMENTED, sa.result)
        appeal.implemented_at = finished
        last = finished
    elif sa.status == AppealStatus.REJECTED:
        finished = add_business_days(created, sa.finished_after_days, tz)
        status(finished, AppealStatus.IN_REVIEW, AppealStatus.REJECTED, sa.rejection_reason)
        last = finished

    if last >= now:
        raise ValueError(f"{sa.number}: событие позже момента загрузки, поправьте сид")
    appeal.updated_at = last
    session.add_all(events)
