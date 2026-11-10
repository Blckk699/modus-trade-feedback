"""Перечисления домена. Коды совпадают с контрактом `contract/openapi.yaml`."""

from __future__ import annotations

from enum import StrEnum


class Role(StrEnum):
    EMPLOYEE = "employee"
    HEAD = "head"
    ADMIN = "admin"
    OWNER = "owner"


class AppealType(StrEnum):
    PROBLEM = "problem"
    SUGGESTION = "suggestion"
    PRAISE = "praise"


class Priority(StrEnum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class AppealStatus(StrEnum):
    NEW = "new"
    IN_REVIEW = "in_review"
    AWAITING_INFO = "awaiting_info"
    IN_PROGRESS = "in_progress"
    IMPLEMENTED = "implemented"
    REJECTED = "rejected"
    CLOSED = "closed"

    @property
    def is_final(self) -> bool:
        return self in FINAL_STATUSES


FINAL_STATUSES = frozenset({AppealStatus.IMPLEMENTED, AppealStatus.REJECTED, AppealStatus.CLOSED})


class AppealSource(StrEnum):
    BOT = "bot"
    FORM = "form"
    MEETING = "meeting"


class ClosedReason(StrEnum):
    FEEDBACK_ACCEPTED = "feedback_accepted"
    MERGED = "merged"


class HistoryKind(StrEnum):
    CREATED = "created"
    ASSIGNED = "assigned"
    REASSIGNED = "reassigned"
    STATUS_CHANGED = "status_changed"
    DEADLINE_SET = "deadline_set"
    CLARIFICATION_REQUESTED = "clarification_requested"
    CLARIFICATION_ANSWERED = "clarification_answered"
    ESCALATED = "escalated"
    MERGED = "merged"
    PARTICIPANT_ADDED = "participant_added"
    ATTACHMENT_ADDED = "attachment_added"
    DISCUSSION_PUBLISHED = "discussion_published"
    DISCUSSION_CLOSED = "discussion_closed"
    BITRIX_TASK_CREATED = "bitrix_task_created"
    FIELD_CHANGED = "field_changed"


class DiscussionStatus(StrEnum):
    OPEN = "open"
    CLOSED = "closed"


class VoteValue(StrEnum):
    FOR = "for"
    AGAINST = "against"


class NameConsent(StrEnum):
    PENDING = "pending"
    SHOWN = "shown"
    HIDDEN = "hidden"


class MeetingStatus(StrEnum):
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"


class MeetingDraftStatus(StrEnum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    DISCARDED = "discarded"


class NotificationKind(StrEnum):
    APPEAL_ASSIGNED = "appeal_assigned"
    APPEAL_CREATED = "appeal_created"
    STATUS_CHANGED = "status_changed"
    CLARIFICATION_REQUESTED = "clarification_requested"
    CLARIFICATION_ANSWERED = "clarification_answered"
    MESSAGE_RECEIVED = "message_received"
    DEADLINE_REMINDER = "deadline_reminder"
    ESCALATION_HEAD = "escalation_head"
    APPEAL_MERGED = "appeal_merged"
    NAME_CONSENT_REQUEST = "name_consent_request"
    DISCUSSION_CLOSED = "discussion_closed"
    DIGEST = "digest"
