"""Кто видит обращение и какие действия ему доступны. Единственное место этих правил (SPEC.md, матрица доступа).

Видимость: сотрудник — свои (автор или участник склеенного повтора), ответственный — назначенные,
руководитель — обращения категорий своего подразделения, администратор и собственник — все.
Руководитель и собственник могут выполнить любое действие ответственного, ответственный при этом
не меняется. Администратор не меняет статусы, не склеивает, не видит приватную переписку.
"""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import ColumnElement, or_, select, true

from app.domain.enums import AppealAction, AppealStatus, AppealType, Role, ViewerRelation
from app.models import Appeal, AppealParticipant, Category, Department, User

NOT_FINAL = (AppealStatus.NEW, AppealStatus.IN_REVIEW, AppealStatus.AWAITING_INFO, AppealStatus.IN_PROGRESS)


@dataclass(frozen=True)
class AppealFacts:
    """То, что нужно правилам об обращении, без загрузки связанных объектов."""

    author_id: int
    assignee_id: int | None
    department_id: int | None  # подразделение категории
    status: AppealStatus
    type: AppealType
    is_participant: bool
    # Пользователь — руководитель подразделения этого обращения (Department.head_id).
    viewer_heads_department: bool = False
    has_discussion: bool = False
    has_bitrix_task: bool = False


def relations(user: User, appeal: AppealFacts) -> list[ViewerRelation]:
    out: list[ViewerRelation] = []
    if appeal.author_id == user.id:
        out.append(ViewerRelation.AUTHOR)
    elif appeal.is_participant:
        out.append(ViewerRelation.PARTICIPANT)
    # Администратор не ответственный, даже если остался им в закрытых обращениях до смены роли.
    if appeal.assignee_id == user.id and user.role != Role.ADMIN:
        out.append(ViewerRelation.ASSIGNEE)
    if appeal.viewer_heads_department:
        out.append(ViewerRelation.DEPARTMENT_HEAD)
    if user.role == Role.OWNER:
        out.append(ViewerRelation.OWNER)
    if user.role == Role.ADMIN:
        out.append(ViewerRelation.ADMIN)
    return out


def full_access(rel: list[ViewerRelation]) -> bool:
    """Участник склеенного повтора видит основное обращение без чужого текста и имени."""
    return bool(rel) and rel != [ViewerRelation.PARTICIPANT]


def can_process(rel: list[ViewerRelation]) -> bool:
    """Действия ответственного: сам ответственный, руководитель подразделения, собственник."""
    return any(r in rel for r in (ViewerRelation.ASSIGNEE, ViewerRelation.DEPARTMENT_HEAD, ViewerRelation.OWNER))


def can_reassign(rel: list[ViewerRelation]) -> bool:
    return any(r in rel for r in (ViewerRelation.DEPARTMENT_HEAD, ViewerRelation.ADMIN, ViewerRelation.OWNER))


def can_close_discussion(rel: list[ViewerRelation]) -> bool:
    """Итог обсуждения фиксирует руководитель подразделения обращения или собственник, не ответственный."""
    return any(r in rel for r in (ViewerRelation.DEPARTMENT_HEAD, ViewerRelation.OWNER))


def can_read_messages(rel: list[ViewerRelation]) -> bool:
    """Приватная переписка: автор, ответственный, руководитель, собственник. Не администратор, не участник."""
    return ViewerRelation.AUTHOR in rel or can_process(rel)


def allowed_actions(user: User, appeal: AppealFacts) -> list[AppealAction]:
    rel = relations(user, appeal)
    if not full_access(rel):
        return []
    status, praise = appeal.status, appeal.type == AppealType.PRAISE
    process = can_process(rel)
    is_author = ViewerRelation.AUTHOR in rel
    actions: list[AppealAction] = []

    def add(action: AppealAction, condition: bool) -> None:
        if condition:
            actions.append(action)

    add(AppealAction.TAKE, process and status == AppealStatus.NEW and not praise)
    add(AppealAction.REQUEST_INFO, process and status == AppealStatus.IN_REVIEW)
    add(AppealAction.REPLY_CLARIFICATION, is_author and status == AppealStatus.AWAITING_INFO)
    add(AppealAction.START_WORK, process and status == AppealStatus.IN_REVIEW)
    add(AppealAction.REJECT, process and status == AppealStatus.IN_REVIEW)
    add(AppealAction.IMPLEMENT, process and status == AppealStatus.IN_PROGRESS)
    add(AppealAction.ACCEPT_FEEDBACK, process and status == AppealStatus.NEW and praise)
    add(AppealAction.MERGE, process and status in (AppealStatus.NEW, AppealStatus.IN_REVIEW) and not praise)
    add(AppealAction.REASSIGN, can_reassign(rel) and status in NOT_FINAL)
    add(AppealAction.PUBLISH_DISCUSSION, process and status != AppealStatus.CLOSED and not appeal.has_discussion)
    add(
        AppealAction.CREATE_BITRIX_TASK,
        process
        and status in (AppealStatus.IN_REVIEW, AppealStatus.AWAITING_INFO, AppealStatus.IN_PROGRESS)
        and not appeal.has_bitrix_task,
    )
    add(AppealAction.SEND_MESSAGE, (is_author or process) and status in NOT_FINAL)
    add(AppealAction.UPLOAD_ATTACHMENT, (is_author or process) and status in NOT_FINAL)
    return actions


def headed_departments(user: User):
    """Подразделения, которыми пользователь руководит: зона руководителя — по `Department.head_id`."""
    return select(Department.id).where(Department.head_id == user.id)


def full_visible_filter(user: User) -> ColumnElement[bool]:
    """Обращения, которые пользователь видит полностью (без «участник склеенного повтора»)."""
    if user.role in (Role.ADMIN, Role.OWNER):
        return true()
    own_categories = select(Category.id).where(Category.department_id.in_(headed_departments(user)))
    return or_(Appeal.author_id == user.id, Appeal.assignee_id == user.id, Appeal.category_id.in_(own_categories))


def suggestion_zone_filter(user: User) -> ColumnElement[bool]:
    """Где показывать подсказки о повторах: назначенные пользователю, его подразделение, для собственника — всё."""
    if user.role == Role.OWNER:
        return true()
    own_categories = select(Category.id).where(Category.department_id.in_(headed_departments(user)))
    return or_(Appeal.assignee_id == user.id, Appeal.category_id.in_(own_categories))


def visible_filter(user: User) -> ColumnElement[bool]:
    """Условие SQL «пользователь видит обращение» — то же правило, что `relations`, для списков."""
    if user.role in (Role.ADMIN, Role.OWNER):
        return true()
    participant = select(AppealParticipant.appeal_id).where(AppealParticipant.user_id == user.id)
    return or_(full_visible_filter(user), Appeal.id.in_(participant))
