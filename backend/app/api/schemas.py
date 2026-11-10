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
    full_name: str
    position: str | None
    role: Role
    department: DepartmentRef | None
    is_absent: bool
    is_disabled: bool
