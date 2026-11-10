"""Демо-данные: компания из датасета организаторов (A-001…A-020).

Люди синтетические. Ключ (`key`) — стабильное имя демо-пользователя: по нему файл аккаунтов
вне репозитория закрепляет за ролью реальный Telegram ID.
"""

from __future__ import annotations

from dataclasses import dataclass

from app.domain.enums import AppealSource, AppealStatus, AppealType, Priority, Role

P, S, F = AppealType.PROBLEM, AppealType.SUGGESTION, AppealType.PRAISE
HIGH, MEDIUM, LOW = Priority.HIGH, Priority.MEDIUM, Priority.LOW
BOT, FORM = AppealSource.BOT, AppealSource.FORM

DEPARTMENTS = [
    "Закупки",
    "Бухгалтерия",
    "Продажи",
    "Проектирование",
    "Проектный офис",
    "IT",
    "Административный отдел",
    "HR",
]


@dataclass(frozen=True)
class SeedUser:
    key: str
    full_name: str
    position: str
    role: Role
    department: str | None
    is_head: bool = False


USERS = [
    SeedUser("owner", "Ержан Касымов", "Собственник", Role.OWNER, None),
    SeedUser("admin", "Анна Ли", "Администратор системы", Role.ADMIN, None),
    SeedUser("head_procurement", "Марат Сейткали", "Руководитель закупок", Role.HEAD, "Закупки", True),
    SeedUser("employee_procurement", "Айгерим Нурланова", "Сотрудник закупок", Role.EMPLOYEE, "Закупки"),
    SeedUser("head_accounting", "Ольга Петрова", "Руководитель бухгалтерии", Role.HEAD, "Бухгалтерия", True),
    SeedUser("employee_accounting", "Дина Жуматова", "Сотрудник бухгалтерии", Role.EMPLOYEE, "Бухгалтерия"),
    SeedUser("head_sales", "Тимур Абенов", "Руководитель продаж", Role.HEAD, "Продажи", True),
    SeedUser("employee_sales", "Сергей Ким", "Менеджер по продажам", Role.EMPLOYEE, "Продажи"),
    SeedUser("head_design", "Нурлан Беков", "Руководитель проектирования", Role.HEAD, "Проектирование", True),
    SeedUser("employee_design", "Алия Сапарова", "Ответственный за номенклатуру", Role.EMPLOYEE, "Проектирование"),
    SeedUser("head_pmo", "Виктор Ахметов", "Руководитель проектного офиса", Role.HEAD, "Проектный офис", True),
    SeedUser("employee_pmo", "Мадина Оспанова", "Координатор проекта", Role.EMPLOYEE, "Проектный офис"),
    SeedUser("employee_it", "Даурен Исаев", "IT-специалист", Role.EMPLOYEE, "IT"),
    SeedUser("head_admin_office", "Гульнара Омарова", "Административный руководитель", Role.HEAD, "Административный отдел", True),
    SeedUser("employee_office", "Асель Тулегенова", "Сотрудник офиса", Role.EMPLOYEE, "Административный отдел"),
    SeedUser("head_hr", "Жанна Ермекова", "HR / внутренние коммуникации", Role.HEAD, "HR", True),
    SeedUser("employee_pm", "Ерлан Тлеуов", "Руководитель проекта", Role.EMPLOYEE, "Проектный офис"),
    SeedUser("employee_docs", "Елена Савченко", "Администратор документов", Role.EMPLOYEE, "Административный отдел"),
    SeedUser("head_it", "Артём Белов", "Руководитель IT", Role.HEAD, "IT", True),
]


@dataclass(frozen=True)
class SeedCategory:
    name: str
    department: str
    responsible: str | None
    deputy: str | None


# Порядок — по первому появлению в датасете; ответственные — «условные ответственные» датасета.
CATEGORIES = [
    SeedCategory("Межотдельное взаимодействие", "Закупки", "head_procurement", "employee_procurement"),
    SeedCategory("Информационная прозрачность", "Закупки", "head_procurement", None),
    SeedCategory("Каталог и данные", "Проектирование", "employee_design", "head_design"),
    SeedCategory("Обучение", "HR", "head_hr", None),
    SeedCategory("Документооборот", "Бухгалтерия", "head_accounting", "employee_accounting"),
    SeedCategory("Регламенты", "Проектный офис", "head_pmo", "employee_pmo"),
    SeedCategory("Интеграции и IT", "IT", "employee_it", "head_it"),
    SeedCategory("Знания и наставничество", "Бухгалтерия", "head_accounting", None),
    SeedCategory("Договорная работа", "Продажи", "head_sales", "employee_sales"),
    SeedCategory("Задачи и коммуникации", "Продажи", "head_sales", None),
    SeedCategory("Оперативность", "Проектный офис", "head_pmo", None),
    SeedCategory("Коммуникации", "IT", "employee_it", "head_it"),
    SeedCategory("Проектная деятельность", "Проектный офис", "head_pmo", "employee_pmo"),
    SeedCategory("Планирование ресурсов", "Проектирование", "head_design", None),
    SeedCategory("Постановка задач", "Проектный офис", "head_pmo", None),
    SeedCategory("Корпоративная среда", "Административный отдел", "head_admin_office", "employee_office"),
    SeedCategory("Хранение документов", "Административный отдел", "employee_docs", "head_admin_office"),
    SeedCategory("Прозрачность результатов", "Закупки", "head_procurement", None),
]

DEADLINE_RULES = {HIGH: 1, MEDIUM: 3, LOW: 5}
SETTINGS = {"digest_time": "09:00"}


@dataclass(frozen=True)
class SeedAppeal:
    number: str
    type: AppealType
    category: str
    author: str
    priority: Priority
    status: AppealStatus
    text: str
    summary: str
    source: AppealSource
    # Когда подано: столько рабочих дней назад от момента загрузки (+ часы раньше в тот же день).
    created_days_ago: int
    created_hours_earlier: int = 0
    # Через сколько часов после подачи дан первый ответ (None — ответа ещё нет).
    first_response_after_hours: int | None = None
    proposed_solution: str | None = None
    question: str | None = None  # уточняющий вопрос (Ожидает уточнения)
    decision: str | None = None  # В работе / Реализовано
    rejection_reason: str | None = None
    result: str | None = None
    public_summary: str | None = None
    # Через сколько рабочих дней после подачи зафиксирован результат или закрытие.
    finished_after_days: int | None = None


APPEALS = [
    SeedAppeal(
        "A-001", P, "Межотдельное взаимодействие", "employee_procurement", MEDIUM, AppealStatus.NEW,
        "В заявках на приобретение оборудования иногда не хватает назначения изделия и требуемых параметров. "
        "Предлагаю добавить обязательные поля, чтобы сократить число уточнений.",
        "В заявках на оборудование не хватает назначения и параметров", FORM,
        created_days_ago=5, created_hours_earlier=1,
        proposed_solution="Добавить обязательные поля «назначение» и «параметры» в шаблон заявки",
    ),
    SeedAppeal(
        "A-002", S, "Информационная прозрачность", "employee_procurement", MEDIUM, AppealStatus.IN_REVIEW,
        "При общении с поставщиками полезно видеть общую стадию проекта без доступа к коммерческим деталям. "
        "Можно ли показывать краткий статус и ориентировочные контрольные даты?",
        "Показывать поставщикам стадию проекта без коммерческих деталей", BOT,
        created_days_ago=4, created_hours_earlier=2, first_response_after_hours=5,
    ),
    SeedAppeal(
        "A-003", P, "Каталог и данные", "employee_design", HIGH, AppealStatus.IN_PROGRESS,
        "В рабочих материалах иногда встречаются разные обозначения одного изделия. Это увеличивает время проверки "
        "спецификации. Нужен понятный способ находить актуальную карточку позиции.",
        "Разные обозначения одного изделия в рабочих материалах", FORM,
        created_days_ago=6, first_response_after_hours=3,
        decision="Подготовим правило проверки и корректировки номенклатуры.",
    ),
    SeedAppeal(
        "A-004", S, "Обучение", "employee_procurement", LOW, AppealStatus.IMPLEMENTED,
        "Было бы полезно проводить короткие занятия по новым товарным линейкам с разбором типовых запросов. "
        "Предлагаю составить календарь таких встреч.",
        "Короткие занятия по новым товарным линейкам", BOT,
        created_days_ago=12, first_response_after_hours=20,
        proposed_solution="Составить календарь занятий",
        decision="Проведём пробный семинар и по итогам решим о календаре.",
        result="Запланирован пробный обучающий семинар.",
        public_summary="Короткие занятия по новым товарным линейкам",
        finished_after_days=9,
    ),
    SeedAppeal(
        "A-005", P, "Документооборот", "employee_accounting", MEDIUM, AppealStatus.AWAITING_INFO,
        "При обработке документов между подразделениями возникают дополнительные вопросы о том, на каком этапе "
        "находится пакет. Хотелось бы видеть ответственного и текущий статус.",
        "Не видно, на каком этапе пакет документов", FORM,
        created_days_ago=4, first_response_after_hours=6,
        question="Уточните, пожалуйста, какие виды документов и какие этапы согласования для вас ключевые?",
    ),
    SeedAppeal(
        "A-006", S, "Регламенты", "employee_accounting", MEDIUM, AppealStatus.IN_REVIEW,
        "Предлагаю собрать короткую пошаговую памятку для операций, в которых последовательно участвуют несколько "
        "подразделений, и определить порядок актуализации памятки.",
        "Пошаговая памятка для межотдельных операций", FORM,
        created_days_ago=3, created_hours_earlier=1, first_response_after_hours=26,
    ),
    SeedAppeal(
        "A-007", P, "Интеграции и IT", "employee_accounting", HIGH, AppealStatus.NEW,
        "Иногда повторный ввод одних и тех же сведений в разных рабочих системах занимает много времени. "
        "Нужна оценка, какие операции можно синхронизировать безопасно.",
        "Повторный ввод данных в разных системах", BOT,
        created_days_ago=3,
    ),
    SeedAppeal(
        "A-008", S, "Знания и наставничество", "employee_accounting", LOW, AppealStatus.IMPLEMENTED,
        "При передаче сложной задачи новому сотруднику полезен короткий разбор типовых ошибок и контактов, к которым "
        "можно обратиться за помощью. Предлагаю сделать такую памятку.",
        "Памятка по типовым ошибкам для новых сотрудников", FORM,
        created_days_ago=15, first_response_after_hours=8,
        decision="Подготовим учебную инструкцию по передаче задач.",
        result="Создана учебная инструкция.",
        public_summary="Памятка по типовым ошибкам для новых сотрудников",
        finished_after_days=8,
    ),
    SeedAppeal(
        "A-009", P, "Договорная работа", "employee_sales", HIGH, AppealStatus.IN_PROGRESS,
        "Не всегда понятно, кто готовит очередную версию приложения к договору и кто должен проверить её перед "
        "отправкой. Это приводит к повторным согласованиям.",
        "Неясно, кто готовит и проверяет приложения к договору", FORM,
        created_days_ago=7, first_response_after_hours=4,
        decision="Разграничим этапы подготовки, проверки и утверждения приложений.",
    ),
    SeedAppeal(
        "A-010", S, "Задачи и коммуникации", "employee_sales", MEDIUM, AppealStatus.IN_REVIEW,
        "Предлагаю не закрывать рабочую задачу до подтверждения заказчиком результата внутри компании, чтобы "
        "связанные вопросы оставались в общей истории обсуждения.",
        "Не закрывать задачу до подтверждения результата заказчиком", BOT,
        created_days_ago=2, created_hours_earlier=3, first_response_after_hours=2,
    ),
    SeedAppeal(
        "A-011", P, "Оперативность", "employee_sales", HIGH, AppealStatus.NEW,
        "При срочной подготовке клиентского предложения сложно прогнозировать сроки ответа от смежных подразделений. "
        "Хотелось бы видеть ожидаемый срок и уведомление при задержке.",
        "Непредсказуемые сроки ответа смежных подразделений", BOT,
        created_days_ago=2, created_hours_earlier=1,
    ),
    SeedAppeal(
        "A-012", S, "Коммуникации", "employee_sales", LOW, AppealStatus.IN_REVIEW,
        "Рабочие обсуждения распределены по нескольким каналам, из-за чего теряется контекст. Предлагаю выбрать "
        "единое место для итоговых решений по задаче.",
        "Единое место для итоговых решений по задаче", FORM,
        created_days_ago=5, first_response_after_hours=30,
    ),
    SeedAppeal(
        "A-013", P, "Проектная деятельность", "employee_pmo", MEDIUM, AppealStatus.AWAITING_INFO,
        "Когда изменяется состав оборудования в проекте, не всегда ясно, какие строки спецификации были пересмотрены. "
        "Нужна более заметная история изменений.",
        "Не видно, какие строки спецификации изменились", FORM,
        created_days_ago=3, first_response_after_hours=4,
        question="В каком формате у вас исходные файлы спецификаций и как вы сейчас сравниваете версии?",
    ),
    SeedAppeal(
        "A-014", S, "Планирование ресурсов", "employee_pmo", MEDIUM, AppealStatus.IN_REVIEW,
        "Предлагаю показывать загруженность проектной группы на ближайшие недели в укрупнённом виде. Так будет проще "
        "согласовывать сроки запуска новых задач.",
        "Показывать загрузку проектной группы на ближайшие недели", BOT,
        created_days_ago=2, first_response_after_hours=7,
    ),
    SeedAppeal(
        "A-015", P, "Постановка задач", "employee_pm", MEDIUM, AppealStatus.IN_PROGRESS,
        "Некоторые поручения поступают без ожидаемого результата и даты завершения. Предлагаю договориться о "
        "минимальном наборе данных при постановке задачи.",
        "Поручения без ожидаемого результата и срока", FORM,
        created_days_ago=8, first_response_after_hours=22,
        decision="Подготовим шаблон поручения с целью, сроком, приоритетом и ответственным.",
    ),
    SeedAppeal(
        "A-016", S, "Обучение", "employee_pm", LOW, AppealStatus.NEW,
        "Для новых сотрудников полезны практические демонстрации оборудования, а не только презентации. "
        "Предлагаю пилотное занятие с учебными образцами.",
        "Практические демонстрации оборудования для новых сотрудников", BOT,
        created_days_ago=1,
    ),
    SeedAppeal(
        "A-017", S, "Корпоративная среда", "employee_office", LOW, AppealStatus.REJECTED,
        "Предлагаю организовать отдельную небольшую зону для коротких перерывов рядом с рабочими помещениями.",
        "Зона для коротких перерывов рядом с рабочими помещениями", FORM,
        created_days_ago=10, first_response_after_hours=28,
        rejection_reason="Сейчас нет подходящего помещения; вернёмся к вопросу при перепланировке.",
        finished_after_days=2,
    ),
    SeedAppeal(
        "A-018", F, "Корпоративная среда", "employee_office", LOW, AppealStatus.CLOSED,
        "Хочу отметить пользу внутренних учебных встреч: после них стало легче обращаться к коллегам за консультацией. "
        "Было бы хорошо сохранить этот формат.",
        "Польза внутренних учебных встреч", BOT,
        created_days_ago=4, first_response_after_hours=5,
    ),
    SeedAppeal(
        "A-019", P, "Хранение документов", "employee_pmo", MEDIUM, AppealStatus.IN_REVIEW,
        "В общих папках трудно быстро определить актуальную редакцию инструкции. Можно ли закрепить единые правила "
        "именования и архивирования старых версий?",
        "Трудно найти актуальную редакцию инструкции в общих папках", FORM,
        created_days_ago=1, created_hours_earlier=2, first_response_after_hours=3,
    ),
    SeedAppeal(
        "A-020", S, "Прозрачность результатов", "employee_procurement", LOW, AppealStatus.NEW,
        "Предлагаю публиковать краткий обзор завершённых внутренних улучшений, чтобы сотрудники видели результат "
        "направленных предложений.",
        "Публиковать обзор завершённых внутренних улучшений", FORM,
        created_days_ago=0, created_hours_earlier=2,
    ),
]
