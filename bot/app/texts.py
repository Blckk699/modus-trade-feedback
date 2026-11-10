"""Тексты и подписи кнопок бота. Названия кнопок упоминают другие клиенты (экран входа Flutter)."""

BTN_SUBMIT = "Подать обращение"
BTN_MY_APPEALS = "Мои обращения"
BTN_DIGEST = "Сводка"
BTN_LOGIN_CODE = "Код входа"
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
    if has_mini_app:
        lines.append(f"«{BTN_MY_APPEALS}» и кнопка «{BTN_OPEN_APP}» открывают приложение прямо в Telegram.")
    return "\n".join(lines)


SUBMIT_HINT = (
    "Опишите проблему или предложение одним сообщением: напишите текстом, наговорите голосовое "
    "или перешлите сообщение из рабочего чата. Я подготовлю черновик обращения, вы проверите и отправите."
)

MY_APPEALS = "Ваши обращения, их статусы и ответы — в приложении."
MY_APPEALS_BUTTON = "Открыть мои обращения"


def login_code(code: str, ttl_seconds: int) -> str:
    return (
        f"Ваш код входа: <code>{code}</code>\n\n"
        f"Введите его на экране входа в мобильном приложении «{APP_NAME}». "
        f"Код одноразовый и действует {ttl_text(ttl_seconds)}."
    )


USE_MENU = "Выберите действие в меню ниже."
