"""«Кто я»: роль, подразделение, назначения ответственным и права для навигации клиента."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.schemas import CategoryRef, DepartmentRef, UserBrief, UserOut
from app.domain.enums import FINAL_STATUSES, Role
from app.models import Appeal, Category, Department, User


class Permissions(BaseModel):
    can_create_appeal: bool
    can_process_appeals: bool
    can_view_department: bool
    can_view_all_appeals: bool
    analytics_scope: Literal["none", "department", "company"]
    can_upload_meetings: bool
    can_manage_settings: bool
    can_view_unassigned: bool
    can_manage_access: bool


class MeOut(UserOut):
    responsible_for: list[CategoryRef]
    deputy_for: list[CategoryRef]
    assigned_open_count: int
    permissions: Permissions


async def department_ref(session: AsyncSession, department_id: int | None) -> DepartmentRef | None:
    if department_id is None:
        return None
    department = await session.get(Department, department_id)
    return DepartmentRef(id=department.id, name=department.name) if department else None


async def user_brief(session: AsyncSession, user: User) -> UserBrief:
    return UserBrief(
        id=user.id, full_name=user.full_name, role=user.role, department=await department_ref(session, user.department_id)
    )


async def user_out(session: AsyncSession, user: User, *, show_telegram_id: bool) -> UserOut:
    return UserOut(
        id=user.id,
        telegram_id=user.telegram_id if show_telegram_id else None,
        full_name=user.full_name,
        position=user.position,
        role=user.role,
        department=await department_ref(session, user.department_id),
        is_absent=user.is_absent,
        is_disabled=user.is_disabled,
    )


def permissions_for(role: Role, *, has_assignments: bool, heads_department: bool) -> Permissions:
    """Зона руководителя — подразделения, где он записан руководителем (`Department.head_id`)."""
    if role == Role.OWNER:
        analytics = "company"
    elif heads_department:
        analytics = "department"
    else:
        analytics = "none"
    return Permissions(
        can_create_appeal=True,
        # Ответственный — не роль, а назначение: очередь есть у закреплённых за категорией или обращением,
        # а руководитель и собственник могут выполнить любое действие ответственного в своей зоне.
        can_process_appeals=has_assignments or heads_department or role == Role.OWNER,
        can_view_department=heads_department,
        can_view_all_appeals=role in (Role.ADMIN, Role.OWNER),
        analytics_scope=analytics,
        can_upload_meetings=role in (Role.HEAD, Role.OWNER),
        can_manage_settings=role == Role.ADMIN,
        can_view_unassigned=role in (Role.ADMIN, Role.OWNER),
        can_manage_access=role in (Role.ADMIN, Role.OWNER),
    )


async def build_me(session: AsyncSession, user: User) -> MeOut:
    categories = (
        await session.execute(
            select(Category)
            .where(Category.is_active, or_(Category.responsible_id == user.id, Category.deputy_id == user.id))
            .order_by(Category.id)
        )
    ).scalars().all()
    responsible = [CategoryRef(id=c.id, name=c.name) for c in categories if c.responsible_id == user.id]
    deputy = [CategoryRef(id=c.id, name=c.name) for c in categories if c.deputy_id == user.id]
    assigned_open = await session.scalar(
        select(func.count())
        .select_from(Appeal)
        .where(Appeal.assignee_id == user.id, Appeal.status.notin_([s.value for s in FINAL_STATUSES]))
    )
    heads = await session.scalar(select(func.count()).select_from(Department).where(Department.head_id == user.id))
    base = await user_out(session, user, show_telegram_id=True)
    return MeOut(
        **base.model_dump(),
        responsible_for=responsible,
        deputy_for=deputy,
        assigned_open_count=assigned_open or 0,
        permissions=permissions_for(
            Role(user.role), has_assignments=bool(categories or assigned_open), heads_department=bool(heads)
        ),
    )
