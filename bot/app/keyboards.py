"""Клавиатуры бота. Набор кнопок зависит от прав пользователя (Me.permissions) и настройки Mini App."""

from typing import Any

from aiogram.types import (
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    KeyboardButton,
    ReplyKeyboardMarkup,
    WebAppInfo,
)

from app import texts


def can_see_digest(me: dict[str, Any]) -> bool:
    return me.get("permissions", {}).get("analytics_scope", "none") != "none"


def main_menu(me: dict[str, Any], mini_app_url: str | None) -> ReplyKeyboardMarkup:
    first_row = [KeyboardButton(text=texts.BTN_SUBMIT), KeyboardButton(text=texts.BTN_MY_APPEALS)]
    second_row = []
    if can_see_digest(me):
        second_row.append(KeyboardButton(text=texts.BTN_DIGEST))
    second_row.append(KeyboardButton(text=texts.BTN_LOGIN_CODE))
    return ReplyKeyboardMarkup(keyboard=[first_row, second_row], resize_keyboard=True, is_persistent=True)


def open_mini_app(text: str, url: str) -> InlineKeyboardMarkup:
    # Inline-кнопка, а не кнопка клавиатуры: только так Mini App получает initData для автовхода.
    return InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(text=text, web_app=WebAppInfo(url=url))]])
