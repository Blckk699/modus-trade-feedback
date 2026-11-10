"""Подписи перечислений и таблица переходов (B-18). Статичные справочники, вход не нужен.

Клиенты берут отсюда подписи. Доступность действий — только по `Appeal.allowed_actions`.
"""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel, ConfigDict, Field

from app.api.deps import SettingsDep
from app.domain.enums import AppealAction, AppealSource, AppealStatus, AppealType, Priority, Role

router = APIRouter(tags=["dictionaries"])

APPEAL_TYPES = {AppealType.PROBLEM: "Проблема", AppealType.SUGGESTION: "Предложение", AppealType.PRAISE: "Положительный отзыв"}
PRIORITIES = {Priority.HIGH: "Высокий", Priority.MEDIUM: "Средний", Priority.LOW: "Низкий"}
STATUSES = {
    AppealStatus.NEW: "Новое",
    AppealStatus.IN_REVIEW: "На рассмотрении",
    AppealStatus.AWAITING_INFO: "Ожидает уточнения",
    AppealStatus.IN_PROGRESS: "В работе",
    AppealStatus.IMPLEMENTED: "Реализовано",
    AppealStatus.REJECTED: "Отклонено",
    AppealStatus.CLOSED: "Закрыто",
}
ROLES = {Role.EMPLOYEE: "Сотрудник", Role.HEAD: "Руководитель подразделения", Role.ADMIN: "Администратор", Role.OWNER: "Собственник"}
SOURCES = {AppealSource.BOT: "Бот", AppealSource.FORM: "Форма", AppealSource.MEETING: "Совещание"}
DUE_FILTERS = {"overdue": "Просрочено", "due_today": "Срок сегодня", "due_week": "Срок на этой неделе", "no_deadline": "Без срока"}

_NEW, _REVIEW, _INFO, _WORK = AppealStatus.NEW, AppealStatus.IN_REVIEW, AppealStatus.AWAITING_INFO, AppealStatus.IN_PROGRESS
_NOT_FINAL = [_NEW, _REVIEW, _INFO, _WORK]
ACTIONS: dict[AppealAction, tuple[str, list[AppealStatus], AppealStatus | None]] = {
    AppealAction.TAKE: ("Взять на рассмотрение", [_NEW], _REVIEW),
    AppealAction.REQUEST_INFO: ("Задать уточняющий вопрос", [_REVIEW], _INFO),
    AppealAction.REPLY_CLARIFICATION: ("Ответить на вопрос", [_INFO], _REVIEW),
    AppealAction.START_WORK: ("В работу", [_REVIEW], _WORK),
    AppealAction.REJECT: ("Отклонить", [_REVIEW], AppealStatus.REJECTED),
    AppealAction.IMPLEMENT: ("Реализовано", [_WORK], AppealStatus.IMPLEMENTED),
    AppealAction.ACCEPT_FEEDBACK: ("Принять отзыв", [_NEW], AppealStatus.CLOSED),
    AppealAction.MERGE: ("Присоединить к основному", [_NEW, _REVIEW], AppealStatus.CLOSED),
    AppealAction.REASSIGN: ("Переназначить", _NOT_FINAL, None),
    AppealAction.PUBLISH_DISCUSSION: ("Вынести на обсуждение", [*_NOT_FINAL, AppealStatus.IMPLEMENTED, AppealStatus.REJECTED], None),
    AppealAction.CREATE_BITRIX_TASK: ("Создать задачу в Битрикс24", [_REVIEW, _INFO, _WORK], None),
    AppealAction.SEND_MESSAGE: ("Написать в переписку", _NOT_FINAL, None),
    AppealAction.UPLOAD_ATTACHMENT: ("Приложить файл", _NOT_FINAL, None),
}


class LabeledCode(BaseModel):
    code: str
    label: str


class StatusLabel(LabeledCode):
    is_final: bool


class ActionLabel(LabeledCode):
    model_config = ConfigDict(populate_by_name=True)

    from_statuses: list[AppealStatus] = Field(serialization_alias="from")
    to: AppealStatus | None


class Dictionaries(BaseModel):
    appeal_types: list[LabeledCode]
    priorities: list[LabeledCode]
    statuses: list[StatusLabel]
    roles: list[LabeledCode]
    sources: list[LabeledCode]
    actions: list[ActionLabel]
    due_filters: list[LabeledCode]
    timezone: str


def _labeled(labels: dict) -> list[LabeledCode]:
    return [LabeledCode(code=str(code), label=label) for code, label in labels.items()]


@router.get("/dictionaries", response_model=Dictionaries, response_model_by_alias=True, summary="Подписи перечислений и таблица переходов")
async def get_dictionaries(settings: SettingsDep) -> Dictionaries:
    return Dictionaries(
        appeal_types=_labeled(APPEAL_TYPES),
        priorities=_labeled(PRIORITIES),
        statuses=[StatusLabel(code=str(status), label=label, is_final=status.is_final) for status, label in STATUSES.items()],
        roles=_labeled(ROLES),
        sources=_labeled(SOURCES),
        actions=[
            ActionLabel(code=str(action), label=label, from_statuses=sources, to=target)
            for action, (label, sources, target) in ACTIONS.items()
        ],
        due_filters=_labeled(DUE_FILTERS),
        timezone=settings.timezone,
    )
