"""T-02: подача обращения текстом и пересылкой.

Сообщение → POST /drafts/text → карточка черновика с кнопками → правка полей → POST /appeals (source=bot).
Черновик живёт в FSM-хранилище диспетчера; на сервере он не хранится.
"""

import html
import logging
import secrets
from typing import Any

from aiogram import Bot, F, Router
from aiogram.filters import StateFilter
from aiogram.filters.callback_data import CallbackData
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import (
    CallbackQuery,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    Message,
    MessageOriginChannel,
    MessageOriginChat,
    MessageOriginHiddenUser,
    MessageOriginUser,
)

from app import formatting, keyboards, texts
from app.api import Api, ApiError
from app.config import Settings

log = logging.getLogger(__name__)

DRAFT_KEY = "draft"
CARD_KEY = "card_message_id"
VERSION_KEY = "draft_version"

EDITABLE_TEXT_FIELDS = {"text": texts.ASK_NEW_TEXT, "summary": texts.ASK_NEW_SUMMARY}


class DraftEdit(StatesGroup):
    text = State()
    summary = State()


class DraftCb(CallbackData, prefix="d"):
    v: str  # версия черновика: кнопки старой карточки не трогают новый черновик
    action: str
    value: str = ""


# ------------------------------------------------------------------ helpers


def forwarded_from(message: Message) -> str | None:
    origin = message.forward_origin
    if origin is None:
        return None
    if isinstance(origin, MessageOriginUser):
        user = origin.sender_user
        return " ".join(filter(None, [user.first_name, user.last_name]))
    if isinstance(origin, MessageOriginHiddenUser):
        return origin.sender_user_name
    if isinstance(origin, MessageOriginChat):
        return origin.sender_chat.title or texts.FORWARDED_UNKNOWN
    if isinstance(origin, MessageOriginChannel):
        return origin.chat.title or texts.FORWARDED_UNKNOWN
    return texts.FORWARDED_UNKNOWN


def card_keyboard(version: str) -> InlineKeyboardMarkup:
    def b(text: str, action: str) -> InlineKeyboardButton:
        return InlineKeyboardButton(text=text, callback_data=DraftCb(v=version, action=action).pack())

    return InlineKeyboardMarkup(
        inline_keyboard=[
            [b(texts.BTN_DRAFT_SEND, "send")],
            [b(texts.BTN_DRAFT_TYPE, "type"), b(texts.BTN_DRAFT_CATEGORY, "category"), b(texts.BTN_DRAFT_PRIORITY, "priority")],
            [b(texts.BTN_DRAFT_TEXT, "text"), b(texts.BTN_DRAFT_SUMMARY, "summary")],
            [b(texts.BTN_DRAFT_CANCEL, "cancel")],
        ]
    )


def choice_keyboard(version: str, action: str, options: list[tuple[str, str]], current: str) -> InlineKeyboardMarkup:
    rows = [
        [
            InlineKeyboardButton(
                text=("• " if value == current else "") + caption,
                callback_data=DraftCb(v=version, action=action, value=value).pack(),
            )
        ]
        for value, caption in options
    ]
    rows.append([InlineKeyboardButton(text=texts.BTN_BACK, callback_data=DraftCb(v=version, action="back").pack())])
    return InlineKeyboardMarkup(inline_keyboard=rows)


async def _drop_old_card(bot: Bot, chat_id: int, state: FSMContext) -> None:
    data = await state.get_data()
    if data.get(CARD_KEY):
        try:
            await bot.edit_message_reply_markup(chat_id=chat_id, message_id=data[CARD_KEY], reply_markup=None)
        except Exception:  # карточка могла быть удалена или уже без кнопок
            log.debug("old draft card not editable", exc_info=True)


async def _show_card(message: Message, bot: Bot, state: FSMContext, api: Api, draft: dict[str, Any]) -> None:
    await _drop_old_card(bot, message.chat.id, state)
    version = secrets.token_hex(3)
    dictionaries = await api.dictionaries()
    card = await message.answer(formatting.draft_card(draft, dictionaries), reply_markup=card_keyboard(version))
    await state.set_state(None)
    await state.set_data({DRAFT_KEY: draft, CARD_KEY: card.message_id, VERSION_KEY: version})


async def _rerender(callback: CallbackQuery, api: Api, draft: dict[str, Any], version: str) -> None:
    dictionaries = await api.dictionaries()
    await callback.message.edit_text(formatting.draft_card(draft, dictionaries), reply_markup=card_keyboard(version))


def _ai_unavailable_markup(settings: Settings) -> InlineKeyboardMarkup | None:
    if not settings.mini_app_url:
        return None
    return keyboards.open_mini_app(texts.BTN_OPEN_FORM, settings.mini_app_url)


# ------------------------------------------------------------------ handlers


async def new_draft(message: Message, bot: Bot, state: FSMContext, api: Api, me: dict[str, Any], settings: Settings) -> None:
    if not me.get("permissions", {}).get("can_create_appeal", False):
        await message.answer(texts.CANNOT_CREATE)
        return
    text = (message.text or message.caption or "").strip()
    if not text:
        await message.answer(texts.NEED_TEXT)
        return
    origin = forwarded_from(message)
    await bot.send_chat_action(message.chat.id, "typing")
    try:
        draft = await api.draft_from_text(message.from_user.id, text, origin)
    except ApiError as exc:
        markup = _ai_unavailable_markup(settings) if exc.code == "ai_unavailable" else None
        message_text = html.escape(exc.message)
        if exc.code == "ai_unavailable" and markup is None:
            message_text += "\n\n" + texts.FORM_ELSEWHERE
        await message.answer(message_text, reply_markup=markup)
        return
    draft["forwarded_from"] = origin
    await _show_card(message, bot, state, api, draft)


async def edited_field(message: Message, bot: Bot, state: FSMContext, api: Api) -> None:
    data = await state.get_data()
    draft = data.get(DRAFT_KEY)
    field = "text" if await state.get_state() == DraftEdit.text.state else "summary"
    new_value = (message.text or "").strip()
    if draft is None:
        await state.clear()
        await message.answer(texts.DRAFT_EXPIRED)
        return
    if not new_value:
        await message.answer(EDITABLE_TEXT_FIELDS[field])
        return
    draft[field] = new_value
    if field == "text":
        draft["transcript"] = None  # исправленный текст — уже не расшифровка голосового
    await _show_card(message, bot, state, api, draft)


async def on_draft_button(callback: CallbackQuery, callback_data: DraftCb, bot: Bot, state: FSMContext, api: Api) -> None:
    data = await state.get_data()
    draft = data.get(DRAFT_KEY)
    if draft is None or data.get(VERSION_KEY) != callback_data.v:
        await callback.answer(texts.DRAFT_EXPIRED, show_alert=True)
        try:
            await callback.message.edit_reply_markup(reply_markup=None)
        except Exception:
            log.debug("stale card not editable", exc_info=True)
        return

    action, value, version = callback_data.action, callback_data.value, callback_data.v
    user_id = callback.from_user.id

    if action == "send":
        await _send(callback, state, api, draft)
        return
    if action == "cancel":
        await state.clear()
        await callback.message.edit_text(texts.DRAFT_CANCELLED)
        await callback.answer()
        return
    if action == "back":
        await callback.message.edit_reply_markup(reply_markup=card_keyboard(version))
        await callback.answer()
        return
    if action in EDITABLE_TEXT_FIELDS:
        await state.set_state(DraftEdit.text if action == "text" else DraftEdit.summary)
        await callback.message.answer(EDITABLE_TEXT_FIELDS[action])
        await callback.answer()
        return

    dictionaries = await api.dictionaries()
    if action == "type":
        options = [(t["code"], t["label"]) for t in dictionaries.get("appeal_types", [])]
        markup = choice_keyboard(version, "set_type", options, draft["type"])
    elif action == "priority":
        options = [(p["code"], p["label"]) for p in dictionaries.get("priorities", [])]
        markup = choice_keyboard(version, "set_priority", options, draft["priority"])
    elif action == "category":
        try:
            categories = await api.categories(user_id)
        except ApiError as exc:
            await callback.answer(exc.message, show_alert=True)
            return
        options = [(str(c["id"]), c["name"]) for c in categories if c.get("is_active", True)]
        options.append(("none", texts.CATEGORY_UNKNOWN))
        current = str(draft["category"]["id"]) if draft.get("category") else "none"
        markup = choice_keyboard(version, "set_category", options, current)
    elif action == "set_type":
        draft["type"] = value
        markup = None
    elif action == "set_priority":
        draft["priority"] = value
        markup = None
    elif action == "set_category":
        if value == "none":
            draft["category"] = None
        else:
            categories = await api.categories(user_id)
            chosen = next((c for c in categories if str(c["id"]) == value), None)
            draft["category"] = {"id": chosen["id"], "name": chosen["name"]} if chosen else None
        markup = None
    else:
        await callback.answer()
        return

    if markup is not None:
        await callback.message.edit_reply_markup(reply_markup=markup)
    else:
        await state.update_data({DRAFT_KEY: draft})
        await _rerender(callback, api, draft, version)
    await callback.answer()


async def _send(callback: CallbackQuery, state: FSMContext, api: Api, draft: dict[str, Any]) -> None:
    body = {
        "type": draft["type"],
        "category_id": draft["category"]["id"] if draft.get("category") else None,
        "priority": draft["priority"],
        "text": draft["text"],
        "summary": draft.get("summary") or None,
        "proposed_solution": draft.get("proposed_solution"),
        "source": "bot",
        "forwarded_from": draft.get("forwarded_from"),
    }
    try:
        appeal = await api.create_appeal(callback.from_user.id, body)
    except ApiError as exc:
        await callback.answer(exc.message[:200], show_alert=True)
        return
    await state.clear()
    await callback.message.edit_reply_markup(reply_markup=None)
    await callback.message.answer(formatting.appeal_created(appeal))
    await callback.answer()


def build_router() -> Router:
    router = Router(name="drafts")
    router.message.register(edited_field, StateFilter(DraftEdit.text, DraftEdit.summary), F.text)
    router.message.register(new_draft, F.text | F.caption, ~F.text.startswith("/"))
    router.callback_query.register(on_draft_button, DraftCb.filter())
    return router
