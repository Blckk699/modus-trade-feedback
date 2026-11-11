"""Все модели приложения. Alembic и тесты импортируют этот модуль, чтобы увидеть полную схему.

Новая модель — добавьте её импорт сюда.
"""

from app.auth.models import AuthSession, LoginAttempt, LoginCode
from app.db import Base
from app.jobs.models import Job, PeriodicTask
from app.models.access import AccessRequest, AccessSubmission, Invite
from app.models.appeals import (
    Appeal,
    AppealParticipant,
    Attachment,
    BitrixTask,
    DuplicateSuggestion,
    HistoryEvent,
    Message,
)
from app.models.discussions import Discussion, DiscussionComment, DiscussionVote
from app.models.meetings import Meeting, MeetingDraft
from app.models.notifications import Notification
from app.models.org import Category, DeadlineRule, Department, SystemSetting, User

__all__ = [
    "AccessRequest",
    "AccessSubmission",
    "Appeal",
    "AppealParticipant",
    "Attachment",
    "AuthSession",
    "Base",
    "BitrixTask",
    "Category",
    "DeadlineRule",
    "Department",
    "Discussion",
    "DiscussionComment",
    "DiscussionVote",
    "DuplicateSuggestion",
    "HistoryEvent",
    "Invite",
    "Job",
    "LoginAttempt",
    "LoginCode",
    "Meeting",
    "MeetingDraft",
    "Message",
    "Notification",
    "PeriodicTask",
    "SystemSetting",
    "User",
]
