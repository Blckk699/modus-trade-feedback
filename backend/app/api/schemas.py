"""Общие схемы ответов, совпадающие с `components/schemas` контракта."""

from __future__ import annotations

from pydantic import BaseModel

from app.domain.enums import Role


class DepartmentRef(BaseModel):
    id: int
    name: str


class CategoryRef(BaseModel):
    id: int
    name: str


class UserBrief(BaseModel):
    id: int
    full_name: str
    role: Role
    department: DepartmentRef | None


class UserOut(BaseModel):
    id: int
    telegram_id: int | None
    # Почта для входа — как telegram_id, только администратору и самому пользователю.
    email: str | None = None
    full_name: str
    position: str | None
    role: Role
    department: DepartmentRef | None
    is_absent: bool
    is_disabled: bool
