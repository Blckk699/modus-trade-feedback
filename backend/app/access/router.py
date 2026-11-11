"""Заявки на доступ и приглашения (B-18, истории 71–74).

Без сессии: подать заявку, узнать её состояние, посмотреть и принять приглашение — опознание в `identity.py`.
Администратор и собственник: рассмотреть заявки, создать, посмотреть и отозвать приглашения.
"""

from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta
from html import escape
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query, Request, Response
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.access.identity import BotTelegramIdDep, TelegramIdentityIn, TelegramProfile, identify
from app.api.deps import ClockDep, CurrentUserDep, SessionDep, SettingsDep
from app.api.schemas import DepartmentRef, UserBrief
from app.auth import service as auth_service
from app.auth.me import MeOut, build_me, user_brief
from app.domain.enums import NotificationKind, Role
from app.errors import (
    AlreadyRegistered,
    Conflict,
    Forbidden,
    InviteInvalid,
    NotFound,
    TooManyRequests,
    UserDisabled,
    ValidationFailed,
)
from app.models import AccessRequest, AccessSubmission, Department, Invite, InviteAttempt, User
from app.notifications import service as notify

router = APIRouter(tags=["access"])

AssignableRole = Literal["employee", "head", "admin"]
RequestStatus = Literal["pending", "approved", "rejected"]
ROLE_LABEL = {"employee": "сотрудник", "head": "руководитель подразделения", "admin": "администратор"}


def require_access_manager(user: CurrentUserDep) -> User:
    """Заявки и приглашения — только администратор и собственник (история 72)."""
    if user.role not in (Role.ADMIN, Role.OWNER):
        raise Forbidden("Заявки и приглашения доступны администратору и собственнику")
    return user


ManagerDep = Annotated[User, Depends(require_access_manager)]


def _field_error(field: str, message: str) -> ValidationFailed:
    return ValidationFailed(message, details={"fields": [{"field": field, "message": message}]})


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


# --- схемы -----------------------------------------------------------------------------------------


class AccessRequestSubmit(TelegramIdentityIn):
    full_name: str = Field(min_length=1, max_length=120, pattern=r"\S")
    department_id: int | None = None
    comment: str | None = Field(default=None, max_length=500)
    telegram_username: str | None = Field(default=None, max_length=64)


class AccessRequestOut(BaseModel):
    id: int
    status: RequestStatus
    full_name: str
    telegram_username: str | None
    department: DepartmentRef | None
    comment: str | None
    created_at: datetime
    updated_at: datetime
    assigned_role: AssignableRole | None
    assigned_department: DepartmentRef | None
    decided_by: UserBrief | None
    decided_at: datetime | None
    reject_reason: str | None
    user_id: int | None


class AccessRequestPage(BaseModel):
    items: list[AccessRequestOut]
    total: int
    page: int
    page_size: int


class AccessStatusOut(BaseModel):
    state: Literal["none", "pending", "rejected", "registered", "disabled"]
    request: AccessRequestOut | None


class AccessRequestApprove(BaseModel):
    role: AssignableRole = "employee"
    department_id: int | None = None
    full_name: str | None = Field(default=None, min_length=1, max_length=120, pattern=r"\S")
    position: str | None = Field(default=None, max_length=120)


class AccessRequestReject(BaseModel):
    reason: str | None = Field(default=None, max_length=500)


class InviteOut(BaseModel):
    id: int
    state: Literal["active", "expired", "revoked", "exhausted"]
    role: AssignableRole
    department: DepartmentRef | None
    full_name: str | None
    created_by: UserBrief
    created_at: datetime
    expires_at: datetime
    max_uses: int
    used_count: int
    revoked_at: datetime | None


class InviteCreate(BaseModel):
    role: AssignableRole
    department_id: int | None = None
    full_name: str | None = Field(default=None, max_length=120)
    expires_in_days: int = Field(default=7, ge=1, le=30)
    max_uses: int = Field(default=1, ge=1, le=100)


class InviteCreated(InviteOut):
    token: str
    bot_link: str
    web_link: str


class InvitePreview(BaseModel):
    role: AssignableRole
    department: DepartmentRef | None
    full_name: str | None
    expires_at: datetime


class InviteAccept(TelegramIdentityIn):
    token: str = Field(min_length=1, max_length=200)
    full_name: str | None = Field(default=None, max_length=120)
    telegram_username: str | None = Field(default=None, max_length=64)


class SessionToken(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_at: datetime


class InviteAccepted(BaseModel):
    created: bool
    user: MeOut
    session: SessionToken | None


# --- сборка ответов --------------------------------------------------------------------------------


async def _department(session: AsyncSession, department_id: int | None) -> DepartmentRef | None:
    if department_id is None:
        return None
    department = await session.get(Department, department_id)
    return DepartmentRef(id=department.id, name=department.name) if department else None


async def _brief(session: AsyncSession, user_id: int | None) -> UserBrief | None:
    if user_id is None:
        return None
    user = await session.get(User, user_id)
    return await user_brief(session, user) if user else None


async def request_out(session: AsyncSession, request: AccessRequest) -> AccessRequestOut:
    return AccessRequestOut(
        id=request.id,
        status=request.status,
        full_name=request.full_name,
        telegram_username=request.telegram_username,
        department=await _department(session, request.department_id),
        comment=request.comment,
        created_at=request.created_at,
        updated_at=request.updated_at,
        assigned_role=request.assigned_role,
        assigned_department=await _department(session, request.assigned_department_id),
        decided_by=await _brief(session, request.decided_by_id),
        decided_at=request.decided_at,
        reject_reason=request.reject_reason,
        user_id=request.user_id,
    )


def invite_state(invite: Invite, now: datetime) -> str:
    if invite.revoked_at is not None:
        return "revoked"
    if invite.used_count >= invite.max_uses:
        return "exhausted"
    if invite.expires_at <= now:
        return "expired"
    return "active"


async def invite_out(session: AsyncSession, invite: Invite, now: datetime) -> InviteOut:
    return InviteOut(
        id=invite.id,
        state=invite_state(invite, now),
        role=invite.role,
        department=await _department(session, invite.department_id),
        full_name=invite.full_name,
        created_by=await _brief(session, invite.created_by_id),
        created_at=invite.created_at,
        expires_at=invite.expires_at,
        max_uses=invite.max_uses,
        used_count=invite.used_count,
        revoked_at=invite.revoked_at,
    )


async def _check_department(session: AsyncSession, department_id: int | None, field: str) -> None:
    if department_id is not None and await session.get(Department, department_id) is None:
        raise _field_error(field, "Подразделение не найдено")


def _clean(text: str | None) -> str | None:
    text = (text or "").strip()
    return text or None


# --- без сессии: заявка ----------------------------------------------------------------------------


@router.get("/access-requests/departments", response_model=list[DepartmentRef], summary="Подразделения для заявки")
async def departments_for_request(session: SessionDep) -> list[DepartmentRef]:
    rows = (await session.execute(select(Department).order_by(Department.name))).scalars()
    return [DepartmentRef(id=d.id, name=d.name) for d in rows]


async def _latest_request(session: AsyncSession, telegram_id: int, *, lock: bool = False) -> AccessRequest | None:
    query = (
        select(AccessRequest)
        .where(AccessRequest.telegram_id == telegram_id)
        .order_by(AccessRequest.created_at.desc(), AccessRequest.id.desc())
        .limit(1)
    )
    if lock:
        query = query.with_for_update()
    return await session.scalar(query)


async def _check_rate(session: AsyncSession, telegram_id: int, now: datetime, settings: SettingsDep) -> None:
    since = now - timedelta(seconds=settings.access_request_window_seconds)
    count = await session.scalar(
        select(func.count())
        .select_from(AccessSubmission)
        .where(AccessSubmission.telegram_id == telegram_id, AccessSubmission.created_at > since)
    )
    if (count or 0) >= settings.access_request_max_per_window:
        raise TooManyRequests("Слишком часто. Попробуйте подать заявку позже.")
    session.add(AccessSubmission(telegram_id=telegram_id, created_at=now))


async def _notify_managers(session: AsyncSession, request: AccessRequest, now: datetime) -> None:
    """Новая заявка — администраторам и собственнику со ссылкой на экран заявок."""
    managers = (
        await session.execute(
            select(User.id).where(User.role.in_([Role.ADMIN, Role.OWNER]), User.is_disabled.is_(False)).order_by(User.id)
        )
    ).scalars()
    department = await session.get(Department, request.department_id) if request.department_id else None
    lines = [f"Новая заявка на доступ: <b>{notify.fragment(request.full_name, 120)}</b>"]
    if request.telegram_username:
        lines.append(f"Telegram: @{escape(request.telegram_username)}")
    if department:
        lines.append(f"Подразделение: {escape(department.name)}")
    if request.comment:
        lines.append(f"Комментарий: {notify.fragment(request.comment, 500)}")
    text = "\n".join(lines)
    button = {"type": "open_access_requests", "text": "Открыть заявки", "appeal_id": None, "discussion_id": None}
    for manager_id in managers:
        notify.add(
            session, manager_id, NotificationKind.ACCESS_REQUEST_CREATED, text, now,
            path="/settings/access-requests", buttons=[button],
        )


@router.post(
    "/access-requests",
    response_model=AccessRequestOut,
    status_code=201,
    summary="Подать или обновить заявку на доступ",
)
async def submit_access_request(
    body: AccessRequestSubmit,
    response: Response,
    bot_id: BotTelegramIdDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
) -> AccessRequestOut:
    now = clock.now()
    profile = identify(body, bot_id, settings, now, bot_username=_clean(body.telegram_username))
    user = await auth_service.user_by_telegram_id(session, profile.telegram_id)
    if user is not None:
        raise UserDisabled() if user.is_disabled else AlreadyRegistered()
    await _check_rate(session, profile.telegram_id, now, settings)
    await _check_department(session, body.department_id, "department_id")

    fields = dict(
        full_name=body.full_name.strip(),
        telegram_username=profile.username,
        department_id=body.department_id,
        comment=_clean(body.comment),
        updated_at=now,
    )
    latest = await _latest_request(session, profile.telegram_id, lock=True)
    if latest is not None and latest.status == "pending":
        for key, value in fields.items():
            setattr(latest, key, value)
        await session.flush()
        response.status_code = 200
        return await request_out(session, latest)

    request = AccessRequest(telegram_id=profile.telegram_id, status="pending", created_at=now, **fields)
    session.add(request)
    await session.flush()
    await _notify_managers(session, request, now)
    return await request_out(session, request)


@router.post("/access-requests/mine", response_model=AccessStatusOut, summary="Состояние доступа и своей заявки")
async def my_access_request(
    body: TelegramIdentityIn, bot_id: BotTelegramIdDep, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> AccessStatusOut:
    profile = identify(body, bot_id, settings, clock.now())
    latest = await _latest_request(session, profile.telegram_id)
    request = await request_out(session, latest) if latest else None
    user = await auth_service.user_by_telegram_id(session, profile.telegram_id)
    if user is not None:
        return AccessStatusOut(state="disabled" if user.is_disabled else "registered", request=request)
    if latest is None or latest.status == "approved":
        return AccessStatusOut(state="none", request=request)
    return AccessStatusOut(state=latest.status, request=request)


# --- администратор и собственник: заявки ------------------------------------------------------------


@router.get("/admin/access-requests", response_model=AccessRequestPage, summary="Заявки на доступ")
async def list_access_requests(
    _: ManagerDep,
    session: SessionDep,
    status: RequestStatus | None = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=200)] = 50,
) -> AccessRequestPage:
    query = select(AccessRequest)
    if status is not None:
        query = query.where(AccessRequest.status == status)
    total = await session.scalar(select(func.count()).select_from(query.subquery()))
    rows = (
        await session.execute(
            query.order_by(AccessRequest.created_at.desc(), AccessRequest.id.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).scalars().all()
    return AccessRequestPage(
        items=[await request_out(session, r) for r in rows], total=total or 0, page=page, page_size=page_size
    )


async def _pending_request(session: AsyncSession, request_id: int) -> AccessRequest:
    request = await session.get(AccessRequest, request_id, with_for_update=True)
    if request is None:
        raise NotFound("Заявка не найдена")
    if request.status != "pending":
        raise Conflict("Заявка уже рассмотрена")
    return request


@router.post(
    "/admin/access-requests/{request_id}/approve", response_model=AccessRequestOut, summary="Одобрить заявку"
)
async def approve_access_request(
    request_id: int, body: AccessRequestApprove, manager: ManagerDep, session: SessionDep, clock: ClockDep
) -> AccessRequestOut:
    now = clock.now()
    request = await _pending_request(session, request_id)
    department_id = body.department_id if "department_id" in body.model_fields_set else request.department_id
    await _check_department(session, department_id, "department_id")
    if await auth_service.user_by_telegram_id(session, request.telegram_id) is not None:
        raise Conflict("Этот Telegram-аккаунт уже есть в системе")

    user = User(
        telegram_id=request.telegram_id,
        full_name=(body.full_name or request.full_name).strip(),
        position=_clean(body.position),
        role=body.role,
        department_id=department_id,
        is_absent=False,
        is_disabled=False,
        created_at=now,
    )
    session.add(user)
    await session.flush()
    request.status = "approved"
    request.assigned_role = body.role
    request.assigned_department_id = department_id
    request.decided_by_id = manager.id
    request.decided_at = now
    request.updated_at = now
    request.user_id = user.id

    department = await session.get(Department, department_id) if department_id else None
    where = f", {escape(department.name)}" if department else ""
    notify.add(
        session, user.id, NotificationKind.ACCESS_REQUEST_APPROVED,
        f"Заявка на доступ одобрена. Ваша роль: {ROLE_LABEL[body.role]}{where}.\n"
        "Откройте меню бота, чтобы подать обращение или войти в приложение.",
        now, path=None, buttons=[],
    )
    await session.flush()
    return await request_out(session, request)


@router.post("/admin/access-requests/{request_id}/reject", response_model=AccessRequestOut, summary="Отклонить заявку")
async def reject_access_request(
    request_id: int, body: AccessRequestReject, manager: ManagerDep, session: SessionDep, clock: ClockDep
) -> AccessRequestOut:
    now = clock.now()
    request = await _pending_request(session, request_id)
    request.status = "rejected"
    request.reject_reason = _clean(body.reason)
    request.decided_by_id = manager.id
    request.decided_at = now
    request.updated_at = now
    text = "Заявка на доступ отклонена."
    if request.reject_reason:
        text += f"\nПричина: {notify.fragment(request.reject_reason, 500)}"
    notify.add(
        session, None, NotificationKind.ACCESS_REQUEST_REJECTED, text, now,
        path=None, buttons=[], telegram_id=request.telegram_id,
    )
    await session.flush()
    return await request_out(session, request)


# --- администратор и собственник: приглашения ------------------------------------------------------


@router.get("/admin/invites", response_model=list[InviteOut], summary="Приглашения")
async def list_invites(
    _: ManagerDep, session: SessionDep, clock: ClockDep, include_inactive: bool = True
) -> list[InviteOut]:
    now = clock.now()
    rows = (await session.execute(select(Invite).order_by(Invite.created_at.desc(), Invite.id.desc()))).scalars()
    invites = [i for i in rows if include_inactive or invite_state(i, now) == "active"]
    return [await invite_out(session, i, now) for i in invites]


@router.post("/admin/invites", response_model=InviteCreated, status_code=201, summary="Создать приглашение")
async def create_invite(
    body: InviteCreate, manager: ManagerDep, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> InviteCreated:
    now = clock.now()
    await _check_department(session, body.department_id, "department_id")
    token = secrets.token_urlsafe(24)
    invite = Invite(
        token_hash=_sha256(token),
        role=body.role,
        department_id=body.department_id,
        full_name=_clean(body.full_name),
        created_by_id=manager.id,
        created_at=now,
        expires_at=now + timedelta(days=body.expires_in_days),
        max_uses=body.max_uses,
        used_count=0,
    )
    session.add(invite)
    await session.flush()
    out = await invite_out(session, invite, now)
    return InviteCreated(
        **out.model_dump(),
        token=token,
        bot_link=f"https://t.me/{settings.telegram_bot_username}?start=inv_{token}",
        web_link=f"{settings.public_web_url.rstrip('/')}/invite/{token}",
    )


@router.post("/admin/invites/{invite_id}/revoke", response_model=InviteOut, summary="Отозвать приглашение")
async def revoke_invite(invite_id: int, _: ManagerDep, session: SessionDep, clock: ClockDep) -> InviteOut:
    now = clock.now()
    invite = await session.get(Invite, invite_id, with_for_update=True)
    if invite is None:
        raise NotFound("Приглашение не найдено")
    if invite.revoked_at is None:
        invite.revoked_at = now
    return await invite_out(session, invite, now)


# --- без сессии: приглашение -----------------------------------------------------------------------


def _attempt_key(request: Request, bot_id: int | None) -> str:
    """Бот ходит с одного адреса за всех, поэтому его попытки считаются по Telegram ID пользователя.
    Адрес клиента — из X-Forwarded-For только от доверенного прокси (см. create_app)."""
    if bot_id is not None:
        return f"tg:{bot_id}"
    return f"ip:{request.client.host if request.client else 'unknown'}"


async def _valid_invite(
    session: AsyncSession,
    request: Request,
    token: str,
    now: datetime,
    settings: SettingsDep,
    *,
    attempt_key: str,
    lock: bool = False,
) -> Invite:
    """Действующее приглашение по токену. Токен бывает в путях и логах, поэтому неудачные попытки
    ограничены: больше `invite_max_failures` за окно с одного ключа — 429 до конца окна."""
    since = now - timedelta(seconds=settings.invite_failure_window_seconds)
    failures = await session.scalar(
        select(func.count())
        .select_from(InviteAttempt)
        .where(InviteAttempt.key == attempt_key, InviteAttempt.created_at > since)
    )
    if (failures or 0) >= settings.invite_max_failures:
        raise TooManyRequests("Слишком много попыток с недействительными приглашениями. Подождите и попробуйте снова.")
    query = select(Invite).where(Invite.token_hash == _sha256(token))
    if lock:
        query = query.with_for_update()
    invite = await session.scalar(query)
    if invite is None or invite_state(invite, now) != "active":
        # Транзакция запроса откатится вместе с ошибкой — неудачу пишем отдельной.
        async with request.app.state.sessionmaker() as attempts, attempts.begin():
            attempts.add(InviteAttempt(key=attempt_key, created_at=now))
        raise InviteInvalid()
    return invite


@router.get("/invites/{token}", response_model=InvitePreview, summary="Что за приглашение")
async def invite_preview(
    token: str, request: Request, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> InvitePreview:
    invite = await _valid_invite(session, request, token, clock.now(), settings, attempt_key=_attempt_key(request, None))
    return InvitePreview(
        role=invite.role,
        department=await _department(session, invite.department_id),
        full_name=invite.full_name,
        expires_at=invite.expires_at,
    )


async def _session_token(
    session: AsyncSession, user: User, profile: TelegramProfile, now: datetime, settings: SettingsDep
) -> SessionToken | None:
    if profile.channel == "bot":
        return None
    token, expires_at = await auth_service.open_session(session, user, f"invite_{profile.channel}", now, settings)
    return SessionToken(access_token=token, expires_at=expires_at)


@router.post("/invites/accept", response_model=InviteAccepted, summary="Принять приглашение")
async def accept_invite(
    body: InviteAccept,
    request: Request,
    bot_id: BotTelegramIdDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
) -> InviteAccepted:
    now = clock.now()
    profile = identify(body, bot_id, settings, now, bot_username=_clean(body.telegram_username))

    existing = await auth_service.user_by_telegram_id(session, profile.telegram_id)
    if existing is not None:
        # Уже заведённый пользователь по ссылке ничего не меняет и приглашение не расходует.
        auth_service.ensure_can_login(existing)
        return InviteAccepted(
            created=False,
            user=await build_me(session, existing),
            session=await _session_token(session, existing, profile, now, settings),
        )

    invite = await _valid_invite(
        session, request, body.token, now, settings, attempt_key=_attempt_key(request, bot_id), lock=True
    )
    full_name = invite.full_name or _clean(body.full_name) or profile.name
    if not full_name:
        raise _field_error("full_name", "Укажите имя")
    user = User(
        telegram_id=profile.telegram_id,
        full_name=full_name[:200],
        position=None,
        role=invite.role,
        department_id=invite.department_id,
        is_absent=False,
        is_disabled=False,
        created_at=now,
    )
    session.add(user)
    invite.used_count += 1
    await session.flush()

    # Заявка «на рассмотрении» от того же аккаунта закрывается: доступ выдан по приглашению.
    pending = await _latest_request(session, profile.telegram_id, lock=True)
    if pending is not None and pending.status == "pending":
        pending.status = "approved"
        pending.assigned_role = invite.role
        pending.assigned_department_id = invite.department_id
        pending.decided_by_id = invite.created_by_id
        pending.decided_at = now
        pending.updated_at = now
        pending.user_id = user.id

    return InviteAccepted(
        created=True,
        user=await build_me(session, user),
        session=await _session_token(session, user, profile, now, settings),
    )
