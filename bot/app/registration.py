"""T-09: незнакомый аккаунт — заявка на доступ и вход по приглашению.

Middleware пропускает незнакомого (`user_not_registered`) с `guest=True`; этот роутер подключён первым
и забирает все его обновления, поэтому остальные роутеры видят только заведённых пользователей.

- `/start inv_<токен>` — POST /invites/accept: действующее приглашение сразу открывает меню роли,
  недействительное (`410 invite_invalid`) — объяснение и кнопка «Подать заявку».
- `/start` и любое другое сообщение — статус из POST /access-requests/mine: форма, «на рассмотрении»,
  отказ с причиной.
- Форма: имя (по умолчанию из профиля) → подразделение кнопками → должность или комментарий → POST /access-requests.
"""

import html
import logging
from datetime import datetime
from typing import Any

from aiogram import Bot, F, Router
from aiogram.filters import CommandObject, CommandStart, Filter, StateFilter
from aiogram.filters.callback_data import CallbackData
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import (
    CallbackQuery,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    Message,
    ReplyKeyboardRemove,
    User,
)

from app import texts
from app.api import Api, ApiError
from app.config import Settings
from app.handlers import welcome

log = logging.getLogger(__name__)

INVITE_PREFIX = "inv_"
NAME_MAX = 120
COMMENT_MAX = 500


class RegCb(CallbackData, prefix="r"):
    action: str  # start | keep_name | dept | skip_comment
    department_id: int = 0  # 0 — «не знаю»


class Registration(StatesGroup):
    name = State()
    department = State()
    comment = State()


class Guest(Filter):
    """Обновление от аккаунта, которого нет среди пользователей (флаг ставит IdentifyUser)."""

    async def __call__(self, event: Any, guest: bool = False) -> bool:
        return guest


def request_button(text: str = texts.BTN_REQUEST_ACCESS) -> InlineKeyboardMarkup:
    data = RegCb(action="start").pack()
    return InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(text=text, callback_data=data)]])


def profile_name(user: User) -> str:
    return " ".join(p for p in (user.first_name, user.last_name) if p).strip()[:NAME_MAX]


# ------------------------------------------------------------------ статус и приглашение


async def on_start(
    message: Message, command: CommandObject, bot: Bot, state: FSMContext, api: Api, settings: Settings
) -> None:
    await state.clear()
    args = (command.args or "").strip()
    if args.startswith(INVITE_PREFIX):
        await accept_invite(message, args[len(INVITE_PREFIX) :], bot, api, settings)
        return
    await show_status(message, api)


async def accept_invite(message: Message, token: str, bot: Bot, api: Api, settings: Settings) -> None:
    user = message.from_user
    try:
        result = await api.accept_invite(user.id, token, profile_name(user) or None, user.username)
    except ApiError as exc:
        if exc.code in {"invite_invalid", "not_found", "validation_error"}:
            await message.answer(texts.INVITE_INVALID, reply_markup=request_button())
        elif exc.code == "already_registered":
            await message.answer(texts.ALREADY_REGISTERED)
        else:
            await message.answer(html.escape(exc.message))
        return
    await welcome(message, bot, result["user"], settings)


async def show_status(message: Message, api: Api, user_id: int | None = None) -> None:
    """Экран по состоянию заявки. `user_id` — для нажатия кнопки, где `message` — сообщение бота."""
    try:
        status = await api.access_status(user_id or message.from_user.id)
    except ApiError as exc:
        await message.answer(html.escape(exc.message), reply_markup=ReplyKeyboardRemove())
        return
    state, request = status["state"], status.get("request") or {}
    if state == "pending":
        department = (request.get("department") or {}).get("name")
        text = texts.request_pending(
            html.escape(request.get("full_name", "")),
            html.escape(department) if department else None,
            _date(request.get("created_at")),
        )
        await message.answer(text, reply_markup=request_button(texts.BTN_EDIT_REQUEST))
    elif state == "rejected":
        reason = request.get("reject_reason")
        text = texts.request_rejected(html.escape(reason) if reason else None)
        await message.answer(text, reply_markup=request_button(texts.BTN_REQUEST_AGAIN))
    elif state == "registered":  # заявку одобрили между запросами — меню откроет следующий /start
        await message.answer(texts.ALREADY_REGISTERED)
    elif state == "disabled":
        await message.answer(texts.ACCESS_DISABLED, reply_markup=ReplyKeyboardRemove())
    else:  # none
        await message.answer(texts.REQUEST_INTRO, reply_markup=request_button())


def _date(value: str | None) -> str:
    if not value:
        return ""
    try:
        return datetime.fromisoformat(value).strftime("%d.%m.%Y %H:%M")
    except ValueError:
        return value


# ------------------------------------------------------------------ форма заявки


async def on_request_start(callback: CallbackQuery, state: FSMContext) -> None:
    default = profile_name(callback.from_user)
    await state.clear()
    await state.set_state(Registration.name)
    await state.update_data(full_name=default)
    markup = None
    if default:
        button = InlineKeyboardButton(
            text=texts.keep_name_button(default), callback_data=RegCb(action="keep_name").pack()
        )
        markup = InlineKeyboardMarkup(inline_keyboard=[[button]])
    await callback.message.answer(texts.ask_name(html.escape(default)), reply_markup=markup)
    await callback.answer()


async def on_name_text(message: Message, state: FSMContext, api: Api) -> None:
    name = " ".join(message.text.split())
    if not 1 <= len(name) <= NAME_MAX:
        await message.answer(texts.NAME_INVALID)
        return
    await state.update_data(full_name=name)
    await ask_department(message, state, api)


async def on_keep_name(callback: CallbackQuery, state: FSMContext, api: Api) -> None:
    await callback.answer()
    await ask_department(callback.message, state, api)


async def ask_department(message: Message, state: FSMContext, api: Api) -> None:
    try:
        departments = await api.access_departments()
    except ApiError as exc:  # без списка заявку всё равно можно подать: подразделение назначит администратор
        log.warning("access departments unavailable: %s", exc)
        departments = []
    if not departments:
        await state.update_data(department_id=None)
        await ask_comment(message, state)
        return
    await state.set_state(Registration.department)
    buttons = [
        InlineKeyboardButton(text=d["name"], callback_data=RegCb(action="dept", department_id=d["id"]).pack())
        for d in departments
    ]
    rows = [buttons[i : i + 2] for i in range(0, len(buttons), 2)]
    rows.append(
        [InlineKeyboardButton(text=texts.BTN_NO_DEPARTMENT, callback_data=RegCb(action="dept").pack())]
    )
    await message.answer(texts.ASK_DEPARTMENT, reply_markup=InlineKeyboardMarkup(inline_keyboard=rows))


async def on_department(callback: CallbackQuery, callback_data: RegCb, state: FSMContext) -> None:
    await state.update_data(department_id=callback_data.department_id or None)
    await callback.message.edit_reply_markup(reply_markup=None)
    await callback.answer()
    await ask_comment(callback.message, state)


async def on_department_text(message: Message) -> None:
    await message.answer(texts.CHOOSE_DEPARTMENT)


async def ask_comment(message: Message, state: FSMContext) -> None:
    await state.set_state(Registration.comment)
    data = RegCb(action="skip_comment").pack()
    markup = InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(text=texts.BTN_SKIP, callback_data=data)]])
    await message.answer(texts.ASK_COMMENT, reply_markup=markup)


async def on_comment_text(message: Message, state: FSMContext, api: Api) -> None:
    comment = message.text.strip()
    if len(comment) > COMMENT_MAX:
        await message.answer(texts.COMMENT_TOO_LONG)
        return
    await submit(message, message.from_user, state, api, comment or None)


async def on_skip_comment(callback: CallbackQuery, state: FSMContext, api: Api) -> None:
    await callback.answer()
    await submit(callback.message, callback.from_user, state, api, None)


async def submit(message: Message, user: User, state: FSMContext, api: Api, comment: str | None) -> None:
    data = await state.get_data()
    try:
        request = await api.submit_access_request(
            user.id, data.get("full_name") or profile_name(user), data.get("department_id"), comment, user.username
        )
    except ApiError as exc:
        if exc.code == "already_registered":
            await state.clear()
            await message.answer(texts.ALREADY_REGISTERED)
        elif exc.code == "validation_error":
            await message.answer(html.escape(exc.message))  # форма остаётся открытой: можно поправить
        else:
            await state.clear()
            await message.answer(html.escape(exc.message))
        return
    await state.clear()
    # 200 — обновлена заявка «на рассмотрении», 201 — новая: различаем по времени изменения.
    updated = request.get("updated_at") != request.get("created_at")
    await message.answer(texts.request_sent(updated=updated))


async def on_form_non_text(message: Message, state: FSMContext) -> None:
    """Фото, голос или стикер посреди формы: форму не сбрасываем, просим ответить текстом."""
    current = await state.get_state()
    hint = texts.CHOOSE_DEPARTMENT if current == Registration.department.state else texts.FORM_NEEDS_TEXT
    await message.answer(hint)


# ------------------------------------------------------------------ всё остальное от незнакомого


async def on_other_message(message: Message, state: FSMContext, api: Api) -> None:
    await state.clear()
    await show_status(message, api)


async def on_other_callback(callback: CallbackQuery, api: Api) -> None:
    await callback.answer()
    await show_status(callback.message, api, user_id=callback.from_user.id)


def build_router() -> Router:
    router = Router(name="registration")
    router.message.filter(Guest())
    router.callback_query.filter(Guest())
    router.message.register(on_start, CommandStart())
    router.callback_query.register(on_request_start, RegCb.filter(F.action == "start"))
    router.callback_query.register(on_keep_name, StateFilter(Registration.name), RegCb.filter(F.action == "keep_name"))
    router.callback_query.register(on_department, StateFilter(Registration.department), RegCb.filter(F.action == "dept"))
    router.callback_query.register(
        on_skip_comment, StateFilter(Registration.comment), RegCb.filter(F.action == "skip_comment")
    )
    router.message.register(on_name_text, StateFilter(Registration.name), F.text, ~F.text.startswith("/"))
    router.message.register(on_department_text, StateFilter(Registration.department), F.text, ~F.text.startswith("/"))
    router.message.register(on_comment_text, StateFilter(Registration.comment), F.text, ~F.text.startswith("/"))
    router.message.register(
        on_form_non_text,
        StateFilter(Registration.name, Registration.department, Registration.comment),
        ~F.text,
    )
    router.message.register(on_other_message)
    router.callback_query.register(on_other_callback)
    return router
