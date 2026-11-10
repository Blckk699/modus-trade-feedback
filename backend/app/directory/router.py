"""Справочники для форм и выбора людей: подразделения, категории, сотрудники."""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import or_, select

from app.api.deps import CurrentUserDep, SessionDep
from app.api.schemas import DepartmentRef, UserBrief, UserOut
from app.appeals.views import Directory
from app.domain.enums import Role
from app.models import Category, Department, User

router = APIRouter(tags=["dictionaries"])


class DepartmentOut(BaseModel):
    id: int
    name: str
    head: UserBrief | None


class CategoryOut(BaseModel):
    id: int
    name: str
    department: DepartmentRef
    responsible: UserBrief | None
    deputy: UserBrief | None
    is_active: bool


@router.get("/departments", response_model=list[DepartmentOut], summary="Подразделения")
async def departments(_: CurrentUserDep, session: SessionDep) -> list[DepartmentOut]:
    directory = await Directory.load(session)
    rows = (await session.execute(select(Department).order_by(Department.id))).scalars()
    return [DepartmentOut(id=d.id, name=d.name, head=directory.user_brief(d.head_id)) for d in rows]


@router.get("/categories", response_model=list[CategoryOut], summary="Категории с ответственными")
async def categories(_: CurrentUserDep, session: SessionDep, include_inactive: bool = False) -> list[CategoryOut]:
    directory = await Directory.load(session)
    query = select(Category).order_by(Category.id)
    if not include_inactive:
        query = query.where(Category.is_active)
    return [
        CategoryOut(
            id=c.id,
            name=c.name,
            department=directory.department_ref(c.department_id),
            responsible=directory.user_brief(c.responsible_id),
            deputy=directory.user_brief(c.deputy_id),
            is_active=c.is_active,
        )
        for c in (await session.execute(query)).scalars()
    ]


@router.get("/users", response_model=list[UserOut], summary="Справочник сотрудников")
async def users(
    user: CurrentUserDep,
    session: SessionDep,
    q: str | None = None,
    department_id: int | None = None,
    role: Role | None = None,
    include_disabled: bool = False,
) -> list[UserOut]:
    is_admin = user.role == Role.ADMIN
    directory = await Directory.load(session)
    query = select(User).order_by(User.full_name)
    if not (include_disabled and is_admin):
        query = query.where(User.is_disabled.is_(False))
    if department_id is not None:
        query = query.where(User.department_id == department_id)
    if role is not None:
        query = query.where(User.role == role)
    if q and q.strip():
        pattern = f"%{q.strip()}%"
        query = query.where(or_(User.full_name.ilike(pattern), User.position.ilike(pattern)))
    return [
        UserOut(
            id=u.id,
            # Telegram ID видят только администратор и сам пользователь.
            telegram_id=u.telegram_id if is_admin or u.id == user.id else None,
            full_name=u.full_name,
            position=u.position,
            role=u.role,
            department=directory.department_ref(u.department_id),
            is_absent=u.is_absent,
            is_disabled=u.is_disabled,
        )
        for u in (await session.execute(query)).scalars()
    ]
