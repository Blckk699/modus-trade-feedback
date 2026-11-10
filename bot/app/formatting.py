"""Оформление черновика и созданного обращения. Подписи перечислений — из GET /dictionaries."""

import html
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
