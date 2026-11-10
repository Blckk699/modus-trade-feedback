"""Схемы обращений — как `AppealCreate`, `AppealListItem`, `Appeal`, `HistoryEvent`, `Attachment` в контракте."""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from app.api.schemas import CategoryRef, DepartmentRef, UserBrief
from app.domain.enums import (
    AppealAction,
    AppealSource,
    AppealStatus,
    AppealType,
    ClosedReason,
    DiscussionStatus,
    DueState,
    Priority,
    ViewerRelation,
)


class AppealCreate(BaseModel):
    type: AppealType
    category_id: int | None = None
    priority: Priority
    text: str = Field(min_length=1, max_length=20_000)
    summary: str | None = Field(default=None, max_length=500)
    proposed_solution: str | None = Field(default=None, max_length=20_000)
    source: Literal["form", "bot"] = "form"
    forwarded_from: str | None = Field(default=None, max_length=300)


class AppealRef(BaseModel):
    id: int
    number: str
    summary: str | None
    status: AppealStatus
    type: AppealType


class BitrixTaskOut(BaseModel):
    task_id: str
    url: str
    created_at: datetime


class DiscussionRef(BaseModel):
    id: int
    status: DiscussionStatus


class AttachmentOut(BaseModel):
    id: int
    appeal_id: int
    filename: str
    content_type: str
    size_bytes: int
    download_url: str
    uploaded_by: UserBrief
    created_at: datetime


class AppealListItem(BaseModel):
    id: int
    number: str
    type: AppealType
    category: CategoryRef | None
    department: DepartmentRef | None
    priority: Priority
    status: AppealStatus
    summary: str | None
    author: UserBrief | None
    assignee: UserBrief | None
    source: AppealSource
    first_response_due_at: datetime | None
    due_state: DueState
    escalation_level: int
    participants_count: int
    merged_into: AppealRef | None
    access: Literal["full", "participant"]
    has_unread: bool
    created_at: datetime
    updated_at: datetime


class AppealOut(AppealListItem):
    text: str | None
    proposed_solution: str | None
    first_response_at: datetime | None
    decision: str | None
    rejection_reason: str | None
    result: str | None
    public_summary: str | None
    public_result: str | None
    forwarded_from: str | None
    closed_reason: ClosedReason | None
    bitrix_task: BitrixTaskOut | None
    discussion: DiscussionRef | None
    attachments: list[AttachmentOut]
    viewer_relations: list[ViewerRelation]
    allowed_actions: list[AppealAction]


class AppealPage(BaseModel):
    items: list[AppealListItem]
    total: int
    page: int
    page_size: int


class HistoryEventOut(BaseModel):
    id: int
    appeal_id: int
    kind: str
    actor: UserBrief | None
    field: str | None
    old_value: str | None
    new_value: str | None
    comment: str | None
    created_at: datetime
