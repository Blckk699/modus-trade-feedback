"""Настройки администратора: сотрудники, подразделения, категории, сроки, время сводки (истории 64–70).

Все маршруты — только администратору. Изменения сразу влияют на вход, маршрутизацию и сроки
новых обращений. Очередь нераспределённых — `GET /appeals?scope=unassigned`, назначение —
`POST /appeals/{id}/reassign`.
"""

from __future__ import annotations

import re
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import ClockDep, CurrentUserDep, SessionDep, SettingsDep
from app.api.schemas import UserOut
from app.appeals.routing import can_be_assignee
from app.appeals.views import Directory
from app.auth.service import revoke_user_sessions
from app.directory.router import CategoryOut, DepartmentOut
from app.domain.enums import Priority, Role
from app.errors import Conflict, Forbidden, NotFound, ValidationFailed
from app.models import Category, DeadlineRule, Department, SystemSetting, User
from app.models.org import User as UserModel

TIME_RE = re.compile(r"^([01][0-9]|2[0-3]):[0-5][0-9]$")


def require_admin(user: CurrentUserDep) -> UserModel:
    if user.role != Role.ADMIN:
        raise Forbidden("Настройки доступны только администратору")
    return user


AdminDep = Annotated[UserModel, Depends(require_admin)]
router = APIRouter(prefix="/admin", tags=["admin"])


def field_error(field: str, message: str) -> ValidationFailed:
    return ValidationFailed(message, details={"fields": [{"field": field, "message": message}]})


# --- схемы ---------------------------------------------------------------------------------------


class UserCreate(BaseModel):
    telegram_id: int = Field(gt=0)
    full_name: str = Field(min_length=1, max_length=200, pattern=r"\S")
    position: str | None = Field(default=None, max_length=200)
    role: Role
    department_id: int | None = None


class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=200, pattern=r"\S")
    position: str | None = Field(default=None, max_length=200)
    role: Role | None = None
    department_id: int | None = None
    is_absent: bool | None = None
    is_disabled: bool | None = None


class DepartmentWrite(BaseModel):
    name: str = Field(min_length=1, max_length=200, pattern=r"\S")
    head_id: int | None = None


class DepartmentUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200, pattern=r"\S")
    head_id: int | None = None


class CategoryWrite(BaseModel):
    name: str = Field(min_length=1, max_length=200, pattern=r"\S")
    department_id: int
    responsible_id: int | None = None
    deputy_id: int | None = None


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200, pattern=r"\S")
    department_id: int | None = None
    responsible_id: int | None = None
    deputy_id: int | None = None
    is_active: bool | None = None


class DeadlineRuleOut(BaseModel):
    priority: Priority
    business_days: int = Field(ge=1, le=30)


class SettingsOut(BaseModel):
    digest_time: str
    timezone: str


class SettingsUpdate(BaseModel):
    digest_time: str | None = None

    @field_validator("digest_time")
    @classmethod
    def _time(cls, value: str | None) -> str | None:
        if value is not None and not TIME_RE.match(value):
            raise ValueError("Время в формате ЧЧ:ММ")
        return value


# --- проверки ---------------------------------------------------------------------------------------


async def _department(session: AsyncSession, department_id: int | None, field: str = "department_id") -> None:
    if department_id is not None and await session.get(Department, department_id) is None:
        raise field_error(field, "Такого подразделения нет")


async def _assignable(session: AsyncSession, user_id: int | None, field: str) -> None:
    """Руководитель, ответственный и заместитель — действующий сотрудник, не администратор."""
    if user_id is None:
        return
    if not can_be_assignee(await session.get(User, user_id)):
        raise field_error(field, "Нужен действующий сотрудник, не администратор")


def _user_out(user: User, directory: Directory) -> UserOut:
    return UserOut(
        id=user.id,
        telegram_id=user.telegram_id,
        full_name=user.full_name,
        position=user.position,
        role=user.role,
        department=directory.department_ref(user.department_id),
        is_absent=user.is_absent,
        is_disabled=user.is_disabled,
    )


def _category_out(category: Category, directory: Directory) -> CategoryOut:
    return CategoryOut(
        id=category.id,
        name=category.name,
        department=directory.department_ref(category.department_id),
        responsible=directory.user_brief(category.responsible_id),
        deputy=directory.user_brief(category.deputy_id),
        is_active=category.is_active,
    )


async def _unique(session: AsyncSession, model, name: str, exclude_id: int | None = None) -> None:
    query = select(func.count()).select_from(model).where(func.lower(model.name) == name.strip().lower())
    if exclude_id is not None:
        query = query.where(model.id != exclude_id)
    if await session.scalar(query):
        raise Conflict("Такое название уже есть")


# --- сотрудники ---------------------------------------------------------------------------------------


@router.post("/users", response_model=UserOut, status_code=201, summary="Добавить сотрудника по Telegram ID")
async def create_user(body: UserCreate, _: AdminDep, session: SessionDep, clock: ClockDep) -> UserOut:
    if await session.scalar(select(User.id).where(User.telegram_id == body.telegram_id)):
        raise Conflict("Сотрудник с таким Telegram ID уже есть")
    await _department(session, body.department_id)
    user = User(
        telegram_id=body.telegram_id,
        full_name=body.full_name.strip(),
        position=(body.position or "").strip() or None,
        role=body.role,
        department_id=body.department_id,
        is_absent=False,
        is_disabled=False,
        created_at=clock.now(),
    )
    session.add(user)
    await session.flush()
    return _user_out(user, await Directory.load(session))


@router.patch("/users/{user_id}", response_model=UserOut, summary="Роль, подразделение, отсутствие, доступ")
async def update_user(user_id: int, body: UserUpdate, admin: AdminDep, session: SessionDep, clock: ClockDep) -> UserOut:
    user = await session.get(User, user_id)
    if user is None:
        raise NotFound("Сотрудник не найден")
    data = body.model_dump(exclude_unset=True)
    if user.id == admin.id and (data.get("is_disabled") or data.get("role", Role.ADMIN) != Role.ADMIN):
        raise field_error("is_disabled" if data.get("is_disabled") else "role", "Нельзя отключить или понизить себя")
    if "department_id" in data:
        await _department(session, data["department_id"])
    # null допустим только для полей, которые можно очистить: должность и подразделение.
    for key in ("full_name", "role", "is_absent", "is_disabled"):
        if data.get(key) is not None:
            setattr(user, key, data[key].strip() if isinstance(data[key], str) else data[key])
    if "position" in data:
        user.position = (data["position"] or "").strip() or None
    if "department_id" in data:
        user.department_id = data["department_id"]
    if user.role == Role.ADMIN:
        # Администратор не обрабатывает обращения: снимаем его с категорий и руководства.
        held = await session.scalar(
            select(func.count()).select_from(Category).where(
                (Category.responsible_id == user.id) | (Category.deputy_id == user.id)
            )
        ) or await session.scalar(select(func.count()).select_from(Department).where(Department.head_id == user.id))
        if held:
            raise field_error("role", "Сначала снимите сотрудника с категорий и руководства подразделением")
    if data.get("is_disabled"):
        await revoke_user_sessions(session, user.id, clock.now())
    return _user_out(user, await Directory.load(session))


# --- подразделения ---------------------------------------------------------------------------------------


@router.post("/departments", response_model=DepartmentOut, status_code=201, summary="Добавить подразделение")
async def create_department(body: DepartmentWrite, _: AdminDep, session: SessionDep) -> DepartmentOut:
    await _unique(session, Department, body.name)
    await _assignable(session, body.head_id, "head_id")
    department = Department(name=body.name.strip(), head_id=body.head_id)
    session.add(department)
    await session.flush()
    directory = await Directory.load(session)
    return DepartmentOut(id=department.id, name=department.name, head=directory.user_brief(department.head_id))


@router.patch("/departments/{department_id}", response_model=DepartmentOut, summary="Название или руководитель")
async def update_department(department_id: int, body: DepartmentUpdate, _: AdminDep, session: SessionDep) -> DepartmentOut:
    department = await session.get(Department, department_id)
    if department is None:
        raise NotFound("Подразделение не найдено")
    data = body.model_dump(exclude_unset=True)
    if data.get("name"):
        await _unique(session, Department, data["name"], department.id)
        department.name = data["name"].strip()
    if "head_id" in data:
        await _assignable(session, data["head_id"], "head_id")
        department.head_id = data["head_id"]
    directory = await Directory.load(session)
    return DepartmentOut(id=department.id, name=department.name, head=directory.user_brief(department.head_id))


# --- категории ---------------------------------------------------------------------------------------


@router.post("/categories", response_model=CategoryOut, status_code=201, summary="Добавить категорию")
async def create_category(body: CategoryWrite, _: AdminDep, session: SessionDep) -> CategoryOut:
    await _unique(session, Category, body.name)
    await _department(session, body.department_id)
    await _assignable(session, body.responsible_id, "responsible_id")
    await _assignable(session, body.deputy_id, "deputy_id")
    if body.deputy_id is not None and body.deputy_id == body.responsible_id:
        raise field_error("deputy_id", "Заместитель должен отличаться от ответственного")
    category = Category(
        name=body.name.strip(),
        department_id=body.department_id,
        responsible_id=body.responsible_id,
        deputy_id=body.deputy_id,
        is_active=True,
    )
    session.add(category)
    await session.flush()
    return _category_out(category, await Directory.load(session))


@router.patch("/categories/{category_id}", response_model=CategoryOut, summary="Изменить категорию")
async def update_category(category_id: int, body: CategoryUpdate, _: AdminDep, session: SessionDep) -> CategoryOut:
    category = await session.get(Category, category_id)
    if category is None:
        raise NotFound("Категория не найдена")
    data = body.model_dump(exclude_unset=True)
    if data.get("name"):
        await _unique(session, Category, data["name"], category.id)
        category.name = data["name"].strip()
    if data.get("department_id") is not None:
        await _department(session, data["department_id"])
        category.department_id = data["department_id"]
    for field in ("responsible_id", "deputy_id"):
        if field in data:
            await _assignable(session, data[field], field)
            setattr(category, field, data[field])
    if category.deputy_id is not None and category.deputy_id == category.responsible_id:
        raise field_error("deputy_id", "Заместитель должен отличаться от ответственного")
    if data.get("is_active") is not None:
        category.is_active = data["is_active"]
    return _category_out(category, await Directory.load(session))


# --- сроки и общие настройки ---------------------------------------------------------------------------


async def _rules(session: AsyncSession) -> list[DeadlineRuleOut]:
    rows = {r.priority: r.business_days for r in (await session.execute(select(DeadlineRule))).scalars()}
    defaults = {"high": 1, "medium": 3, "low": 5}
    return [DeadlineRuleOut(priority=p, business_days=rows.get(p.value, defaults[p.value])) for p in Priority]


@router.get("/deadline-rules", response_model=list[DeadlineRuleOut], summary="Сроки первого ответа")
async def get_rules(_: AdminDep, session: SessionDep) -> list[DeadlineRuleOut]:
    return await _rules(session)


@router.put("/deadline-rules", response_model=list[DeadlineRuleOut], summary="Изменить сроки первого ответа")
async def put_rules(
    body: Annotated[list[DeadlineRuleOut], Field(min_length=1, max_length=3)], _: AdminDep, session: SessionDep
) -> list[DeadlineRuleOut]:
    if len({r.priority for r in body}) != len(body):
        raise field_error("priority", "Каждый приоритет — один раз")
    for rule in body:
        row = await session.get(DeadlineRule, rule.priority.value)
        if row is None:
            session.add(DeadlineRule(priority=rule.priority.value, business_days=rule.business_days))
        else:
            row.business_days = rule.business_days
    await session.flush()
    return await _rules(session)


async def _settings_out(session: AsyncSession, settings) -> SettingsOut:
    row = await session.get(SystemSetting, "digest_time")
    return SettingsOut(digest_time=row.value if row else settings.digest_time.strftime("%H:%M"), timezone=settings.timezone)


@router.get("/settings", response_model=SettingsOut, summary="Общие настройки")
async def get_settings_(_: AdminDep, session: SessionDep, settings: SettingsDep) -> SettingsOut:
    return await _settings_out(session, settings)


@router.patch("/settings", response_model=SettingsOut, summary="Время утренней сводки")
async def patch_settings(body: SettingsUpdate, _: AdminDep, session: SessionDep, settings: SettingsDep) -> SettingsOut:
    if body.digest_time is not None:
        row = await session.get(SystemSetting, "digest_time")
        if row is None:
            session.add(SystemSetting(key="digest_time", value=body.digest_time))
        else:
            row.value = body.digest_time
        await session.flush()
    return await _settings_out(session, settings)
