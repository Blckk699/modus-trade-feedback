"""Сборка ответов об обращениях: справочники загружаются один раз на запрос, без N+1."""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.schemas import CategoryRef, DepartmentRef, UserBrief
from app.appeals import policy
from app.appeals.schemas import (
    AppealListItem,
    AppealOut,
    AppealRef,
    AttachmentOut,
    BitrixTaskOut,
    DiscussionRef,
)
from app.domain.enums import AppealStatus, AppealType, DueState
from app.models import (
    Appeal,
    AppealParticipant,
    Attachment,
    BitrixTask,
    Category,
    Department,
    Discussion,
    Notification,
    User,
)


@dataclass
class Directory:
    """Подразделения, категории и пользователи — маленькие таблицы, грузим целиком."""

    departments: dict[int, Department]
    categories: dict[int, Category]
    users: dict[int, User]

    @classmethod
    async def load(cls, session: AsyncSession) -> Directory:
        departments = {d.id: d for d in (await session.execute(select(Department))).scalars()}
        categories = {c.id: c for c in (await session.execute(select(Category))).scalars()}
        users = {u.id: u for u in (await session.execute(select(User))).scalars()}
        return cls(departments, categories, users)

    def department_ref(self, department_id: int | None) -> DepartmentRef | None:
        d = self.departments.get(department_id) if department_id else None
        return DepartmentRef(id=d.id, name=d.name) if d else None

    def category_ref(self, category_id: int | None) -> CategoryRef | None:
        c = self.categories.get(category_id) if category_id else None
        return CategoryRef(id=c.id, name=c.name) if c else None

    def user_brief(self, user_id: int | None) -> UserBrief | None:
        u = self.users.get(user_id) if user_id else None
        if u is None:
            return None
        return UserBrief(id=u.id, full_name=u.full_name, role=u.role, department=self.department_ref(u.department_id))

    def appeal_department_id(self, appeal: Appeal) -> int | None:
        category = self.categories.get(appeal.category_id) if appeal.category_id else None
        return category.department_id if category else None


def due_state(appeal: Appeal, now: datetime) -> DueState:
    if appeal.first_response_at is not None:
        return DueState.ANSWERED
    if appeal.first_response_due_at is None or appeal.type == AppealType.PRAISE:
        return DueState.NO_DEADLINE
    if AppealStatus(appeal.status).is_final:
        return DueState.ANSWERED
    if appeal.first_response_due_at <= now:
        return DueState.OVERDUE
    if appeal.first_response_due_at - now < timedelta(days=1):
        return DueState.DUE_SOON
    return DueState.ON_TIME


def appeal_ref(appeal: Appeal) -> AppealRef:
    return AppealRef(id=appeal.id, number=appeal.number, summary=appeal.summary, status=appeal.status, type=appeal.type)


@dataclass
class Extras:
    """Связанные данные для набора обращений, загруженные пачкой."""

    participants_count: dict[int, int]
    my_participation: set[int]
    unread: set[int]
    merged_into: dict[int, Appeal]
    discussions: dict[int, Discussion]
    bitrix: dict[int, BitrixTask]
    # Подразделения, которыми руководит пользователь (Department.head_id).
    headed: set[int]

    @classmethod
    async def load(cls, session: AsyncSession, user: User, appeals: Iterable[Appeal]) -> Extras:
        appeals = list(appeals)
        ids = [a.id for a in appeals]
        headed = set((await session.execute(select(Department.id).where(Department.head_id == user.id))).scalars())
        if not ids:
            return cls({}, set(), set(), {}, {}, {}, headed)
        counts = dict(
            (
                await session.execute(
                    select(AppealParticipant.appeal_id, func.count())
                    .where(AppealParticipant.appeal_id.in_(ids))
                    .group_by(AppealParticipant.appeal_id)
                )
            ).all()
        )
        mine = set(
            (
                await session.execute(
                    select(AppealParticipant.appeal_id).where(
                        AppealParticipant.appeal_id.in_(ids), AppealParticipant.user_id == user.id
                    )
                )
            ).scalars()
        )
        unread = set(
            (
                await session.execute(
                    select(Notification.appeal_id).where(
                        Notification.user_id == user.id, Notification.read_at.is_(None), Notification.appeal_id.in_(ids)
                    )
                )
            ).scalars()
        )
        main_ids = {a.merged_into_id for a in appeals if a.merged_into_id}
        merged = {a.id: a for a in (await session.execute(select(Appeal).where(Appeal.id.in_(main_ids)))).scalars()}
        discussions = {
            d.appeal_id: d for d in (await session.execute(select(Discussion).where(Discussion.appeal_id.in_(ids)))).scalars()
        }
        bitrix = {
            b.appeal_id: b for b in (await session.execute(select(BitrixTask).where(BitrixTask.appeal_id.in_(ids)))).scalars()
        }
        return cls({k: v for k, v in counts.items()}, mine, unread, merged, discussions, bitrix, headed)


def facts(appeal: Appeal, directory: Directory, extras: Extras) -> policy.AppealFacts:
    return policy.AppealFacts(
        author_id=appeal.author_id,
        assignee_id=appeal.assignee_id,
        department_id=directory.appeal_department_id(appeal),
        status=AppealStatus(appeal.status),
        type=AppealType(appeal.type),
        is_participant=appeal.id in extras.my_participation,
        viewer_heads_department=directory.appeal_department_id(appeal) in extras.headed,
        has_discussion=appeal.id in extras.discussions,
        has_bitrix_task=appeal.id in extras.bitrix,
    )


def list_item(appeal: Appeal, user: User, directory: Directory, extras: Extras, now: datetime) -> AppealListItem:
    rel = policy.relations(user, facts(appeal, directory, extras))
    full = policy.full_access(rel)
    merged = extras.merged_into.get(appeal.merged_into_id) if appeal.merged_into_id else None
    return AppealListItem(
        id=appeal.id,
        number=appeal.number,
        type=appeal.type,
        category=directory.category_ref(appeal.category_id),
        department=directory.department_ref(directory.appeal_department_id(appeal)),
        priority=appeal.priority,
        status=appeal.status,
        summary=appeal.summary,
        author=directory.user_brief(appeal.author_id) if full else None,
        assignee=directory.user_brief(appeal.assignee_id),
        source=appeal.source,
        first_response_due_at=appeal.first_response_due_at,
        due_state=due_state(appeal, now),
        escalation_level=appeal.escalation_level,
        participants_count=1 + extras.participants_count.get(appeal.id, 0),
        merged_into=appeal_ref(merged) if merged else None,
        access="full" if full else "participant",
        has_unread=appeal.id in extras.unread,
        created_at=appeal.created_at,
        updated_at=appeal.updated_at,
    )


def attachment_out(attachment: Attachment, directory: Directory) -> AttachmentOut:
    return AttachmentOut(
        id=attachment.id,
        appeal_id=attachment.appeal_id,
        filename=attachment.filename,
        content_type=attachment.content_type,
        size_bytes=attachment.size_bytes,
        download_url=f"/api/v1/attachments/{attachment.id}",
        uploaded_by=directory.user_brief(attachment.uploaded_by_id),
        created_at=attachment.created_at,
    )


async def appeal_out(session: AsyncSession, appeal: Appeal, user: User, now: datetime) -> AppealOut:
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    item = list_item(appeal, user, directory, extras, now)
    f = facts(appeal, directory, extras)
    rel = policy.relations(user, f)
    full = item.access == "full"
    attachments: list[AttachmentOut] = []
    if full:
        rows = await session.execute(select(Attachment).where(Attachment.appeal_id == appeal.id).order_by(Attachment.id))
        attachments = [attachment_out(a, directory) for a in rows.scalars()]
    bitrix = extras.bitrix.get(appeal.id)
    discussion = extras.discussions.get(appeal.id)
    return AppealOut(
        **item.model_dump(),
        text=appeal.text if full else None,
        proposed_solution=appeal.proposed_solution if full else None,
        first_response_at=appeal.first_response_at,
        decision=appeal.decision,
        rejection_reason=appeal.rejection_reason,
        result=appeal.result,
        public_summary=appeal.public_summary,
        public_result=appeal.public_result,
        forwarded_from=appeal.forwarded_from if full else None,
        closed_reason=appeal.closed_reason,
        bitrix_task=BitrixTaskOut(task_id=bitrix.task_id, url=bitrix.url, created_at=bitrix.created_at) if bitrix else None,
        discussion=DiscussionRef(id=discussion.id, status=discussion.status) if discussion else None,
        attachments=attachments,
        viewer_relations=rel,
        allowed_actions=policy.allowed_actions(user, f),
    )
