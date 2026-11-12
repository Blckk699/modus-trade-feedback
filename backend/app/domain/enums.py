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
    ATTACHMENT_REMOVED = "attachment_removed"
    DISCUSSION_PUBLISHED = "discussion_published"
    DISCUSSION_CLOSED = "discussion_closed"
    BITRIX_TASK_CREATED = "bitrix_task_created"
    FIELD_CHANGED = "field_changed"


class AppealAction(StrEnum):
    TAKE = "take"
    REQUEST_INFO = "request_info"
    REPLY_CLARIFICATION = "reply_clarification"
    START_WORK = "start_work"
    REJECT = "reject"
    IMPLEMENT = "implement"
    ACCEPT_FEEDBACK = "accept_feedback"
    MERGE = "merge"
    REASSIGN = "reassign"
    PUBLISH_DISCUSSION = "publish_discussion"
    CREATE_BITRIX_TASK = "create_bitrix_task"
    SEND_MESSAGE = "send_message"
    UPLOAD_ATTACHMENT = "upload_attachment"


class ViewerRelation(StrEnum):
    AUTHOR = "author"
    PARTICIPANT = "participant"
    ASSIGNEE = "assignee"
    DEPARTMENT_HEAD = "department_head"
    OWNER = "owner"
    ADMIN = "admin"


class DueState(StrEnum):
    ON_TIME = "on_time"
    DUE_SOON = "due_soon"
    OVERDUE = "overdue"
    ANSWERED = "answered"
    NO_DEADLINE = "no_deadline"


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
    ACCESS_REQUEST_CREATED = "access_request_created"
    ACCESS_REQUEST_APPROVED = "access_request_approved"
    ACCESS_REQUEST_REJECTED = "access_request_rejected"
