"""Список модулей с обработчиками фоновых задач.

Импорт модуля регистрирует его обработчики в `app.jobs.registry.registry`.
Новый модуль с задачами (эскалация, сводка, совещания) — добавьте строку импорта сюда.
"""

from app.appeals import escalation  # noqa: F401
from app.jobs import builtin  # noqa: F401
from app.meetings import router as meetings  # noqa: F401
