"""Оформление черновика и созданного обращения. Подписи перечислений — из GET /dictionaries."""

import html
import time
from datetime import datetime
from typing import Any

MONTHS = [
    "января", "февраля", "марта", "апреля", "мая", "июня",
    "июля", "августа", "сентября", "октября", "ноября", "декабря",
]
TEXT_LIMIT = 1500


def label(dictionaries: dict[str, Any], group: str, code: str | None) -> str:
    for item in dictionaries.get(group, []):
        if item.get("code") == code:
            return item["label"]
    return code or ""


def due_text(iso: str) -> str:
    """'2026-11-13T18:00:00+05:00' → '13 ноября, 18:00' (время системы, как отдал сервер)."""
    moment = datetime.fromisoformat(iso)
    return f"{moment.day} {MONTHS[moment.month - 1]}, {moment:%H:%M}"


def _clip(text: str) -> str:
    return text if len(text) <= TEXT_LIMIT else text[: TEXT_LIMIT - 1] + "…"


def draft_card(draft: dict[str, Any], dictionaries: dict[str, Any]) -> str:
    e = html.escape
    category = draft.get("category")
    lines = [
        "<b>Черновик обращения</b>",
        "",
        f"<b>Тип:</b> {e(label(dictionaries, 'appeal_types', draft['type']))}",
        f"<b>Категория:</b> {e(category['name']) if category else 'не определена — назначит администратор'}",
        f"<b>Приоритет:</b> {e(label(dictionaries, 'priorities', draft['priority']))}",
        f"<b>Суть:</b> {e(draft.get('summary') or '')}",
    ]
    if draft.get("proposed_solution"):
        lines.append(f"<b>Предлагаемое решение:</b> {e(draft['proposed_solution'])}")
    if draft.get("forwarded_from"):
        lines.append(f"<b>Переслано из:</b> {e(draft['forwarded_from'])}")
    if draft.get("transcript"):
        lines += ["", "🎙 <b>Расшифровка голосового</b> — проверьте, что вас поняли верно:"]
    else:
        lines.append("")
    lines += [f"<blockquote>{e(_clip(draft['text']))}</blockquote>", "", "Проверьте и отправьте или поправьте поля."]
    return "\n".join(lines)


def appeal_created(appeal: dict[str, Any]) -> str:
    e = html.escape
    lines = [f"✅ Обращение <b>{e(appeal['number'])}</b> зарегистрировано.", ""]
    assignee = appeal.get("assignee")
    if assignee:
        lines.append(f"<b>Ответственный:</b> {e(assignee['full_name'])}")
    else:
        lines.append("<b>Ответственный:</b> назначит администратор")
    if appeal.get("first_response_due_at"):
        lines.append(f"<b>Срок первого ответа:</b> {due_text(appeal['first_response_due_at'])}")
    return "\n".join(lines)


def appeal_card_data(appeal: dict[str, Any], dictionaries: dict[str, Any], header: str | None = None) -> str:
    """chat_data карточки обращения (widgets.APPEAL_CARD). Принимает Appeal или AppealRef из контракта."""
    from app.widgets import pack

    assignee = appeal.get("assignee") or {}
    data = {
        "h": header or "",
        "n": appeal["number"],
        "k": label(dictionaries, "appeal_types", appeal.get("type")),
        "st": appeal.get("status") or "new",
        "sl": label(dictionaries, "statuses", appeal.get("status") or "new"),
        "a": assignee.get("full_name", ""),
        "d": due_text(appeal["first_response_due_at"]) if appeal.get("first_response_due_at") else "",
        "s": appeal.get("summary") or "",
    }
    return pack(data, shrink="s")


def login_code_data(code: str, expires_at: str, ttl_seconds: int) -> str:
    """chat_data виджета кода входа (widgets.LOGIN_CODE): код и момент истечения в мс."""
    from app.widgets import pack

    try:
        expires = datetime.fromisoformat(expires_at).timestamp()
    except ValueError:  # время сервера не разобрать — считаем от своих часов по ttl
        expires = time.time() + ttl_seconds
    return pack({"c": code, "e": int(expires * 1000)})


def my_appeals(page: dict[str, Any], dictionaries: dict[str, Any]) -> str:
    e = html.escape
    lines = ["<b>Мои обращения</b>", ""]
    for item in page["items"]:
        status = label(dictionaries, "statuses", item["status"])
        lines.append(f"<b>{e(item['number'])}</b> · {e(status)}")
        if item.get("summary"):
            lines.append(e(item["summary"]))
        lines.append("")
    if page["total"] > len(page["items"]):
        lines.append(f"Показаны последние {len(page['items'])} из {page['total']}. Все — в приложении.")
    return "\n".join(lines).rstrip()
