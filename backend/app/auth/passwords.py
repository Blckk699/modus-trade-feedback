"""Пароли и почта: хеш argon2, временный пароль, нормализация почты.

Пароль хранится только хешем и нигде не логируется: ни в ответах, ни в текстах ошибок.
"""

from __future__ import annotations

import re
import secrets

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

from app.errors import ValidationFailed

_hasher = PasswordHasher()
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str | None) -> bool:
    if not password_hash:
        return False
    try:
        return _hasher.verify(password_hash, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def temporary_password() -> str:
    """Временный пароль для сброса администратором: 12 символов, показывается один раз."""
    return "Tmp-" + secrets.token_urlsafe(9)[:12]


def normalize_email(value: str, field: str = "email") -> str:
    """Почта в нижнем регистре без пробелов. Письмом не подтверждается — проверяем только вид."""
    email = value.strip().lower()
    if len(email) > 254 or not EMAIL_RE.match(email):
        raise ValidationFailed(
            "Проверьте почту", details={"fields": [{"field": field, "message": "Укажите почту вида name@company.kz"}]}
        )
    return email
