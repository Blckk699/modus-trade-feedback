"""Тексты и подписи кнопок бота. Названия кнопок упоминают другие клиенты (экран входа Flutter)."""

BTN_SUBMIT = "Подать обращение"
BTN_MY_APPEALS = "Мои обращения"
BTN_DIGEST = "Сводка"
BTN_LOGIN_CODE = "Код входа"
BTN_COPY_CODE = "Скопировать код"
BTN_OPEN_APP = "Открыть"

APP_NAME = "Модус Трейд"

NOT_CONFIGURED = "Бот не настроен: не заданы переменные окружения {names}. См. bot/.env.example."
API_UNAVAILABLE = "Сервис временно недоступен. Попробуйте ещё раз через минуту."


def plural(n: int, one: str, few: str, many: str) -> str:
    n = abs(n) % 100
    if 11 <= n <= 19:
        return many
    n %= 10
    if n == 1:
        return one
    if 2 <= n <= 4:
        return few
    return many


def ttl_text(seconds: int) -> str:
    if seconds >= 60 and seconds % 60 == 0:
        minutes = seconds // 60
        return f"{minutes} {plural(minutes, 'минуту', 'минуты', 'минут')}"
    return f"{seconds} {plural(seconds, 'секунду', 'секунды', 'секунд')}"


def greeting(first_name: str, has_mini_app: bool) -> str:
    lines = [
        f"Здравствуйте, {first_name}!",
        "",
        "Здесь можно подать обращение или предложение: напишите текстом, наговорите голосовое "
        "или перешлите сообщение из рабочего чата.",
        "",
        f"«{BTN_LOGIN_CODE}» — одноразовый код для входа в мобильное приложение «{APP_NAME}».",
    ]
    lines.append(f"«{BTN_MY_APPEALS}» — номера и статусы ваших обращений.")
    if has_mini_app:
        lines.append(f"Кнопка «{BTN_OPEN_APP}» открывает приложение прямо в Telegram.")
    return "\n".join(lines)


SUBMIT_HINT = (
    "Опишите проблему или предложение одним сообщением: напишите текстом, наговорите голосовое "
    "или перешлите сообщение из рабочего чата. Я подготовлю черновик обращения, вы проверите и отправите."
)

MY_APPEALS_BUTTON = "Открыть мои обращения"


def login_code(code: str, ttl_seconds: int) -> str:
    return (
        f"Ваш код входа: <code>{code}</code>\n\n"
        f"Введите его на экране входа в мобильном приложении «{APP_NAME}». "
        f"Код одноразовый и действует {ttl_text(ttl_seconds)}."
    )


def login_code_caption(ttl_seconds: int) -> str:
    """Подпись под виджетом кода: сам код крупно в карточке, здесь — куда его вводить."""
    return (
        f"Введите код на экране входа в мобильном приложении «{APP_NAME}». "
        f"Код одноразовый, действует {ttl_text(ttl_seconds)}."
    )


def appeal_created_caption(number: str) -> str:
    return f"✅ Обращение <b>{number}</b> зарегистрировано. Ответ и смену статуса пришлю сюда."


USE_MENU = "Выберите действие в меню ниже."

# ---- черновик обращения (T-02)
BTN_DRAFT_SEND = "✅ Отправить"
BTN_DRAFT_TYPE = "Тип"
BTN_DRAFT_CATEGORY = "Категория"
BTN_DRAFT_PRIORITY = "Приоритет"
BTN_DRAFT_TEXT = "Поправить текст"
BTN_DRAFT_SUMMARY = "Поправить суть"
BTN_DRAFT_CANCEL = "Отменить"
BTN_BACK = "← Назад"
BTN_OPEN_FORM = "Заполнить форму"

CATEGORY_UNKNOWN = "Не знаю — пусть определит администратор"
FORWARDED_UNKNOWN = "пересланное сообщение"
ASK_NEW_TEXT = "Пришлите исправленный текст обращения одним сообщением."
ASK_NEW_SUMMARY = "Пришлите краткую суть одной фразой."
DRAFT_EXPIRED = "Этот черновик уже неактуален. Напишите сообщение заново."
DRAFT_CANCELLED = "Черновик отменён."
DRAFT_CAPTION = "Проверьте черновик: нажмите «Отправить» или поправьте поля кнопками ниже."
DRAFT_SENT = "Черновик отправлен."
NEED_TEXT = "Пришлите обращение текстом или перешлите текстовое сообщение."
CANNOT_CREATE = "Подача обращений вам недоступна."
FORM_ELSEWHERE = "Форма есть в веб-версии и в мобильном приложении «Модус Трейд»."

# ---- уведомления (T-04)
BTN_OPEN_APPEAL = "Открыть обращение"
NAME_SHOWN = "Готово: в обсуждении будет указано ваше имя."
NAME_HIDDEN = "Готово: в обсуждении будет указано только подразделение."
MY_APPEALS_EMPTY = "У вас пока нет обращений. Опишите проблему или предложение одним сообщением."


def ask_clarification(number: str) -> str:
    return f"Напишите ответ по обращению <b>{number}</b> одним сообщением — он попадёт в переписку с ответственным."


def clarification_sent(number: str) -> str:
    return f"Ответ по обращению <b>{number}</b> отправлен ответственному."

# ---- голосовое (T-03)
VOICE_PROCESSING = "🎙 Расшифровываю голосовое и готовлю черновик…"
VOICE_TOO_LONG = "Голосовое длиннее 5 минут. Запишите покороче или опишите главное текстом."
VOICE_FILE_TOO_BIG = "Файл слишком большой: бот принимает аудио до 20 МБ. Запишите голосовое покороче."
VOICE_DOWNLOAD_FAILED = "Не удалось получить голосовое из Telegram. Попробуйте отправить его ещё раз."

# ---- сводка (T-05)
BTN_OPEN_ANALYTICS = "Открыть аналитику"
DIGEST_UNAVAILABLE = "Сводка доступна руководителям подразделений и собственнику."

# ---- заявка на доступ и приглашение (T-09)
BTN_REQUEST_ACCESS = "Подать заявку"
BTN_REQUEST_AGAIN = "Подать заявку снова"
BTN_EDIT_REQUEST = "Изменить заявку"
BTN_SKIP = "Пропустить"
BTN_NO_DEPARTMENT = "Не знаю / другое"

REQUEST_INTRO = (
    "Вас пока нет в списке сотрудников «Модус Трейд».\n\n"
    "Подайте заявку на доступ: администратор проверит её, а решение придёт сюда."
)
LINK_HINT = (
    "Уже есть аккаунт по почте? Войдите на сайте и привяжите Telegram в профиле — "
    "после этого бот вас узнает и будет присылать уведомления."
)
BTN_LINK_TELEGRAM = "Привязать Telegram на сайте"
ASK_DEPARTMENT = "В каком подразделении вы работаете?"
ASK_COMMENT = "Напишите должность или короткий комментарий для администратора. Или нажмите «Пропустить»."
NAME_INVALID = "Имя должно быть от 1 до 120 символов. Напишите имя и фамилию одним сообщением."
COMMENT_TOO_LONG = "Комментарий длиннее 500 символов. Напишите покороче."
CHOOSE_DEPARTMENT = "Выберите подразделение кнопкой под вопросом."
ALREADY_REGISTERED = "Вы уже зарегистрированы. Нажмите /start, чтобы открыть меню."
INVITE_INVALID = (
    "Приглашение недействительно: истёк срок, его отозвали или оно уже использовано.\n\n"
    "Можно подать заявку на доступ — администратор рассмотрит её."
)


def ask_name(default_name: str) -> str:
    return (
        "Как вас записать? Напишите имя и фамилию одним сообщением"
        + (f" или нажмите «Оставить: {default_name}»." if default_name else ".")
    )


def keep_name_button(name: str) -> str:
    short = name if len(name) <= 40 else name[:39] + "…"
    return f"Оставить: {short}"


def request_sent(updated: bool) -> str:
    head = "Заявка обновлена." if updated else "Заявка отправлена."
    return head + " Администратор рассмотрит её, решение придёт сюда."


def request_pending(full_name: str, department: str | None, created: str) -> str:
    lines = ["Ваша заявка на доступ на рассмотрении.", "", f"Имя: {full_name}"]
    if department:
        lines.append(f"Подразделение: {department}")
    lines.append(f"Подана: {created}")
    lines += ["", "Решение придёт сюда. Можно поправить заявку, пока её не рассмотрели."]
    return "\n".join(lines)


def request_rejected(reason: str | None) -> str:
    text = "Ваша заявка на доступ отклонена."
    if reason:
        text += f"\nПричина: {reason}"
    return text + "\n\nМожно подать заявку снова."
ACCESS_DISABLED = "Доступ отключён. Обратитесь к администратору."
BTN_OPEN_ACCESS_REQUESTS = "Открыть заявки"
ALREADY_IN = "Доступ уже открыт. Выберите действие в меню ниже."
FORM_NEEDS_TEXT = "Ответьте, пожалуйста, текстом — заявка ещё не отправлена."
