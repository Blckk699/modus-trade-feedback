"""Маршруты жизненного цикла и приватной переписки обращения (B-06)."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Body
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.api.deps import ClockDep, CurrentUserDep, SessionDep
from app.api.schemas import UserBrief
from app.appeals import lifecycle, service
from app.appeals.schemas import AppealOut
from app.appeals.views import Directory, appeal_out
from app.models import Message

router = APIRouter(tags=["appeal-actions"])

# Обязательный текст: хотя бы один непробельный символ.
Required = Annotated[str, Field(min_length=1, max_length=20_000, pattern=r"\S")]


class CommentIn(BaseModel):
    comment: str | None = Field(default=None, max_length=20_000)


class QuestionIn(BaseModel):
    question: Required


class DecisionIn(BaseModel):
    decision: Required


class ReasonIn(BaseModel):
    reason: Required


class ImplementIn(BaseModel):
    result: Required
    public_summary: str | None = Field(default=None, max_length=2000)
    public_result: str | None = Field(default=None, max_length=20_000)


class MessageIn(BaseModel):
    text: Required


class MessageOut(BaseModel):
    id: int
    appeal_id: int
    author: UserBrief
    text: str
    is_clarification_question: bool
    created_at: datetime


@router.post("/appeals/{appeal_id}/take", response_model=AppealOut, summary="Взять на рассмотрение")
async def take(
    appeal_id: int, user: CurrentUserDep, session: SessionDep, clock: ClockDep, body: Annotated[CommentIn | None, Body()] = None
) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user)
    await lifecycle.take(session, appeal, user, clock.now(), body.comment if body else None)
    return await appeal_out(session, appeal, user, clock.now())


@router.post("/appeals/{appeal_id}/request-info", response_model=AppealOut, summary="Уточняющий вопрос автору")
async def request_info(appeal_id: int, body: QuestionIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user)
    await lifecycle.request_info(session, appeal, user, clock.now(), body.question)
    return await appeal_out(session, appeal, user, clock.now())


@router.post("/appeals/{appeal_id}/start-work", response_model=AppealOut, summary="Принять решение — в работу")
async def start_work(appeal_id: int, body: DecisionIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user)
    await lifecycle.start_work(session, appeal, user, clock.now(), body.decision)
    return await appeal_out(session, appeal, user, clock.now())


@router.post("/appeals/{appeal_id}/reject", response_model=AppealOut, summary="Отклонить с причиной")
async def reject(appeal_id: int, body: ReasonIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user)
    await lifecycle.reject(session, appeal, user, clock.now(), body.reason)
    return await appeal_out(session, appeal, user, clock.now())


@router.post("/appeals/{appeal_id}/implement", response_model=AppealOut, summary="Зафиксировать результат")
async def implement(appeal_id: int, body: ImplementIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user)
    await lifecycle.implement(session, appeal, user, clock.now(), body.result, body.public_summary, body.public_result)
    return await appeal_out(session, appeal, user, clock.now())


@router.post("/appeals/{appeal_id}/accept-feedback", response_model=AppealOut, summary="Принять положительный отзыв")
async def accept_feedback(
    appeal_id: int, user: CurrentUserDep, session: SessionDep, clock: ClockDep, body: Annotated[CommentIn | None, Body()] = None
) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user)
    await lifecycle.accept_feedback(session, appeal, user, clock.now(), body.comment if body else None)
    return await appeal_out(session, appeal, user, clock.now())


@router.get("/appeals/{appeal_id}/messages", response_model=list[MessageOut], summary="Приватная переписка")
async def list_messages(appeal_id: int, user: CurrentUserDep, session: SessionDep) -> list[MessageOut]:
    appeal = await service.get_visible(session, appeal_id, user, full=False)
    await lifecycle.ensure_can_read_messages(session, appeal, user)
    directory = await Directory.load(session)
    rows = await session.execute(select(Message).where(Message.appeal_id == appeal_id).order_by(Message.created_at, Message.id))
    return [_message_out(m, directory) for m in rows.scalars()]


@router.post("/appeals/{appeal_id}/messages", response_model=MessageOut, status_code=201, summary="Написать в переписку")
async def post_message(appeal_id: int, body: MessageIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> MessageOut:
    appeal = await service.get_visible(session, appeal_id, user, full=False)
    await lifecycle.ensure_can_read_messages(session, appeal, user)
    message = await lifecycle.post_message(session, appeal, user, clock.now(), body.text)
    await session.flush()
    return _message_out(message, await Directory.load(session))


def _message_out(message: Message, directory: Directory) -> MessageOut:
    return MessageOut(
        id=message.id,
        appeal_id=message.appeal_id,
        author=directory.user_brief(message.author_id),
        text=message.text,
        is_clarification_question=message.is_clarification_question,
        created_at=message.created_at,
    )
