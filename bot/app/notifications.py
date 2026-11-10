"""T-04: доставка уведомлений из очереди бэкенда и ответы на них.

Очередь: GET /bot/notifications/pending → sendMessage → ack (с telegram_message_id) или fail.
fail без permanent — бэкенд вернёт уведомление позже с паузой; permanent — пользователь заблокировал бота.
Кнопки: open_* — Mini App, reply_clarification — ответ в переписку, name_consent_* — согласие на имя.
"""

import asyncio
import html
import logging
from typing import Any

from aiogram import Bot, F, Router
from aiogram.exceptions import (
    TelegramAPIError,
    TelegramBadRequest,
    TelegramForbiddenError,
    TelegramNotFound,
    TelegramRetryAfter,
)
from aiogram.filters import StateFilter
from aiogram.filters.callback_data import CallbackData
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import CallbackQuery, InlineKeyboardButton, InlineKeyboardMarkup, Message, WebAppInfo

from app import texts
from app.api import Api, ApiError
from app.config import Settings

log = logging.getLogger(__name__)

APPEAL_KEY = "reply_appeal_id"
NUMBER_KEY = "reply_appeal_number"


class NotifCb(CallbackData, prefix="n"):
    action: str  # reply | consent
    appeal_id: int = 0
    discussion_id: int = 0
    show: int = 0
    number: str = ""


class ClarificationReply(StatesGroup):
    waiting = State()


# ------------------------------------------------------------------ доставка


def notification_keyboard(notification: dict[str, Any], settings: Settings) -> InlineKeyboardMarkup | None:
    rows: list[list[InlineKeyboardButton]] = []
    number = (notification.get("appeal") or {}).get("number", "")
    has_open_button = False
    for button in notification.get("buttons", []):
        kind, text = button["type"], button["text"]
        if kind == "open_appeal" and button.get("appeal_id"):
            url = settings.mini_app_link(f"/appeals/{button['appeal_id']}")
        elif kind == "open_discussion" and button.get("discussion_id"):
            url = settings.mini_app_link(f"/discussions/{button['discussion_id']}")
        elif kind == "open_analytics":
            url = settings.mini_app_link("/analytics")
        elif kind == "reply_clarification" and button.get("appeal_id"):
            data = NotifCb(action="reply", appeal_id=button["appeal_id"], number=number)
            rows.append([InlineKeyboardButton(text=text, callback_data=data.pack())])
            continue
        elif kind in ("name_consent_show", "name_consent_hide") and button.get("discussion_id"):
            data = NotifCb(
                action="consent",
                discussion_id=button["discussion_id"],
                show=int(kind == "name_consent_show"),
                number=number,
            )
            rows.append([InlineKeyboardButton(text=text, callback_data=data.pack())])
            continue
        else:
            log.warning("unknown notification button %s", button)
            continue
        if url:  # без MINI_APP_URL кнопки перехода не показываем
            rows.append([InlineKeyboardButton(text=text, web_app=WebAppInfo(url=url))])
            has_open_button = True
    # Утренняя сводка ведёт на экран аналитики, даже если бэкенд не прислал кнопку.
    if notification.get("kind") == "digest" and not has_open_button and settings.mini_app_url:
        url = settings.mini_app_link("/analytics")
        rows.append([InlineKeyboardButton(text=texts.BTN_OPEN_ANALYTICS, web_app=WebAppInfo(url=url))])
        has_open_button = True
    # Каждое уведомление по обращению ведёт к карточке, даже если бэкенд не прислал такую кнопку.
    appeal = notification.get("appeal")
    if appeal and not has_open_button and settings.mini_app_url:
        url = settings.mini_app_link(f"/appeals/{appeal['id']}")
        rows.append([InlineKeyboardButton(text=texts.BTN_OPEN_APPEAL, web_app=WebAppInfo(url=url))])
    return InlineKeyboardMarkup(inline_keyboard=rows) if rows else None


async def deliver(bot: Bot, api: Api, settings: Settings, notification: dict[str, Any]) -> bool:
    """Отправить одно уведомление и отчитаться бэкенду. True — доставлено."""
    nid = notification["id"]
    chat_id = notification["recipient"]["telegram_id"]
    markup = notification_keyboard(notification, settings)
    try:
        try:
            sent = await bot.send_message(chat_id=chat_id, text=notification["text"], reply_markup=markup)
        except TelegramBadRequest as exc:
            if "can't parse entities" not in str(exc).lower():
                raise
            # Неэкранированный «<» в тексте: иначе уведомление вечно уходило бы в fail. Шлём простым текстом.
            log.warning("notification %s: bad HTML, sending as plain text: %s", nid, exc)
            sent = await bot.send_message(
                chat_id=chat_id, text=notification["text"], reply_markup=markup, parse_mode=None
            )
    except TelegramForbiddenError as exc:  # бот заблокирован или пользователь не начинал диалог
        await _fail(api, nid, str(exc), permanent=True)
        return False
    except TelegramRetryAfter as exc:
        await _fail(api, nid, f"retry after {exc.retry_after}s", permanent=False)
        raise  # остановить проход по очереди, Telegram просит подождать
    except (TelegramBadRequest, TelegramNotFound) as exc:
        permanent = "chat not found" in str(exc).lower()
        await _fail(api, nid, str(exc), permanent=permanent)
        return False
    except TelegramAPIError as exc:
        await _fail(api, nid, str(exc), permanent=False)
        return False
    try:
        await api.ack_notification(nid, sent.message_id)
    except ApiError as exc:  # бэкенд вернёт уведомление ещё раз — лучше дубль, чем потеря
        log.warning("ack %s failed: %s", nid, exc)
    return True


async def _fail(api: Api, nid: int, error: str, permanent: bool) -> None:
    log.info("notification %s not delivered (permanent=%s): %s", nid, permanent, error)
    try:
        await api.fail_notification(nid, error, permanent)
    except ApiError as exc:
        log.warning("fail %s not reported: %s", nid, exc)


async def deliver_pending(bot: Bot, api: Api, settings: Settings) -> int:
    """Один проход по очереди. Возвращает число доставленных."""
    notifications = await api.pending_notifications()
    delivered = 0
    for notification in notifications:
        try:
            delivered += await deliver(bot, api, settings, notification)
        except TelegramRetryAfter as exc:
            await asyncio.sleep(exc.retry_after)
            break
    return delivered


async def poll_forever(bot: Bot, api: Api, settings: Settings) -> None:
    while True:
        try:
            await deliver_pending(bot, api, settings)
        except ApiError as exc:
            log.warning("notification queue unavailable: %s", exc)
        except Exception:
            log.exception("notification delivery pass failed")
        await asyncio.sleep(settings.notifications_poll_seconds)


# ------------------------------------------------------------------ ответы на уведомления


def _reply_target(message: Message) -> NotifCb | None:
    """Ответ свайпом на уведомление с кнопкой «Ответить»: берём обращение из её callback_data."""
    replied = message.reply_to_message
    if replied is None or replied.reply_markup is None:
        return None
    for row in replied.reply_markup.inline_keyboard:
        for button in row:
            if button.callback_data and button.callback_data.startswith(NotifCb.__prefix__ + ":"):
                data = NotifCb.unpack(button.callback_data)
                if data.action == "reply":
                    return data
    return None


async def on_reply_button(callback: CallbackQuery, callback_data: NotifCb, state: FSMContext) -> None:
    await state.set_state(ClarificationReply.waiting)
    await state.update_data({APPEAL_KEY: callback_data.appeal_id, NUMBER_KEY: callback_data.number})
    await callback.message.answer(texts.ask_clarification(html.escape(callback_data.number)))
    await callback.answer()


async def on_reply_text(message: Message, state: FSMContext, api: Api) -> None:
    target = _reply_target(message)
    if target is not None:
        appeal_id, number = target.appeal_id, target.number
    else:
        data = await state.get_data()
        appeal_id, number = data.get(APPEAL_KEY), data.get(NUMBER_KEY, "")
    if not appeal_id:
        await state.set_state(None)
        return
    try:
        await api.post_message(message.from_user.id, appeal_id, message.text)
    except ApiError as exc:
        await message.answer(html.escape(exc.message))
        if exc.code in {"invalid_transition", "forbidden", "not_found"}:
            await state.set_state(None)
        return
    await state.set_state(None)
    await message.answer(texts.clarification_sent(html.escape(number)))


async def on_consent(callback: CallbackQuery, callback_data: NotifCb, api: Api) -> None:
    show = bool(callback_data.show)
    try:
        await api.set_name_consent(callback.from_user.id, callback_data.discussion_id, show)
    except ApiError as exc:
        await callback.answer(exc.message[:200], show_alert=True)
        return
    await callback.message.edit_reply_markup(reply_markup=None)
    await callback.message.answer(texts.NAME_SHOWN if show else texts.NAME_HIDDEN)
    await callback.answer()


def is_reply_to_clarification(message: Message) -> bool:
    return _reply_target(message) is not None


def build_router() -> Router:
    router = Router(name="notifications")
    router.callback_query.register(on_reply_button, NotifCb.filter(F.action == "reply"))
    router.callback_query.register(on_consent, NotifCb.filter(F.action == "consent"))
    router.message.register(on_reply_text, F.text, F.func(is_reply_to_clarification))
    router.message.register(on_reply_text, StateFilter(ClarificationReply.waiting), F.text, ~F.text.startswith("/"))
    return router
