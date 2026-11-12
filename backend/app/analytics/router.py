"""Сводка и аналитика (B-13, истории 52–58, 61; SPEC.md, «Сводка»).

Собственник видит компанию, руководитель — подразделения, где он записан руководителем.
Текст для бота пишет Claude по посчитанным фактам; если сервис недоступен, уходит готовый шаблон с теми же числами.
"""

from __future__ import annotations

import html
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, time, timedelta, tzinfo
from html import escape
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters.claude import ClaudeClient
from app.api.deps import ClaudeDep, ClockDep, CurrentUserDep, SessionDep, SettingsDep
from app.api.schemas import CategoryRef, DepartmentRef, UserBrief
from app.appeals import policy, service
from app.appeals.schemas import AppealRef
from app.appeals.views import Directory, appeal_ref
from app.clock import LocalDatetime
from app.config import Settings
from app.domain.business_days import add_business_days
from app.domain.enums import AppealStatus, AppealType, NotificationKind, Role
from app.errors import ExternalServiceError, Forbidden
from app.jobs.registry import JobContext, registry
from app.jobs.schedules import Every
from app.models import Appeal, AppealParticipant, Department, SystemSetting, User
from app.notifications import service as notify

router = APIRouter(tags=["analytics"])

DigestScope = Literal["company", "department"]
DueFilter = Literal["overdue", "due_today", "due_week", "no_deadline"]

DIGEST_LIST_LIMIT = 10
# Сервер мог лежать в назначенное время: «утреннюю» сводку не отправляем посреди дня.
DIGEST_SEND_WINDOW = timedelta(hours=1)
DIGEST_MAX_CHARS = 3500
MONTHS = ("января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря")


class CountByType(BaseModel):
    type: AppealType
    count: int


class CountByCategory(BaseModel):
    category: CategoryRef | None
    count: int


class CountByStatus(BaseModel):
    status: AppealStatus
    count: int


class StuckAppeal(BaseModel):
    appeal: AppealRef
    assignee: UserBrief | None
    days_overdue: int
    escalation_level: int


class RepeatedTopic(BaseModel):
    appeal: AppealRef
    participants_count: int


class AssigneeLoad(BaseModel):
    assignee: UserBrief
    open_count: int
    overdue_count: int
    avg_first_response_hours: float | None


class AnalyticsSummary(BaseModel):
    scope: DigestScope
    department: DepartmentRef | None
    generated_at: LocalDatetime
    total: int
    closed_count: int
    closed_share: float
    avg_first_response_hours: float | None
    by_type: list[CountByType]
    by_category: list[CountByCategory]
    by_status: list[CountByStatus]
    new_last_24h: list[AppealRef]
    stuck: list[StuckAppeal]
    closed_last_week: list[AppealRef]
    repeated_topics: list[RepeatedTopic]
    overdue: list[StuckAppeal]
    assignee_load: list[AssigneeLoad]
    unassigned_count: int


class Digest(BaseModel):
    scope: DigestScope
    department: DepartmentRef | None
    generated_at: LocalDatetime
    text: str


@dataclass(frozen=True)
class Filters:
    department_id: int | None = None
    category_id: int | None = None
    statuses: tuple[str, ...] = ()
    due: DueFilter | None = None


def days_overdue(due: datetime, now: datetime, tz: tzinfo) -> int:
    """Полные рабочие дни просрочки; только что истёкший срок — уже один день."""
    days = 0
    while add_business_days(due, days + 1, tz) <= now:
        days += 1
    return max(days, 1)


def _is_overdue(appeal: Appeal, now: datetime) -> bool:
    return (
        appeal.first_response_at is None
        and appeal.first_response_due_at is not None
        and appeal.first_response_due_at <= now
        and appeal.type != AppealType.PRAISE
        and not AppealStatus(appeal.status).is_final
    )


def _average_hours(appeals: list[Appeal]) -> float | None:
    spans = [(a.first_response_at - a.created_at).total_seconds() / 3600 for a in appeals if a.first_response_at is not None]
    return round(sum(spans) / len(spans), 1) if spans else None


async def _headed(session: AsyncSession, user: User) -> set[int]:
    return set((await session.execute(policy.headed_departments(user))).scalars())


async def build_summary(session: AsyncSession, user: User, filters: Filters, now: datetime, tz: tzinfo) -> AnalyticsSummary:
    headed = await _headed(session, user)
    if user.role == Role.OWNER:
        scope: DigestScope = "company"
    elif headed:
        scope = "department"
        if filters.department_id is not None and filters.department_id not in headed:
            raise Forbidden("Сводка доступна только по вашему подразделению")
    else:
        raise Forbidden("Сводка доступна руководителю и собственнику")

    query = service.list_query(
        user,
        scope="all" if scope == "company" else "department",
        statuses=list(filters.statuses),
        type=None,
        priority=None,
        category_id=filters.category_id,
        department_id=filters.department_id,
        due=filters.due,
        q=None,
        now=now,
        tz=tz,
        headed_ids=headed,
    )
    appeals = list((await session.scalars(query.order_by(Appeal.created_at.desc(), Appeal.id.desc()))).all())
    directory = await Directory.load(session)
    ids = [a.id for a in appeals]
    extra_participants = (
        dict(
            (
                await session.execute(
                    select(AppealParticipant.appeal_id, func.count())
                    .where(AppealParticipant.appeal_id.in_(ids))
                    .group_by(AppealParticipant.appeal_id)
                )
            ).all()
        )
        if ids
        else {}
    )
    # Присоединённые повторы считаем отдельно от фильтров выборки: они закрыты и могли в неё не попасть.
    merged_count = (
        dict(
            (
                await session.execute(
                    select(Appeal.merged_into_id, func.count()).where(Appeal.merged_into_id.in_(ids)).group_by(Appeal.merged_into_id)
                )
            ).all()
        )
        if ids
        else {}
    )

    def reports(appeal: Appeal) -> int:
        """Сколько раз об этом сообщили: основное обращение плюс присоединённые повторы.

        Участников может быть меньше, чем повторов (один человек написал дважды), и больше
        (повтор пришёл со своими участниками) — берём большее.
        """
        return 1 + max(merged_count.get(appeal.id, 0), extra_participants.get(appeal.id, 0))

    def stuck_item(appeal: Appeal) -> StuckAppeal:
        return StuckAppeal(
            appeal=appeal_ref(appeal),
            assignee=directory.user_brief(appeal.assignee_id),
            days_overdue=days_overdue(appeal.first_response_due_at, now, tz),
            escalation_level=appeal.escalation_level,
        )

    overdue = sorted((a for a in appeals if _is_overdue(a, now)), key=lambda a: (a.first_response_due_at, a.id))
    closed = [a for a in appeals if AppealStatus(a.status).is_final]
    by_type = Counter(a.type for a in appeals)
    by_status = Counter(a.status for a in appeals)
    by_category = Counter(a.category_id for a in appeals)

    by_assignee: dict[int, list[Appeal]] = defaultdict(list)
    for appeal in appeals:
        if appeal.assignee_id is not None:
            by_assignee[appeal.assignee_id].append(appeal)
    load = [
        AssigneeLoad(
            assignee=directory.user_brief(assignee_id),
            open_count=sum(not AppealStatus(a.status).is_final for a in items),
            overdue_count=sum(_is_overdue(a, now) for a in items),
            avg_first_response_hours=_average_hours(items),
        )
        for assignee_id, items in by_assignee.items()
    ]
    load.sort(key=lambda item: (-item.open_count, -item.overdue_count, item.assignee.id))

    repeated = sorted((a for a in appeals if reports(a) > 1), key=lambda a: (-reports(a), a.id))
    department_id = filters.department_id
    if department_id is None and scope == "department" and len(headed) == 1:
        department_id = next(iter(headed))

    return AnalyticsSummary(
        scope=scope,
        department=directory.department_ref(department_id),
        generated_at=now,
        total=len(appeals),
        closed_count=len(closed),
        closed_share=round(len(closed) / len(appeals), 4) if appeals else 0.0,
        avg_first_response_hours=_average_hours(appeals),
        by_type=[CountByType(type=t, count=by_type.get(t, 0)) for t in AppealType],
        by_category=[
            CountByCategory(category=directory.category_ref(category_id), count=count)
            for category_id, count in sorted(by_category.items(), key=lambda kv: (-kv[1], kv[0] or 0))
        ],
        by_status=[CountByStatus(status=s, count=by_status.get(s, 0)) for s in AppealStatus],
        new_last_24h=[appeal_ref(a) for a in appeals if a.created_at >= now - timedelta(hours=24)],
        stuck=[stuck_item(a) for a in overdue if a.escalation_level >= 3],
        closed_last_week=[appeal_ref(a) for a in closed if a.updated_at >= now - timedelta(days=7)],
        repeated_topics=[RepeatedTopic(appeal=appeal_ref(a), participants_count=reports(a)) for a in repeated],
        overdue=[stuck_item(a) for a in overdue],
        assignee_load=load,
        unassigned_count=sum(a.assignee_id is None and not AppealStatus(a.status).is_final for a in appeals),
    )


def _limited(lines: list[str], total: int) -> list[str]:
    extra = total - len(lines)
    return [*lines, f"…и ещё {extra}"] if extra > 0 else lines


def digest_template(summary: AnalyticsSummary, tz: tzinfo) -> str:
    """Сводка в формате Telegram HTML. Всё пользовательское экранировано."""
    local = summary.generated_at.astimezone(tz)
    title = f"Сводка на {local.day} {MONTHS[local.month - 1]}"
    if summary.department:
        title += f" · {summary.department.name}"
    lines = [f"<b>{escape(title)}</b>", "", f"🆕 Новое за сутки: {len(summary.new_last_24h)}"]
    lines += _limited(
        [f"• {escape(a.number)} {escape(a.summary or '')}" for a in summary.new_last_24h[:DIGEST_LIST_LIMIT]], len(summary.new_last_24h)
    )
    lines += ["", f"⏰ Зависло: {len(summary.stuck)}"]
    lines += _limited(
        [
            f"• {escape(item.appeal.number)} — {escape(item.assignee.full_name) if item.assignee else 'без ответственного'}, "
            f"просрочено {item.days_overdue} дн."
            for item in summary.stuck[:DIGEST_LIST_LIMIT]
        ],
        len(summary.stuck),
    )
    lines += ["", f"✅ Закрыто за неделю: {len(summary.closed_last_week)}"]
    if summary.scope == "company":
        lines += ["", f"📥 В очереди нераспределённых: {summary.unassigned_count}"]
    if summary.repeated_topics:
        lines += ["", "🔁 Повторяется:"]
        lines += _limited(
            [
                f"• {escape(item.appeal.number)} — сообщили {item.participants_count} чел."
                for item in summary.repeated_topics[:DIGEST_LIST_LIMIT]
            ],
            len(summary.repeated_topics),
        )
    return "\n".join(lines)


async def digest_text(claude: ClaudeClient, summary: AnalyticsSummary, tz: tzinfo) -> str:
    template = digest_template(summary, tz)
    facts = html.unescape(re.sub(r"</?b>", "", template))
    try:
        written = await claude.write_digest(facts)
    except ExternalServiceError:
        return template
    return escape(written.strip()[:DIGEST_MAX_CHARS], quote=False)


@router.get("/analytics/summary", response_model=AnalyticsSummary, summary="Экран сводки и аналитики")
async def get_summary(
    user: CurrentUserDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
    department_id: int | None = None,
    category_id: int | None = None,
    status: Annotated[list[AppealStatus] | None, Query()] = None,
    due: DueFilter | None = None,
) -> AnalyticsSummary:
    filters = Filters(department_id, category_id, tuple(s.value for s in status or ()), due)
    return await build_summary(session, user, filters, clock.now(), settings.tz)


@router.get("/analytics/digest", response_model=Digest, summary="Текст сводки для бота")
async def get_digest(user: CurrentUserDep, session: SessionDep, clock: ClockDep, settings: SettingsDep, claude: ClaudeDep) -> Digest:
    summary = await build_summary(session, user, Filters(), clock.now(), settings.tz)
    return Digest(
        scope=summary.scope,
        department=summary.department,
        generated_at=summary.generated_at,
        text=await digest_text(claude, summary, settings.tz),
    )


LAST_SENT_KEY = "digest_last_sent"


async def configured_digest_time(session: AsyncSession, settings: Settings) -> time:
    """Время рассылки из настроек администратора; пока их не меняли — значение окружения."""
    row = await session.get(SystemSetting, "digest_time")
    return time.fromisoformat(row.value) if row else settings.digest_time


async def _recipients(session: AsyncSession) -> list[User]:
    heads = select(Department.head_id).where(Department.head_id.is_not(None))
    query = select(User).where((User.role == Role.OWNER) | User.id.in_(heads), User.is_disabled.is_(False)).order_by(User.id)
    return list((await session.scalars(query)).all())


@registry.periodic("digest.check", Every(minutes=5))
async def send_daily_digest(ctx: JobContext, payload: dict[str, Any]) -> None:
    """Раз в пять минут сверяет часы с настройкой: так новое время действует без перезапуска воркера."""
    now, tz = ctx.now(), ctx.settings.tz
    local = now.astimezone(tz)
    at = await configured_digest_time(ctx.session, ctx.settings)
    planned = datetime.combine(local.date(), at, tzinfo=tz)
    if not planned <= local < planned + DIGEST_SEND_WINDOW:
        return
    # В отметке есть и время: если администратор перенёс рассылку, она уйдёт в новое время.
    stamp = f"{local.date().isoformat()} {at.strftime('%H:%M')}"
    row = await ctx.session.get(SystemSetting, LAST_SENT_KEY, with_for_update=True)
    if row is not None and row.value == stamp:
        return
    if row is None:
        ctx.session.add(SystemSetting(key=LAST_SENT_KEY, value=stamp))
    else:
        row.value = stamp
    for user in await _recipients(ctx.session):
        summary = await build_summary(ctx.session, user, Filters(), now, tz)
        text = await digest_text(ctx.services.claude, summary, tz)
        notify.add(ctx.session, user.id, NotificationKind.DIGEST, text, now, path="/analytics")
