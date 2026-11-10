"""Все модели приложения. Alembic и тесты импортируют этот модуль, чтобы увидеть полную схему.

Новая модель — добавьте её импорт сюда.
"""

from app.db import Base
from app.jobs.models import Job, PeriodicTask

__all__ = ["Base", "Job", "PeriodicTask"]
