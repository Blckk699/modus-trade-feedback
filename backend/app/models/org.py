"""Оргструктура и настройки: пользователи, подразделения, категории, сроки, общие настройки."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import BigInteger, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class User(Base):
    """Сотрудник. Входит по почте и паролю или через Telegram; нужен хотя бы один способ и включённый доступ."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    telegram_id: Mapped[int | None] = mapped_column(BigInteger, unique=True)
    # Почта хранится в нижнем регистре — уникальна без учёта регистра.
    email: Mapped[str | None] = mapped_column(String(254), unique=True)
    password_hash: Mapped[str | None] = mapped_column(String(255))
    # ID сотрудника на портале Битрикс24: запоминается при первом входе через портал.
    bitrix_user_id: Mapped[int | None] = mapped_column(BigInteger, unique=True)
    # Временный пароль от администратора: при входе с ним нужно задать новый.
    must_change_password: Mapped[bool] = mapped_column(default=False)
    # Группа связанных аккаунтов (демо-переключатель ролей): участники одной группы переключаются друг на друга.
    # Задаётся только настройкой вне репозитория (`python -m app.seed link`), через API не меняется.
    switch_group: Mapped[str | None] = mapped_column(String(50), index=True)
    full_name: Mapped[str] = mapped_column(String(200))
    position: Mapped[str | None] = mapped_column(String(200))
    role: Mapped[str] = mapped_column(String(20))  # app.domain.enums.Role
    department_id: Mapped[int | None] = mapped_column(ForeignKey("departments.id", use_alter=True))
    is_absent: Mapped[bool] = mapped_column(default=False)
    is_disabled: Mapped[bool] = mapped_column(default=False)
    # Ключ демо-пользователя из сида: по нему файл аккаунтов вне репозитория задаёт Telegram ID.
    seed_key: Mapped[str | None] = mapped_column(String(50), unique=True)
    created_at: Mapped[datetime]


class Department(Base):
    __tablename__ = "departments"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200), unique=True)
    head_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", use_alter=True))


class Category(Base):
    """Категория обращений: правило маршрутизации — ответственный и заместитель."""

    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200), unique=True)
    department_id: Mapped[int] = mapped_column(ForeignKey("departments.id"))
    responsible_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    deputy_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    is_active: Mapped[bool] = mapped_column(default=True)


class DeadlineRule(Base):
    """Срок первого ответа по приоритету, в рабочих днях."""

    __tablename__ = "deadline_rules"

    priority: Mapped[str] = mapped_column(String(20), primary_key=True)  # Priority
    business_days: Mapped[int]


class SystemSetting(Base):
    """Настройки, которые меняет администратор (например, `digest_time`). Значение — строка."""

    __tablename__ = "system_settings"

    key: Mapped[str] = mapped_column(String(50), primary_key=True)
    value: Mapped[str] = mapped_column(String(200))
