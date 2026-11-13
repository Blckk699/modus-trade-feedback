"""Витрина для показа: то, что иначе на экранах появилось бы только по ходу демо.

Открытое обсуждение с голосами, склеенные повторы с участниками и разобранная запись совещания.
Загружается командой `app.seed` поверх двадцати обращений из датасета. Данные только синтетические.
Тесты по умолчанию работают без витрины, чтобы числа сида считались от датасета.
"""

from __future__ import annotations

from datetime import datetime, timedelta, tzinfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.business_days import add_business_days
from app.domain.enums import (
    AppealSource,
    AppealStatus,
    AppealType,
    ClosedReason,
    DiscussionStatus,
    HistoryKind,
    MeetingDraftStatus,
    MeetingStatus,
    NameConsent,
    Priority,
    VoteValue,
)
from app.models import (
    Appeal,
    AppealParticipant,
    Category,
    Discussion,
    DiscussionComment,
    DiscussionVote,
    HistoryEvent,
    Meeting,
    MeetingDraft,
    User,
)
from app.seed.showcase_more import add_more

DISCUSSED_APPEAL = "A-012"
MAIN_APPEAL = "A-003"

DISCUSSION_TEXT = "Договориться об одном месте, где фиксируются итоговые решения по задаче?"
VOTES = {
    "employee_procurement": VoteValue.FOR,
    "employee_accounting": VoteValue.FOR,
    "employee_design": VoteValue.FOR,
    "employee_pmo": VoteValue.AGAINST,
    "head_procurement": VoteValue.FOR,
}
COMMENTS = {
    "employee_accounting": "Поддерживаю: итог легко потерять, когда переписка идёт в нескольких чатах.",
    "employee_pmo": "Только без отдельного инструмента, иначе добавится ещё одно место, куда надо заходить.",
}

# Те же жалобы, что и основное обращение, от других сотрудников.
DUPLICATES = [
    ("employee_procurement", "В спецификациях одно изделие называют по-разному, приходится сверять вручную.", "Разные названия изделия в спецификациях"),
    ("employee_pm", "На проектах теряем время: одна позиция в документах записана под разными обозначениями.", "Одна позиция под разными обозначениями"),
]

MEETING_TITLE = "Планёрка закупок"
MEETING_TRANSCRIPT = (
    "Марат: давайте по задержкам. Поставщик снова прислал спецификацию на три дня позже срока, и заявка встала.\n"
    "Айгерим: и согласование договоров длится дольше, потому что непонятно, кто подписывает при отсутствии руководителя.\n"
    "Марат: ещё предлагаю завести общий список проверенных поставщиков, чтобы не искать каждый раз заново."
)
MEETING_DRAFTS = [
    (
        AppealType.PROBLEM, "Межотдельное взаимодействие", Priority.HIGH,
        "Поставщик присылает спецификации позже срока",
        "Поставщик снова прислал спецификацию на три дня позже срока",
    ),
    (
        AppealType.PROBLEM, "Договорная работа", Priority.MEDIUM,
        "Неясно, кто подписывает договор при отсутствии руководителя",
        "непонятно, кто подписывает при отсутствии руководителя",
    ),
    (
        AppealType.SUGGESTION, "Прозрачность результатов", Priority.LOW,
        "Общий список проверенных поставщиков",
        "предлагаю завести общий список проверенных поставщиков",
    ),
]


def _between(start: datetime, end: datetime) -> datetime:
    return start + (end - start) / 2


async def _users(session: AsyncSession) -> dict[str, User]:
    return {u.seed_key: u for u in await session.scalars(select(User)) if u.seed_key}


async def _appeal(session: AsyncSession, number: str) -> Appeal:
    return (await session.scalars(select(Appeal).where(Appeal.number == number))).one()


async def _add_discussion(session: AsyncSession, users: dict[str, User], now: datetime, tz: tzinfo) -> None:
    appeal = await _appeal(session, DISCUSSED_APPEAL)
    published = _between(appeal.updated_at, now)
    discussion = Discussion(
        appeal_id=appeal.id,
        public_text=DISCUSSION_TEXT,
        deadline=add_business_days(now, 3, tz),
        status=DiscussionStatus.OPEN,
        author_name_consent=NameConsent.SHOWN,
        created_by_id=appeal.assignee_id,
        created_at=published,
    )
    session.add(discussion)
    await session.flush()
    session.add(
        HistoryEvent(appeal_id=appeal.id, actor_id=appeal.assignee_id, kind=HistoryKind.DISCUSSION_PUBLISHED, comment=DISCUSSION_TEXT, created_at=published)
    )
    voted = _between(published, now)
    for key, value in VOTES.items():
        session.add(DiscussionVote(discussion_id=discussion.id, user_id=users[key].id, value=value, updated_at=voted))
    for key, text in COMMENTS.items():
        session.add(DiscussionComment(discussion_id=discussion.id, author_id=users[key].id, text=text, created_at=voted))
    appeal.updated_at = published


async def _add_duplicates(session: AsyncSession, users: dict[str, User], tz: tzinfo) -> None:
    main = await _appeal(session, MAIN_APPEAL)
    merged_at = main.first_response_at + timedelta(hours=1)
    for offset, (author_key, text, summary) in enumerate(DUPLICATES):
        created = merged_at - timedelta(minutes=40 - offset * 10)
        duplicate = Appeal(
            number=f"A-{21 + offset:03d}",
            type=AppealType.PROBLEM,
            category_id=main.category_id,
            priority=Priority.MEDIUM,
            status=AppealStatus.CLOSED,
            author_id=users[author_key].id,
            assignee_id=main.assignee_id,
            text=text,
            summary=summary,
            source=AppealSource.BOT,
            first_response_due_at=add_business_days(created, 3, tz),
            escalation_level=0,
            closed_reason=ClosedReason.MERGED,
            merged_into_id=main.id,
            created_at=created,
            updated_at=merged_at,
        )
        session.add(duplicate)
        await session.flush()
        comment = f"Присоединено к {main.number}"
        session.add_all(
            [
                HistoryEvent(appeal_id=duplicate.id, actor_id=users[author_key].id, kind=HistoryKind.CREATED, comment="Подано через бота", created_at=created),
                HistoryEvent(
                    appeal_id=duplicate.id, actor_id=main.assignee_id, kind=HistoryKind.STATUS_CHANGED, field="status",
                    old_value=AppealStatus.NEW, new_value=AppealStatus.CLOSED, created_at=merged_at,
                ),
                HistoryEvent(appeal_id=duplicate.id, actor_id=main.assignee_id, kind=HistoryKind.MERGED, new_value=main.number, comment=comment, created_at=merged_at),
                HistoryEvent(appeal_id=main.id, actor_id=main.assignee_id, kind=HistoryKind.PARTICIPANT_ADDED, comment=f"Присоединён повтор {duplicate.number}", created_at=merged_at),
                AppealParticipant(appeal_id=main.id, user_id=users[author_key].id, via_appeal_id=duplicate.id, added_at=merged_at),
            ]
        )


async def _add_meeting(session: AsyncSession, users: dict[str, User], now: datetime) -> None:
    created = now - timedelta(hours=2)
    meeting = Meeting(
        title=MEETING_TITLE,
        status=MeetingStatus.READY,
        filename="planerka.mp3",
        content_type="audio/mpeg",
        storage_key="meetings/demo-showcase",  # запись уже разобрана, файл не читается
        transcript=MEETING_TRANSCRIPT,
        uploaded_by_id=users["head_procurement"].id,
        created_at=created,
    )
    session.add(meeting)
    await session.flush()
    categories = {c.name: c.id for c in await session.scalars(select(Category))}
    for kind, category, priority, summary, quote in MEETING_DRAFTS:
        session.add(
            MeetingDraft(
                meeting_id=meeting.id,
                status=MeetingDraftStatus.PENDING,
                type=kind,
                category_id=categories[category],
                priority=priority,
                summary=summary,
                text=f"{summary}\n\nЦитата из совещания: {quote}",
                quote=quote,
                created_at=created,
            )
        )


async def add_showcase(session: AsyncSession, now: datetime, tz: tzinfo) -> None:
    users = await _users(session)
    await _add_discussion(session, users, now, tz)
    await _add_duplicates(session, users, tz)
    await _add_meeting(session, users, now)
    await session.flush()
    await add_more(session, now, tz)
