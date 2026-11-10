"""Поиск и склейка повторов (B-10, истории 19, 34–37, 58; SPEC.md, «Повторы»).

Подсказки считает фоновая задача: подача обращения не ждёт Claude и работает при его недоступности.
Подсказка хранится одна на пару обращений, поэтому отклонённая («Это другое») не появляется снова.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import APIRouter, Response
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters.claude import DuplicateCandidate
from app.api.deps import ClockDep, CurrentUserDep, SessionDep
from app.appeals import policy, service
from app.appeals.history import record
from app.appeals.schemas import AppealOut, AppealRef
from app.appeals.views import Directory, Extras, appeal_out, appeal_ref, facts
from app.domain.enums import AppealAction, AppealStatus, AppealType, ClosedReason, HistoryKind
from app.errors import AppError, Forbidden, NotFound
from app.jobs.registry import JobContext, registry
from app.models import Appeal, AppealParticipant, DuplicateSuggestion, User
from app.notifications import service as notify

router = APIRouter(tags=["duplicates"])

# Сравниваем с самыми свежими открытыми: запрос к модели не должен расти вместе с базой.
MAX_CANDIDATES = 100
MERGEABLE = (AppealStatus.NEW, AppealStatus.IN_REVIEW)


class MergeNotAllowed(AppError):
    status_code = 409
    code = "merge_not_allowed"
    message = "Склеить можно только обращения в статусах «Новое» и «На рассмотрении»."


class MergeIn(BaseModel):
    main_appeal_id: int


class DuplicateSuggestionOut(BaseModel):
    id: int
    appeal_id: int
    similar_appeal: AppealRef
    explanation: str
    can_merge: bool
    created_at: datetime


def _candidate_text(appeal: Appeal) -> str:
    return f"{appeal.summary}\n{appeal.text}"[:2000]


@registry.job(service.FIND_DUPLICATES_JOB)
async def find_duplicates(ctx: JobContext, payload: dict[str, Any]) -> None:
    """Сравнивает новое обращение с открытыми и сохраняет подсказки с объяснением."""
    appeal = await ctx.session.get(Appeal, payload["appeal_id"])
    if appeal is None or AppealStatus(appeal.status).is_final or appeal.type == AppealType.PRAISE:
        return
    rows = await ctx.session.scalars(
        select(Appeal)
        .where(Appeal.id != appeal.id, Appeal.status.in_(policy.NOT_FINAL), Appeal.type != AppealType.PRAISE)
        .order_by(Appeal.created_at.desc(), Appeal.id.desc())
        .limit(MAX_CANDIDATES)
    )
    candidates = {str(a.id): a for a in rows}
    if not candidates:
        return
    matches = await ctx.services.claude.find_duplicates(
        _candidate_text(appeal), [DuplicateCandidate(id=key, text=_candidate_text(a)) for key, a in candidates.items()]
    )
    for match in matches:
        similar = candidates.get(match.id)
        if similar is None:  # модель вернула id не из списка
            continue
        await ctx.session.execute(
            insert(DuplicateSuggestion)
            .values(appeal_id=appeal.id, similar_appeal_id=similar.id, explanation=match.reason.strip(), created_at=ctx.now())
            .on_conflict_do_nothing(index_elements=[DuplicateSuggestion.appeal_id, DuplicateSuggestion.similar_appeal_id])
        )


def _both_mergeable(appeal: Appeal, main: Appeal) -> bool:
    if appeal.id == main.id or AppealType.PRAISE in (appeal.type, main.type):
        return False
    return AppealStatus(appeal.status) in MERGEABLE and AppealStatus(main.status) in MERGEABLE


@router.get("/appeals/{appeal_id}/similar", response_model=list[DuplicateSuggestionOut], summary="Подсказки о похожих обращениях")
async def list_similar(appeal_id: int, user: CurrentUserDep, session: SessionDep) -> list[DuplicateSuggestionOut]:
    appeal = await service.get_visible(session, appeal_id, user)
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    own = facts(appeal, directory, extras)
    # Автору, не обрабатывающему обращение, чужие обращения не показываем: пустой список, а не ошибка.
    if not policy.can_process(policy.relations(user, own)) or AppealStatus(appeal.status).is_final:
        return []
    rows = (
        await session.execute(
            select(DuplicateSuggestion, Appeal)
            .join(Appeal, Appeal.id == DuplicateSuggestion.similar_appeal_id)
            .where(
                DuplicateSuggestion.appeal_id == appeal.id,
                DuplicateSuggestion.dismissed_at.is_(None),
                Appeal.status.in_(policy.NOT_FINAL),
                policy.suggestion_zone_filter(user),
            )
            .order_by(DuplicateSuggestion.id)
        )
    ).all()
    similar_extras = await Extras.load(session, user, [a for _, a in rows])

    def can_merge(similar: Appeal) -> bool:
        main = facts(similar, directory, similar_extras)
        return (
            AppealAction.MERGE in policy.allowed_actions(user, own)
            and policy.can_process(policy.relations(user, main))
            and _both_mergeable(appeal, similar)
        )

    return [
        DuplicateSuggestionOut(
            id=suggestion.id,
            appeal_id=suggestion.appeal_id,
            similar_appeal=appeal_ref(similar),
            explanation=suggestion.explanation,
            can_merge=can_merge(similar),
            created_at=suggestion.created_at,
        )
        for suggestion, similar in rows
    ]


@router.post("/duplicate-suggestions/{suggestion_id}/dismiss", status_code=204, summary="«Это другое»")
async def dismiss(suggestion_id: int, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> Response:
    suggestion = await session.get(DuplicateSuggestion, suggestion_id, with_for_update=True)
    if suggestion is None:
        raise NotFound("Подсказка не найдена")
    appeal = await service.get_visible(session, suggestion.appeal_id, user)
    await _require_processor(session, appeal, user)
    if suggestion.dismissed_at is None:
        suggestion.dismissed_at = clock.now()
        suggestion.dismissed_by_id = user.id
    return Response(status_code=204)


async def _require_processor(session: AsyncSession, appeal: Appeal, user: User) -> None:
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    if not policy.can_process(policy.relations(user, facts(appeal, directory, extras))):
        raise Forbidden("Это действие вам недоступно")


async def _add_participant(session: AsyncSession, main: Appeal, user_id: int, via: Appeal, now: datetime) -> None:
    if user_id == main.author_id:
        return
    await session.execute(
        insert(AppealParticipant)
        .values(appeal_id=main.id, user_id=user_id, via_appeal_id=via.id, added_at=now)
        .on_conflict_do_nothing(index_elements=[AppealParticipant.appeal_id, AppealParticipant.user_id])
    )


@router.post("/appeals/{appeal_id}/merge", response_model=AppealOut, tags=["appeal-actions"], summary="Присоединить как повтор к основному")
async def merge(appeal_id: int, body: MergeIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> AppealOut:
    now = clock.now()
    # Блокируем в одном порядке, чтобы встречные склейки не взаимоблокировались.
    locked = {i: await service.get_visible(session, i, user, lock=True) for i in sorted({appeal_id, body.main_appeal_id})}
    duplicate, main = locked[appeal_id], locked[body.main_appeal_id]
    await _require_processor(session, duplicate, user)
    await _require_processor(session, main, user)
    if not _both_mergeable(duplicate, main):
        message = None
        if duplicate.id == main.id:
            message = "Обращение нельзя присоединить к самому себе"
        elif AppealType.PRAISE in (duplicate.type, main.type):
            message = "Положительный отзыв нельзя склеить: он принимается одним действием"
        raise MergeNotAllowed(message, details={"appeal_status": duplicate.status, "main_appeal_status": main.status})

    inherited = list(await session.scalars(select(AppealParticipant.user_id).where(AppealParticipant.appeal_id == duplicate.id)))
    newcomers = {duplicate.author_id, *inherited}
    for user_id in sorted(newcomers):
        await _add_participant(session, main, user_id, duplicate, now)

    duplicate.merged_into_id = main.id
    duplicate.closed_reason = ClosedReason.MERGED
    old_status, duplicate.status = duplicate.status, AppealStatus.CLOSED
    record(session, duplicate, HistoryKind.STATUS_CHANGED, now, user.id, field="status", old_value=old_status, new_value=AppealStatus.CLOSED)
    record(session, duplicate, HistoryKind.MERGED, now, user.id, new_value=main.number, comment=f"Присоединено к {main.number}")
    # Без имени нового участника: историю основного видят и другие участники.
    record(session, main, HistoryKind.PARTICIPANT_ADDED, now, user.id, comment=f"Присоединён повтор {duplicate.number}")
    await session.flush()
    await notify.appeal_merged(session, duplicate, main, sorted(newcomers), user.id, now)
    return await appeal_out(session, main, user, now)
