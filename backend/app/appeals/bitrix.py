"""Задача в Битрикс24 из обращения (история 39). Одна задача на обращение, обратной синхронизации нет."""

from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import BitrixDep, ClockDep, CurrentUserDep, SessionDep
from app.appeals import lifecycle, policy, service
from app.appeals.history import record
from app.appeals.schemas import BitrixTaskOut
from app.appeals.views import Directory, Extras, facts
from app.domain.enums import AppealAction, HistoryKind
from app.errors import AppError, ExternalServiceError, Forbidden
from app.models import Appeal, BitrixTask, User

router = APIRouter(tags=["bitrix"])


class BitrixUnavailable(AppError):
    status_code = 502
    code = "bitrix_unavailable"
    message = "Не удалось создать задачу в Битрикс24. Попробуйте позже."


def task_description(appeal: Appeal, author: User | None) -> str:
    parts = [f"Обращение {appeal.number} из системы обращений сотрудников.", "", appeal.text]
    if appeal.proposed_solution:
        parts += ["", f"Предлагаемое решение: {appeal.proposed_solution}"]
    if appeal.decision:
        parts += ["", f"Принятое решение: {appeal.decision}"]
    if author:
        parts += ["", f"Автор: {author.full_name}"]
    return "\n".join(parts)


async def create_task(session: AsyncSession, appeal: Appeal, user: User, bitrix, now: datetime) -> tuple[BitrixTask, bool]:
    """Создаёт задачу или возвращает уже созданную. Второй элемент — создана ли сейчас."""
    existing = await session.get(BitrixTask, appeal.id)
    if existing is not None:
        directory = await Directory.load(session)
        extras = await Extras.load(session, user, [appeal])
        if not policy.can_process(policy.relations(user, facts(appeal, directory, extras))):
            raise Forbidden("Создать задачу в Битрикс24 могут ответственный, руководитель и собственник")
        return existing, False
    await lifecycle._check(session, appeal, user, AppealAction.CREATE_BITRIX_TASK, who="process")
    deadline = appeal.first_response_due_at if appeal.first_response_due_at and appeal.first_response_due_at > now else None
    try:
        created = await bitrix.create_task(
            title=f"{appeal.number}: {appeal.summary or appeal.text[:100]}",
            description=task_description(appeal, await session.get(User, appeal.author_id)),
            deadline=deadline,
        )
    except ExternalServiceError as exc:
        raise BitrixUnavailable() from exc
    task = BitrixTask(appeal_id=appeal.id, task_id=created.id, url=created.url, created_by_id=user.id, created_at=now)
    session.add(task)
    record(session, appeal, HistoryKind.BITRIX_TASK_CREATED, now, user.id, field="bitrix_task", new_value=created.url)
    return task, True


@router.post("/appeals/{appeal_id}/bitrix-task", response_model=BitrixTaskOut, status_code=201, summary="Задача в Битрикс24")
async def create_bitrix_task(
    appeal_id: int, response: Response, user: CurrentUserDep, session: SessionDep, clock: ClockDep, bitrix: BitrixDep
) -> BitrixTaskOut:
    appeal = await service.get_visible(session, appeal_id, user, lock=True)
    task, created = await create_task(session, appeal, user, bitrix, clock.now())
    if not created:
        response.status_code = 200
    return BitrixTaskOut(task_id=task.task_id, url=task.url, created_at=task.created_at)
