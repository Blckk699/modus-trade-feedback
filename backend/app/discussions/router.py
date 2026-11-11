"""Общие обсуждения и лента реализованного (B-11, истории 18, 20–22, 38, 47).

Обсуждение и лента видны всем, поэтому наружу идут только публичная формулировка, номер, тип и статус
обращения: текст и приватная переписка сюда не попадают. Имя автора — только с его согласия.
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Query
from pydantic import AwareDatetime, BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import ClockDep, CurrentUserDep, SessionDep
from app.api.schemas import CategoryRef, DepartmentRef, UserBrief
from app.appeals import policy, service
from app.appeals.history import record
from app.appeals.views import Directory, Extras, facts
from app.clock import LocalDatetime
from app.domain.enums import (
    AppealAction,
    AppealStatus,
    AppealType,
    DiscussionStatus,
    HistoryKind,
    NameConsent,
    Role,
    VoteValue,
)
from app.errors import Conflict, Forbidden, InvalidTransition, NotFound, ValidationFailed, VotingClosed
from app.models import Appeal, Department, Discussion, DiscussionComment, DiscussionVote, User
from app.notifications import service as notify

router = APIRouter(tags=["discussions"])

Required = Annotated[str, Field(min_length=1, max_length=20_000, pattern=r"\S")]
Page = Annotated[int, Query(ge=1)]
PageSize = Annotated[int, Query(ge=1, le=200)]


class DiscussionCreate(BaseModel):
    public_text: Required
    deadline: AwareDatetime


class VoteIn(BaseModel):
    value: VoteValue


class CommentIn(BaseModel):
    text: Required


class NameConsentIn(BaseModel):
    show_name: bool


class OutcomeIn(BaseModel):
    outcome: Required


class DiscussionAppeal(BaseModel):
    id: int
    number: str
    type: AppealType
    status: AppealStatus


class DiscussionOut(BaseModel):
    id: int
    appeal: DiscussionAppeal
    public_text: str
    deadline: LocalDatetime
    status: DiscussionStatus
    author_name_consent: NameConsent
    author_display: str
    department: DepartmentRef | None
    votes_for: int
    votes_against: int
    my_vote: VoteValue | None
    comments_count: int
    outcome: str | None
    created_by: UserBrief
    created_at: LocalDatetime
    closed_at: LocalDatetime | None
    can_vote: bool
    can_close: bool
    can_set_name_consent: bool


class DiscussionPage(BaseModel):
    items: list[DiscussionOut]
    total: int
    page: int
    page_size: int


class DiscussionCommentOut(BaseModel):
    id: int
    discussion_id: int
    author: UserBrief
    text: str
    created_at: LocalDatetime


class FeedItem(BaseModel):
    appeal_id: int
    number: str
    type: AppealType
    category: CategoryRef | None
    department: DepartmentRef | None
    public_summary: str
    result: str
    author_display: str
    implemented_at: LocalDatetime
    discussion_id: int | None


class FeedPage(BaseModel):
    items: list[FeedItem]
    total: int
    page: int
    page_size: int


def _author_display(appeal: Appeal, consent: str | None, directory: Directory) -> str:
    """Имя — только при явном согласии. Без него — подразделение обращения."""
    author = directory.users.get(appeal.author_id)
    if consent == NameConsent.SHOWN and author is not None:
        return author.full_name
    department = directory.department_ref(directory.appeal_department_id(appeal))
    return f"Отдел «{department.name}»" if department else "Сотрудник компании"


def _is_open(discussion: Discussion, now: datetime) -> bool:
    return discussion.status == DiscussionStatus.OPEN and now < discussion.deadline


@dataclass
class _Context:
    """Данные для набора обсуждений, загруженные пачкой, без N+1."""

    directory: Directory
    appeals: dict[int, Appeal]
    totals: dict[tuple[int, str], int]
    mine: dict[int, str]
    comments: dict[int, int]
    headed: set[int]

    @classmethod
    async def load(cls, session: AsyncSession, user: User, discussions: Iterable[Discussion]) -> _Context:
        items = list(discussions)
        ids = [d.id for d in items]
        directory = await Directory.load(session)
        headed = set((await session.execute(select(Department.id).where(Department.head_id == user.id))).scalars())
        if not ids:
            return cls(directory, {}, {}, {}, {}, headed)
        appeal_ids = [d.appeal_id for d in items]
        appeals = {a.id: a for a in (await session.execute(select(Appeal).where(Appeal.id.in_(appeal_ids)))).scalars()}
        totals_rows = await session.execute(
            select(DiscussionVote.discussion_id, DiscussionVote.value, func.count())
            .where(DiscussionVote.discussion_id.in_(ids))
            .group_by(DiscussionVote.discussion_id, DiscussionVote.value)
        )
        totals = {(discussion_id, value): count for discussion_id, value, count in totals_rows.all()}
        mine_rows = await session.execute(
            select(DiscussionVote.discussion_id, DiscussionVote.value).where(
                DiscussionVote.discussion_id.in_(ids), DiscussionVote.user_id == user.id
            )
        )
        comment_rows = await session.execute(
            select(DiscussionComment.discussion_id, func.count())
            .where(DiscussionComment.discussion_id.in_(ids))
            .group_by(DiscussionComment.discussion_id)
        )
        return cls(directory, appeals, totals, dict(mine_rows.all()), dict(comment_rows.all()), headed)

    def out(self, discussion: Discussion, user: User, now: datetime) -> DiscussionOut:
        appeal = self.appeals[discussion.appeal_id]
        department_id = self.directory.appeal_department_id(appeal)
        is_open = discussion.status == DiscussionStatus.OPEN
        return DiscussionOut(
            id=discussion.id,
            appeal=DiscussionAppeal(id=appeal.id, number=appeal.number, type=appeal.type, status=appeal.status),
            public_text=discussion.public_text,
            deadline=discussion.deadline,
            status=discussion.status,
            author_name_consent=discussion.author_name_consent,
            author_display=_author_display(appeal, discussion.author_name_consent, self.directory),
            department=self.directory.department_ref(department_id),
            votes_for=self.totals.get((discussion.id, VoteValue.FOR), 0),
            votes_against=self.totals.get((discussion.id, VoteValue.AGAINST), 0),
            my_vote=self.mine.get(discussion.id),
            comments_count=self.comments.get(discussion.id, 0),
            outcome=discussion.outcome,
            created_by=self.directory.user_brief(discussion.created_by_id),
            created_at=discussion.created_at,
            closed_at=discussion.closed_at,
            can_vote=_is_open(discussion, now),
            can_close=is_open and (user.role == Role.OWNER or department_id in self.headed),
            can_set_name_consent=appeal.author_id == user.id,
        )


async def _out(session: AsyncSession, discussion: Discussion, user: User, now: datetime) -> DiscussionOut:
    await session.flush()
    return (await _Context.load(session, user, [discussion])).out(discussion, user, now)


async def _get(session: AsyncSession, discussion_id: int, *, lock: bool = False) -> Discussion:
    """`lock=True` — для действий: голоса и итог одного обсуждения выполняются по очереди."""
    discussion = await session.get(Discussion, discussion_id, with_for_update=lock, populate_existing=lock)
    if discussion is None:
        raise NotFound("Обсуждение не найдено")
    return discussion


def _require_open(discussion: Discussion, now: datetime) -> None:
    if not _is_open(discussion, now):
        raise VotingClosed()


@router.post("/appeals/{appeal_id}/discussion", response_model=DiscussionOut, status_code=201, summary="Вынести на обсуждение")
async def publish(appeal_id: int, body: DiscussionCreate, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> DiscussionOut:
    now = clock.now()
    appeal = await service.get_visible(session, appeal_id, user, lock=True)
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    f = facts(appeal, directory, extras)
    if not policy.can_process(policy.relations(user, f)):
        raise Forbidden("Это действие вам недоступно")
    if f.has_discussion:
        raise Conflict("Обращение уже вынесено на обсуждение")
    allowed = policy.allowed_actions(user, f)
    if AppealAction.PUBLISH_DISCUSSION not in allowed:
        raise InvalidTransition(
            "Из этого статуса вынести на обсуждение нельзя",
            details={"action": AppealAction.PUBLISH_DISCUSSION, "status": appeal.status, "allowed_actions": allowed},
        )
    if body.deadline <= now:
        raise ValidationFailed(details={"fields": [{"field": "deadline", "message": "Срок должен быть в будущем"}]})
    discussion = Discussion(
        appeal_id=appeal.id,
        public_text=body.public_text.strip(),
        deadline=body.deadline,
        status=DiscussionStatus.OPEN,
        author_name_consent=NameConsent.PENDING,
        created_by_id=user.id,
        created_at=now,
    )
    session.add(discussion)
    await session.flush()
    record(session, appeal, HistoryKind.DISCUSSION_PUBLISHED, now, user.id, comment=discussion.public_text)
    await notify.name_consent_request(session, appeal, discussion.id, now)
    return await _out(session, discussion, user, now)


@router.get("/discussions", response_model=DiscussionPage, summary="Лента обсуждений")
async def list_discussions(
    user: CurrentUserDep,
    session: SessionDep,
    clock: ClockDep,
    status: DiscussionStatus | None = None,
    page: Page = 1,
    page_size: PageSize = 50,
) -> DiscussionPage:
    condition = [Discussion.status == status] if status else []
    total = await session.scalar(select(func.count()).select_from(Discussion).where(*condition))
    rows: Sequence[Discussion] = (
        await session.scalars(
            select(Discussion)
            .where(*condition)
            # Открытые — по ближайшему сроку, за ними завершённые, свежие сверху.
            .order_by(Discussion.status != DiscussionStatus.OPEN, Discussion.closed_at.desc(), Discussion.deadline, Discussion.id)
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).all()
    context = await _Context.load(session, user, rows)
    return DiscussionPage(items=[context.out(d, user, clock.now()) for d in rows], total=total or 0, page=page, page_size=page_size)


@router.get("/discussions/{discussion_id}", response_model=DiscussionOut, summary="Обсуждение")
async def get_discussion(discussion_id: int, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> DiscussionOut:
    return await _out(session, await _get(session, discussion_id), user, clock.now())


@router.put("/discussions/{discussion_id}/vote", response_model=DiscussionOut, summary="Проголосовать или изменить голос")
async def vote(discussion_id: int, body: VoteIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> DiscussionOut:
    now = clock.now()
    discussion = await _get(session, discussion_id, lock=True)
    _require_open(discussion, now)
    existing = await session.get(DiscussionVote, (discussion.id, user.id))
    if existing is None:
        session.add(DiscussionVote(discussion_id=discussion.id, user_id=user.id, value=body.value, updated_at=now))
    else:
        existing.value = body.value
        existing.updated_at = now
    return await _out(session, discussion, user, now)


@router.delete("/discussions/{discussion_id}/vote", response_model=DiscussionOut, summary="Отозвать голос")
async def unvote(discussion_id: int, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> DiscussionOut:
    now = clock.now()
    discussion = await _get(session, discussion_id, lock=True)
    _require_open(discussion, now)
    existing = await session.get(DiscussionVote, (discussion.id, user.id))
    if existing is not None:
        await session.delete(existing)
    return await _out(session, discussion, user, now)


def _comment_out(comment: DiscussionComment, directory: Directory) -> DiscussionCommentOut:
    return DiscussionCommentOut(
        id=comment.id,
        discussion_id=comment.discussion_id,
        author=directory.user_brief(comment.author_id),
        text=comment.text,
        created_at=comment.created_at,
    )


@router.get("/discussions/{discussion_id}/comments", response_model=list[DiscussionCommentOut], summary="Публичные комментарии")
async def list_comments(discussion_id: int, _: CurrentUserDep, session: SessionDep) -> list[DiscussionCommentOut]:
    discussion = await _get(session, discussion_id)
    directory = await Directory.load(session)
    rows = await session.scalars(
        select(DiscussionComment)
        .where(DiscussionComment.discussion_id == discussion.id)
        .order_by(DiscussionComment.created_at, DiscussionComment.id)
    )
    return [_comment_out(c, directory) for c in rows]


@router.post("/discussions/{discussion_id}/comments", response_model=DiscussionCommentOut, status_code=201, summary="Оставить комментарий")
async def post_comment(discussion_id: int, body: CommentIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> DiscussionCommentOut:
    now = clock.now()
    discussion = await _get(session, discussion_id)
    _require_open(discussion, now)
    comment = DiscussionComment(discussion_id=discussion.id, author_id=user.id, text=body.text.strip(), created_at=now)
    session.add(comment)
    await session.flush()
    return _comment_out(comment, await Directory.load(session))


@router.post("/discussions/{discussion_id}/name-consent", response_model=DiscussionOut, summary="Показывать ли имя автора")
async def set_name_consent(discussion_id: int, body: NameConsentIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> DiscussionOut:
    now = clock.now()
    discussion = await _get(session, discussion_id, lock=True)
    appeal = await session.get(Appeal, discussion.appeal_id)
    if appeal.author_id != user.id:
        raise Forbidden("Решить это может только автор обращения")
    new = NameConsent.SHOWN if body.show_name else NameConsent.HIDDEN
    if discussion.author_name_consent != new:
        old, discussion.author_name_consent = discussion.author_name_consent, new
        record(session, appeal, HistoryKind.FIELD_CHANGED, now, user.id, field="author_name_consent", old_value=old, new_value=new)
    return await _out(session, discussion, user, now)


@router.post("/discussions/{discussion_id}/close", response_model=DiscussionOut, summary="Зафиксировать итог обсуждения")
async def close(discussion_id: int, body: OutcomeIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> DiscussionOut:
    now = clock.now()
    discussion = await _get(session, discussion_id, lock=True)
    appeal = await session.get(Appeal, discussion.appeal_id)
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    if not policy.can_close_discussion(policy.relations(user, facts(appeal, directory, extras))):
        raise Forbidden("Итог фиксирует руководитель подразделения или собственник")
    if discussion.status != DiscussionStatus.OPEN:
        raise Conflict("Итог обсуждения уже зафиксирован")
    discussion.status = DiscussionStatus.CLOSED
    discussion.outcome = body.outcome.strip()
    discussion.closed_by_id = user.id
    discussion.closed_at = now
    record(session, appeal, HistoryKind.DISCUSSION_CLOSED, now, user.id, comment=discussion.outcome)
    await notify.discussion_closed(session, appeal, discussion.id, discussion.outcome, user.id, now)
    return await _out(session, discussion, user, now)


@router.get("/feed/implemented", response_model=FeedPage, tags=["feed"], summary="Лента реализованных улучшений")
async def implemented_feed(_: CurrentUserDep, session: SessionDep, page: Page = 1, page_size: PageSize = 50) -> FeedPage:
    condition = Appeal.status == AppealStatus.IMPLEMENTED
    total = await session.scalar(select(func.count()).select_from(Appeal).where(condition))
    appeals = (
        await session.scalars(
            select(Appeal)
            .where(condition)
            .order_by(Appeal.implemented_at.desc().nulls_last(), Appeal.id.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).all()
    directory = await Directory.load(session)
    ids = [a.id for a in appeals]
    discussions = {d.appeal_id: d for d in await session.scalars(select(Discussion).where(Discussion.appeal_id.in_(ids)))} if ids else {}

    def item(appeal: Appeal) -> FeedItem:
        discussion = discussions.get(appeal.id)
        return FeedItem(
            appeal_id=appeal.id,
            number=appeal.number,
            type=appeal.type,
            category=directory.category_ref(appeal.category_id),
            department=directory.department_ref(directory.appeal_department_id(appeal)),
            public_summary=appeal.public_summary or (discussion.public_text if discussion else appeal.summary),
            result=appeal.public_result or appeal.result or "",
            author_display=_author_display(appeal, discussion.author_name_consent if discussion else None, directory),
            implemented_at=appeal.implemented_at or appeal.updated_at,
            discussion_id=discussion.id if discussion else None,
        )

    return FeedPage(items=[item(a) for a in appeals], total=total or 0, page=page, page_size=page_size)
