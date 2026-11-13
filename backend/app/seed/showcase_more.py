"""Витрина, часть вторая: обращения, на которых видно всё, что умеет система.

Живая переписка автора с ответственным, уточняющие вопросы, переназначения с причиной, эскалация просрочки,
смена категории, задачи в Битрикс24, закрытое обсуждение с итогом, благодарности, все статусы и все
подразделения. Данные только синтетические: дистрибьютор систем безопасности, вымышленные сотрудники сида.
Загружается вместе с `app.seed.showcase` и в тестах по умолчанию отключена.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, tzinfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.appeals.escalation import due_level
from app.domain.business_days import add_business_days
from app.domain.enums import (
    AppealSource,
    AppealStatus,
    AppealType,
    ClosedReason,
    DiscussionStatus,
    HistoryKind,
    NameConsent,
    Priority,
    VoteValue,
)
from app.models import (
    Appeal,
    BitrixTask,
    Category,
    Discussion,
    DiscussionComment,
    DiscussionVote,
    HistoryEvent,
    Message,
    User,
)

FIRST_NUMBER = 23  # A-001…A-020 — датасет, A-021 и A-022 — склеенные повторы первой части витрины
DEADLINE_DAYS = {Priority.HIGH: 1, Priority.MEDIUM: 3, Priority.LOW: 5}
ESCALATION_COMMENTS = {
    1: "Срок первого ответа истёк: напоминание ответственному",
    2: "Ответа нет рабочий день после срока: сообщили руководителю подразделения",
    3: "Ответа нет два рабочих дня после срока: обращение зависло, попадёт в сводку собственника",
}
BITRIX_URL = "https://modus-demo.bitrix24.kz/company/personal/user/1/tasks/task/view/{}/"

PROBLEM, SUGGESTION, PRAISE = AppealType.PROBLEM, AppealType.SUGGESTION, AppealType.PRAISE
HIGH, MEDIUM, LOW = Priority.HIGH, Priority.MEDIUM, Priority.LOW
NEW, IN_REVIEW, AWAITING, IN_PROGRESS = AppealStatus.NEW, AppealStatus.IN_REVIEW, AppealStatus.AWAITING_INFO, AppealStatus.IN_PROGRESS
IMPLEMENTED, REJECTED, CLOSED = AppealStatus.IMPLEMENTED, AppealStatus.REJECTED, AppealStatus.CLOSED


@dataclass(frozen=True)
class Talk:
    """Реплика переписки: `who` — `author`, `assignee` или ключ сотрудника сида."""

    who: str
    text: str


@dataclass(frozen=True)
class Extra:
    type: AppealType
    category: str
    author: str
    priority: Priority
    status: AppealStatus
    summary: str
    text: str
    age_days: float
    solution: str | None = None
    source: AppealSource = AppealSource.FORM
    # Кто ответственный сейчас; None — ответственный категории.
    assignee: str | None = None
    # Сначала обращение было у этого сотрудника, потом его переназначили с причиной.
    reassigned_from: str | None = None
    reassign_reason: str | None = None
    reassigned_by: str | None = None
    # Обращение подали в другую категорию, ответственный её исправил.
    category_from: str | None = None
    first_reply: str | None = None
    talk: tuple[Talk, ...] = ()
    question: str | None = None
    answer: str | None = None
    decision: str | None = None
    result: str | None = None
    public_summary: str | None = None
    public_result: str | None = None
    reject_reason: str | None = None
    escalation: int = 0
    bitrix_task: str | None = None
    extra_events: tuple[tuple[HistoryKind, str], ...] = field(default=())


APPEALS: list[Extra] = [
    # --- Продажи ---------------------------------------------------------------------------------
    Extra(
        PROBLEM, "Договорная работа", "employee_sales", HIGH, IN_PROGRESS,
        "Договоры на поставку СКУД по три дня ждут визы юриста",
        "Договоры на поставку систем контроля доступа по три дня лежат на согласовании у юриста. Клиент за это время "
        "успевает запросить предложение у конкурента. За октябрь так ушли две сделки на монтаж турникетов.",
        age_days=6.2, solution="Типовой договор без изменений согласовывать за один рабочий день, без очереди.",
        first_reply="Взял. Посмотрю, сколько договоров в октябре шли дольше двух дней.",
        talk=(
            Talk("assignee", "Ильдар, пришлите номера двух сделок, которые ушли. Хочу показать их юристу."),
            Talk("author", "Сделки по складу на Рыскулова и по бизнес-центру «Алатау». В обеих договор был типовой, без правок."),
            Talk("assignee", "Спасибо. Юрист подтвердил: типовые договоры он смотрит в общей очереди вместе с нестандартными."),
            Talk("author", "Тогда, может, типовые вообще не отправлять ему, если клиент не менял условия?"),
            Talk("assignee", "Так и сделаем: типовой договор без изменений подписываю я, юристу уходит только копия."),
        ),
        decision="Типовой договор без изменений подписывает руководитель продаж в день обращения. Юрист получает копию и смотрит "
        "только договоры с правками клиента. Проверим на ноябрьских сделках.",
        bitrix_task="1412",
    ),
    Extra(
        SUGGESTION, "Задачи и коммуникации", "employee_sales", MEDIUM, IMPLEMENTED,
        "Единый шаблон коммерческого предложения по видеонаблюдению",
        "Каждый менеджер собирает коммерческое предложение по видеонаблюдению в своём файле. Клиенты получают разные "
        "формы с разным набором позиций, а новичок тратит на первое предложение полдня.",
        age_days=12, solution="Один шаблон в CRM: камеры, регистратор, монтаж и гарантия отдельными блоками.",
        first_reply="Хорошая идея. Соберу, что сейчас используют менеджеры.",
        talk=(
            Talk("assignee", "Какие блоки обязательно должны быть в шаблоне?"),
            Talk("author", "Оборудование, монтаж, пусконаладка, гарантия и срок поставки. Срок клиенты спрашивают в первую очередь."),
            Talk("assignee", "Добавил срок поставки отдельной строкой. Шаблон в CRM, раздел «Документы»."),
        ),
        decision="Собираем один шаблон на основе трёх самых удачных предложений за квартал.",
        result="Шаблон коммерческого предложения по видеонаблюдению добавлен в CRM. Менеджеры используют его с 5 ноября.",
        public_summary="Единый шаблон коммерческого предложения по видеонаблюдению",
        public_result="Шаблон лежит в CRM: оборудование, монтаж, гарантия и срок поставки отдельными блоками",
    ),
    Extra(
        PROBLEM, "Задачи и коммуникации", "employee_pm", MEDIUM, AWAITING,
        "Заявки от клиентов на выезд инженера теряются в общем чате",
        "Клиенты пишут о неисправностях в общий чат продаж. Сообщение уходит вверх, и заявку на выезд инженера никто "
        "не оформляет. На прошлой неделе клиент ждал выезд четыре дня.",
        age_days=3.1, first_reply="Взял в работу. Разберусь, как заявки попадают в чат.",
        question="Ринат, о каком клиенте речь и в какой чат он писал? Хочу проверить, кто видел сообщение.",
    ),
    Extra(
        PRAISE, "Договорная работа", "employee_accounting", LOW, CLOSED,
        "Спасибо отделу продаж за быстрые закрывающие документы",
        "Хочу отметить Ильдара Хасанова: в конце квартала он за один день собрал подписанные акты по шести объектам. "
        "Мы закрыли период без переносов.",
        age_days=8, source=AppealSource.BOT, first_reply="Спасибо, передал Ильдару и отметил на планёрке.",
    ),
    # --- Закупки ---------------------------------------------------------------------------------
    Extra(
        PROBLEM, "Межотдельное взаимодействие", "employee_pm", HIGH, NEW,
        "Камеры для объекта заказаны без согласования с проектом",
        "На объект «Склад Байсерке» закупили 40 камер с фокусным расстоянием 2,8 мм. По проекту на периметр нужны 6 мм. "
        "Заявку в закупки отправили до того, как проектировщик утвердил спецификацию.",
        # Возраст подбирается под шаг эскалации при загрузке: обращение остаётся на втором шаге в любой день сброса.
        age_days=2.2, escalation=2,
    ),
    Extra(
        SUGGESTION, "Прозрачность результатов", "employee_procurement", LOW, IN_REVIEW,
        "Показывать статус заказа у поставщика в карточке заявки",
        "Проектные менеджеры каждый день спрашивают, отгрузил ли поставщик оборудование. Статус есть в личном кабинете "
        "поставщика, но видим его только мы.",
        age_days=2.2, solution="Раз в день вносить статус отгрузки в карточку заявки.",
        first_reply="Посмотрю, сколько времени уходит на такие вопросы.",
        talk=(
            Talk("assignee", "Карина, сколько таких вопросов приходит за день?"),
            Talk("author", "В среднем восемь. Перед сдачей объекта доходит до пятнадцати."),
        ),
    ),
    Extra(
        PROBLEM, "Информационная прозрачность", "employee_design", MEDIUM, REJECTED,
        "Нет доступа к закупочным ценам при подборе оборудования",
        "При подборе оборудования для проекта я не вижу закупочную цену. Подбираю по каталожной, потом смету "
        "пересчитывают, и проект уходит на доработку.",
        age_days=9, first_reply="Взял. Уточню у собственника, кому можно открывать закупочные цены.",
        talk=(
            Talk("assignee", "Вероника, вам нужна сама цена или достаточно знать, укладывается ли позиция в бюджет?"),
            Talk("author", "Достаточно понимать, проходит позиция по бюджету или нет."),
        ),
        reject_reason="Закупочные цены остаются закрытыми: это условие договоров с поставщиками. Вместо цены в каталог "
        "добавим отметку «в бюджете / выше бюджета» — её достаточно для подбора. Отметку заведём отдельной задачей.",
    ),
    # --- Бухгалтерия -----------------------------------------------------------------------------
    Extra(
        PROBLEM, "Документооборот", "employee_sales", MEDIUM, IN_REVIEW,
        "Счета на предоплату выставляются на следующий день",
        "Счёт на предоплату по оборудованию клиент получает на следующий день после запроса. Для срочных поставок "
        "охранной сигнализации это критично: клиент не может оплатить в день заказа.",
        age_days=1.4, category_from="Договорная работа",
        first_reply="Взяла. Посмотрю, во сколько приходят запросы на счета.",
    ),
    Extra(
        SUGGESTION, "Знания и наставничество", "employee_accounting", LOW, IN_PROGRESS,
        "Памятка по закрывающим документам для менеджеров",
        "Менеджеры часто приносят акты без печати заказчика или с неверной датой. Документы возвращаются, "
        "период закрывается позже.",
        age_days=7, solution="Одностраничная памятка: какие документы нужны и как их проверить перед сдачей.",
        first_reply="Согласна, это снимет половину возвратов.",
        decision="Готовим памятку на одну страницу и разбираем её на планёрке продаж 20 ноября.",
    ),
    # --- Проектирование --------------------------------------------------------------------------
    Extra(
        PROBLEM, "Каталог и данные", "employee_procurement", HIGH, IN_PROGRESS,
        "В каталоге нет аналогов снятых с производства камер",
        "Три модели купольных камер сняты с производства, а в каталоге нет указания на замену. Закупки каждый раз "
        "пишут проектировщику и ждут ответа.",
        age_days=4.6, reassigned_from="head_design", reassigned_by="head_design",
        reassign_reason="Номенклатуру ведёт Вероника Литвин: она знает, какие модели пришли на замену.",
        first_reply="Взяла. Соберу список снятых моделей.",
        talk=(
            Talk("assignee", "Карина, какие модели вы запрашивали чаще всего?"),
            Talk("author", "DS-2CD2143 и две модели той же серии с ИК-подсветкой."),
            Talk("assignee", "Нашла замену для всех трёх, вношу в каталог с пометкой «аналог»."),
        ),
        decision="В карточку каждой снятой модели добавляем поле «аналог» и ссылку на замену. Начинаем с камер.",
        bitrix_task="1418",
    ),
    Extra(
        SUGGESTION, "Планирование ресурсов", "employee_pmo", MEDIUM, NEW,
        "Календарь занятости проектировщиков на месяц вперёд",
        "Сроки проекта называем клиенту наугад: не видно, когда освободится проектировщик слаботочных систем.",
        age_days=0.3, solution="Общий календарь: кто на каком объекте и до какой даты.",
    ),
    # --- Проектный офис --------------------------------------------------------------------------
    Extra(
        PROBLEM, "Проектная деятельность", "employee_design", HIGH, NEW,
        "Монтажники выезжают на объект без утверждённой схемы",
        "Бригада выехала на монтаж пожарной сигнализации в торговом центре с черновой схемой. Шлейфы проложили "
        "по старой трассе, переделка заняла два дня.",
        age_days=6.5, escalation=3,
    ),
    Extra(
        PROBLEM, "Постановка задач", "employee_it", MEDIUM, IN_REVIEW,
        "В задачах на настройку оборудования нет адреса объекта",
        "Задачи на настройку регистраторов приходят без адреса объекта и контакта на месте. Каждый раз уточняю "
        "у руководителя проекта.",
        age_days=3.8, first_reply="Принял. Проверю, как заполняются задачи.",
        question="Станислав, это задачи из Битрикс24 или из чата? Пришлите пример.",
        answer="Из Битрикс24. Пример — настройка регистратора для аптеки на Абая: в задаче только название клиента.",
    ),
    Extra(
        SUGGESTION, "Регламенты", "employee_pm", LOW, IMPLEMENTED,
        "Короткий чек-лист сдачи объекта заказчику",
        "При сдаче объекта каждый руководитель проекта проверяет своё. Один забывает паспорта оборудования, "
        "другой — журнал обучения персонала заказчика.",
        age_days=14, solution="Чек-лист из десяти пунктов, общий для всех объектов.",
        first_reply="Поддерживаю. Соберу пункты у руководителей проектов.",
        decision="Составляем чек-лист и пробуем его на двух объектах в ноябре.",
        result="Чек-лист сдачи объекта из 11 пунктов утверждён и добавлен в шаблон проекта.",
        public_summary="Чек-лист сдачи объекта заказчику",
        public_result="Чек-лист из 11 пунктов добавлен в шаблон проекта и используется на всех объектах",
    ),
    # --- IT --------------------------------------------------------------------------------------
    Extra(
        PROBLEM, "Интеграции и IT", "employee_office", MEDIUM, IMPLEMENTED,
        "Удалённый доступ к регистраторам клиентов работает через раз",
        "Инженеры сервиса не могут подключиться к регистраторам клиентов: соединение рвётся каждые десять минут. "
        "Диагностику приходится проводить с выездом.",
        age_days=10, source=AppealSource.BOT,
        first_reply="Взял. Проверю настройки VPN.",
        talk=(
            Talk("assignee", "Ольга, у кого именно рвётся соединение — у всех инженеров или у части?"),
            Talk("author", "У тех, кто работает из дома. В офисе всё в порядке."),
            Talk("assignee", "Нашёл причину: у домашних подключений стоял короткий срок сеанса. Увеличил, проверьте."),
            Talk("author", "Проверили втроём, час держится без обрывов. Спасибо!"),
        ),
        decision="Меняем срок сеанса VPN для удалённых подключений инженеров.",
        result="Срок сеанса VPN увеличен до восьми часов. Обрывов при удалённой диагностике больше нет.",
        public_summary="Удалённый доступ к регистраторам клиентов обрывался",
        public_result="Увеличили срок сеанса VPN: диагностика проходит без выезда",
        bitrix_task="1401",
    ),
    Extra(
        PRAISE, "Коммуникации", "employee_sales", LOW, NEW,
        "Благодарность Станиславу Цою за помощь с демонстрацией",
        "Станислав за вечер собрал демо-стенд с камерами и доступом по карте для встречи с сетью аптек. "
        "Клиент подписал договор на 12 точек.",
        age_days=0.6, source=AppealSource.BOT,
    ),
    # --- Административный отдел ------------------------------------------------------------------
    Extra(
        PROBLEM, "Хранение документов", "employee_accounting", MEDIUM, IN_REVIEW,
        "Оригиналы договоров хранятся в трёх разных шкафах",
        "Чтобы найти оригинал договора для проверки, приходится обходить три кабинета. Договор с подрядчиком "
        "по монтажу искали полдня.",
        age_days=2.6, first_reply="Взяла. Посмотрю, где сейчас лежат договоры этого года.",
        talk=(
            Talk("assignee", "Зарина, договоры какого периода ищете чаще всего?"),
            Talk("author", "Текущего года и прошлого. Старше — редко."),
            Talk("assignee", "Тогда соберём эти два года в одном шкафу у бухгалтерии, остальное — в архив."),
        ),
    ),
    Extra(
        SUGGESTION, "Корпоративная среда", "employee_docs", LOW, REJECTED,
        "Отдельная переговорная для видеозвонков с клиентами",
        "Звонки с клиентами идут из общего кабинета, слышны разговоры коллег.",
        age_days=11, solution="Выделить малую переговорную под видеозвонки.",
        first_reply="Посмотрю загрузку переговорных.",
        reject_reason="Свободной комнаты нет: малая переговорная с декабря отдаётся под сервисный стол. Для звонков "
        "заказаны две гарнитуры с шумоподавлением и ширма в кабинет продаж — придут до конца ноября.",
    ),
    # --- HR --------------------------------------------------------------------------------------
    Extra(
        SUGGESTION, "Обучение", "employee_it", MEDIUM, IN_PROGRESS,
        "Вводный курс по охранным системам для новых сотрудников",
        "Новые сотрудники продаж и закупок первые недели путают шлейф, извещатель и приёмно-контрольный прибор. "
        "Вопросы уходят инженерам и отвлекают их от объектов.",
        age_days=5, solution="Двухчасовой вводный курс с демо-стендом в первую неделю работы.",
        first_reply="Отличное предложение. Посмотрю, кто из инженеров может вести.",
        talk=(
            Talk("assignee", "Станислав, сможете провести первое занятие на демо-стенде?"),
            Talk("author", "Да, могу в любую пятницу после обеда."),
        ),
        decision="Первое занятие вводного курса — 27 ноября, ведёт Станислав Цой. Дальше раз в месяц для новичков.",
    ),
    Extra(
        PRAISE, "Обучение", "employee_procurement", LOW, CLOSED,
        "Спасибо HR за разбор новых линеек оборудования",
        "Занятие по новым линейкам пожарных извещателей было понятным и коротким. Теперь быстрее отвечаю поставщикам.",
        age_days=4, first_reply="Спасибо! Следующее занятие — по системам контроля доступа.",
    ),
]

# Закрытое обсуждение с итогом — на реализованном предложении про чек-лист сдачи объекта.
CLOSED_DISCUSSION_SUMMARY = "Короткий чек-лист сдачи объекта заказчику"
CLOSED_DISCUSSION_TEXT = "Ввести общий чек-лист сдачи объекта заказчику для всех проектов?"
CLOSED_DISCUSSION_OUTCOME = (
    "Большинство за. Чек-лист вводим для всех объектов; пункт про журнал обучения персонала заказчика "
    "оставляем обязательным только для объектов с пожарной сигнализацией."
)
CLOSED_DISCUSSION_VOTES = {
    "employee_pm": VoteValue.FOR,
    "employee_pmo": VoteValue.FOR,
    "employee_design": VoteValue.FOR,
    "employee_it": VoteValue.FOR,
    "employee_sales": VoteValue.FOR,
    "head_design": VoteValue.AGAINST,
    "employee_office": VoteValue.FOR,
}
CLOSED_DISCUSSION_COMMENTS = [
    ("employee_pmo", "За. Сейчас при сдаче каждый вспоминает своё, и что-то обязательно забывают."),
    ("head_design", "Против длинного списка: если пунктов будет больше десяти, его перестанут читать."),
    ("employee_it", "Предлагаю пункт про журнал обучения оставить только там, где есть пожарная сигнализация."),
]


def _at(now: datetime, days: float) -> datetime:
    return now - timedelta(days=days)


async def add_more(session: AsyncSession, now: datetime, tz: tzinfo) -> None:
    users = {u.seed_key: u for u in await session.scalars(select(User)) if u.seed_key}
    categories = {c.name: c for c in await session.scalars(select(Category))}
    for offset, spec in enumerate(APPEALS):
        await _add_appeal(session, spec, FIRST_NUMBER + offset, users, categories, now, tz)
    await _add_closed_discussion(session, users, now)
    await session.flush()


async def _add_appeal(
    session: AsyncSession, spec: Extra, number: int, users: dict[str, User], categories: dict[str, Category], now: datetime, tz: tzinfo
) -> None:
    category = categories[spec.category]
    author = users[spec.author]
    final = users[spec.assignee] if spec.assignee else await session.get(User, category.responsible_id)
    first = users[spec.reassigned_from] if spec.reassigned_from else final
    created = _at(now, spec.age_days)
    praise = spec.type == PRAISE
    due = None if praise else add_business_days(created, DEADLINE_DAYS[spec.priority], tz)
    if spec.escalation:
        # Просроченное обращение должно стоять ровно на своём шаге в любой день сброса: в выходные и понедельник
        # рабочие дни считаются иначе. Отступаем по часу назад от «сейчас», пока шаг не совпадёт.
        for hours in range(1, 24 * 21):
            created = now - timedelta(hours=hours)
            due = add_business_days(created, DEADLINE_DAYS[spec.priority], tz)
            if due_level(due, now, tz) == spec.escalation:
                created -= timedelta(hours=1)  # небольшой запас: шаг наступил не в эту минуту
                due = add_business_days(created, DEADLINE_DAYS[spec.priority], tz)
                if due_level(due, now, tz) == spec.escalation:
                    break

    appeal = Appeal(
        number=f"A-{number:03d}",
        type=spec.type,
        category_id=category.id,
        priority=spec.priority,
        status=spec.status,
        author_id=author.id,
        assignee_id=final.id,
        text=spec.text,
        summary=spec.summary,
        proposed_solution=spec.solution,
        source=spec.source,
        first_response_due_at=due,
        escalation_level=spec.escalation,
        created_at=created,
        updated_at=created,
    )
    session.add(appeal)
    await session.flush()

    def event(kind: HistoryKind, at: datetime, actor: User | None, **fields) -> None:
        session.add(HistoryEvent(appeal_id=appeal.id, actor_id=actor.id if actor else None, kind=kind, created_at=at, **fields))
        appeal.updated_at = max(appeal.updated_at, at)

    def say(who: User, at: datetime, text: str, *, question: bool = False) -> None:
        session.add(Message(appeal_id=appeal.id, author_id=who.id, text=text, is_clarification_question=question, created_at=at))
        appeal.updated_at = max(appeal.updated_at, at)

    via = "Подано через бота" if spec.source == AppealSource.BOT else "Подано через форму"
    event(HistoryKind.CREATED, created, author, comment=via)
    origin = categories[spec.category_from] if spec.category_from else category
    event(
        HistoryKind.ASSIGNED, created, None, field="assignee", new_value=first.full_name,
        comment=f"По правилу категории «{origin.name}»",
    )
    if due is not None:
        event(HistoryKind.DEADLINE_SET, created, None, field="first_response_due_at", new_value=due.isoformat())

    # Шаг между событиями: всё действие укладывается в прошедшее с подачи время и не уходит в будущее.
    span = now - created
    step = min(timedelta(hours=5), span / 14)
    moment = created + step

    if spec.category_from:
        event(HistoryKind.FIELD_CHANGED, moment, final, field="category", old_value=origin.name, new_value=category.name)
        moment += step
    if spec.reassigned_from:
        by = users[spec.reassigned_by or spec.reassigned_from]
        event(
            HistoryKind.REASSIGNED, moment, by, field="assignee", old_value=first.full_name, new_value=final.full_name,
            comment=spec.reassign_reason,
        )
        moment += step

    # Просрочка: срок прошёл, первого ответа нет — шаги эскалации по рабочему дню друг за другом.
    for level in range(1, spec.escalation + 1):
        at = min(add_business_days(due, level - 1, tz) + timedelta(minutes=10), now - timedelta(minutes=30 * (4 - level)))
        event(
            HistoryKind.ESCALATED, at, None, field="escalation_level", old_value=str(level - 1), new_value=str(level),
            comment=ESCALATION_COMMENTS[level],
        )

    if spec.status == NEW:
        return

    def move(to: AppealStatus, at: datetime, old: AppealStatus, comment: str | None = None, actor: User = final) -> None:
        event(HistoryKind.STATUS_CHANGED, at, actor, field="status", old_value=old, new_value=to, comment=comment)

    # Первый ответ: «Взять» у обычного обращения, «Принять» у благодарности.
    appeal.first_response_at = moment
    if praise:
        appeal.closed_reason = ClosedReason.FEEDBACK_ACCEPTED
        move(CLOSED, moment, NEW, spec.first_reply)
        if spec.first_reply:
            say(final, moment, spec.first_reply)
        return
    move(IN_REVIEW, moment, NEW, spec.first_reply)
    if spec.first_reply:
        say(final, moment, spec.first_reply)
    moment += step

    for line in spec.talk:
        who = author if line.who == "author" else final if line.who == "assignee" else users[line.who]
        say(who, moment, line.text)
        moment += step / 2

    if spec.question:
        event(HistoryKind.CLARIFICATION_REQUESTED, moment, final)
        move(AWAITING, moment, IN_REVIEW)
        say(final, moment, spec.question, question=True)
        moment += step
        if spec.answer:
            event(HistoryKind.CLARIFICATION_ANSWERED, moment, author)
            move(IN_REVIEW, moment, AWAITING, actor=author)
            say(author, moment, spec.answer)
            moment += step

    if spec.bitrix_task:
        url = BITRIX_URL.format(spec.bitrix_task)
        session.add(BitrixTask(appeal_id=appeal.id, task_id=spec.bitrix_task, url=url, created_by_id=final.id, created_at=moment))
        event(HistoryKind.BITRIX_TASK_CREATED, moment, final, field="bitrix_task", new_value=url)
        moment += step / 2

    if spec.status == REJECTED:
        appeal.rejection_reason = spec.reject_reason
        move(REJECTED, moment, IN_REVIEW, spec.reject_reason)
        return
    if spec.status in (IN_PROGRESS, IMPLEMENTED):
        appeal.decision = spec.decision
        move(IN_PROGRESS, moment, IN_REVIEW, spec.decision)
        moment += step * 2
    if spec.status == IMPLEMENTED:
        appeal.result = spec.result
        appeal.public_summary = spec.public_summary
        appeal.public_result = spec.public_result
        appeal.implemented_at = moment
        move(IMPLEMENTED, moment, IN_PROGRESS, spec.result)


async def _add_closed_discussion(session: AsyncSession, users: dict[str, User], now: datetime) -> None:
    appeal = (await session.scalars(select(Appeal).where(Appeal.summary == CLOSED_DISCUSSION_SUMMARY))).one()
    published = appeal.first_response_at + (appeal.implemented_at - appeal.first_response_at) / 4
    closed = appeal.first_response_at + (appeal.implemented_at - appeal.first_response_at) / 2
    discussion = Discussion(
        appeal_id=appeal.id,
        public_text=CLOSED_DISCUSSION_TEXT,
        deadline=closed,
        status=DiscussionStatus.CLOSED,
        author_name_consent=NameConsent.SHOWN,
        outcome=CLOSED_DISCUSSION_OUTCOME,
        created_by_id=appeal.assignee_id,
        created_at=published,
        closed_by_id=appeal.assignee_id,
        closed_at=closed,
    )
    session.add(discussion)
    await session.flush()
    voted = published + (closed - published) / 2
    for key, value in CLOSED_DISCUSSION_VOTES.items():
        session.add(DiscussionVote(discussion_id=discussion.id, user_id=users[key].id, value=value, updated_at=voted))
    for index, (key, text) in enumerate(CLOSED_DISCUSSION_COMMENTS):
        at = voted + timedelta(minutes=20 * index)
        session.add(DiscussionComment(discussion_id=discussion.id, author_id=users[key].id, text=text, created_at=at))
    session.add_all(
        [
            HistoryEvent(
                appeal_id=appeal.id, actor_id=appeal.assignee_id, kind=HistoryKind.DISCUSSION_PUBLISHED,
                comment=CLOSED_DISCUSSION_TEXT, created_at=published,
            ),
            HistoryEvent(
                appeal_id=appeal.id, actor_id=appeal.assignee_id, kind=HistoryKind.DISCUSSION_CLOSED,
                comment=CLOSED_DISCUSSION_OUTCOME, created_at=closed,
            ),
        ]
    )
