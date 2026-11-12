"""Оформление черновика и созданного обращения. Подписи перечислений — из GET /dictionaries."""

import html
import re
import time
from datetime import datetime
from typing import Any

MONTHS = [
    "января", "февраля", "марта", "апреля", "мая", "июня",
    "июля", "августа", "сентября", "октября", "ноября", "декабря",
]
TEXT_LIMIT = 1500
# Подписи состояния срока — как web/src/appeals/labels.ts (dueStateLabel): в /dictionaries их нет.
DUE_STATE_LABELS = {
    "on_time": "В срок",
    "due_soon": "Срок скоро",
    "overdue": "Просрочено",
    "answered": "Ответ дан",
}


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
    status = appeal.get("status") or "new"
    due_state = appeal.get("due_state") or ("on_time" if appeal.get("first_response_due_at") else "")
    if status == "closed" or due_state == "no_deadline":  # как на сайте: у закрытых и бессрочных срока не показываем
        due_state = ""
    data = {
        "h": header or "",
        "n": appeal["number"],
        "t": appeal.get("type") or "problem",
        "k": label(dictionaries, "appeal_types", appeal.get("type")),
        "c": (appeal.get("category") or {}).get("name", ""),
        "p": label(dictionaries, "priorities", appeal["priority"]) if appeal.get("priority") else "",
        "st": status,
        "sl": label(dictionaries, "statuses", status),
        "a": assignee.get("full_name", ""),
        "ds": due_state,
        "dl": DUE_STATE_LABELS.get(due_state, ""),
        "d": due_text(appeal["first_response_due_at"])
        if appeal.get("first_response_due_at") and due_state not in ("", "answered")
        else "",
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
    return pack({"c": code, "e": int(expires * 1000), "l": ttl_seconds})


def draft_card_data(
    draft: dict[str, Any], dictionaries: dict[str, Any], state: str = "", number: str = ""
) -> str:
    """chat_data виджета черновика (widgets.DRAFT_CARD). state: '' | sent | cancelled."""
    from app.widgets import pack

    data = {
        "t": draft.get("type") or "problem",
        "k": label(dictionaries, "appeal_types", draft.get("type")),
        "c": (draft.get("category") or {}).get("name", ""),
        "p": label(dictionaries, "priorities", draft.get("priority")),
        "s": draft.get("summary") or "",
        "q": draft.get("text") or "",
        "o": draft.get("proposed_solution") or "",
        "v": 1 if draft.get("transcript") else 0,
        "f": draft.get("forwarded_from") or "",
        "x": state,
        "n": number,
    }
    return pack(data, shrink=("q", "o", "s"))


def short_day(iso: str | None) -> str:
    """'2026-11-12T10:00:00+05:00' → '12 ноября'."""
    if not iso:
        return ""
    try:
        moment = datetime.fromisoformat(iso)
    except ValueError:
        return ""
    return f"{moment.day} {MONTHS[moment.month - 1]}"


def appeal_list_data(page: dict[str, Any], dictionaries: dict[str, Any]) -> str:
    """chat_data виджета «Мои обращения» (widgets.APPEAL_LIST). Не влезает в 1024 байта — короче суть, меньше строк."""
    from app.widgets import DATA_LIMIT, _dump

    items = page["items"]
    statuses = {item["status"] for item in items}
    labels = {code: label(dictionaries, "statuses", code) for code in sorted(statuses)}

    def build(clip: int, count: int) -> str:
        rows = []
        for item in items[:count]:
            summary = item.get("summary") or ""
            if len(summary) > clip:
                summary = summary[: clip - 1].rstrip() + "…"
            rows.append([
                item["number"], item.get("type") or "problem", item["status"], summary,
                short_day(item.get("created_at")), 1 if item.get("has_unread") else 0,
            ])
        return _dump({"T": page.get("total", len(items)), "L": labels, "i": rows})

    count = len(items)
    for clip in (90, 60, 40):
        raw = build(clip, count)
        if len(raw.encode()) <= DATA_LIMIT:
            return raw
    while count > 1 and len(raw.encode()) > DATA_LIMIT:
        count -= 1
        raw = build(40, count)
    return raw


_SUMMARY_QUOTE = re.compile(r"(</b>) «.*?»(?=[ .,:;!?\n]|$)", re.DOTALL)
_CARD_LINES = ("Ответственный:", "Срок первого ответа:")


def card_caption(text: str) -> str:
    """Подпись под карточкой уведомления: текст бэкенда без того, что уже есть в карточке.

    Убираем суть в кавычках после номера и строки «Ответственный» и «Срок первого ответа».
    Остаются событие и подробности, которых в карточке нет (комментарий к статусу, итог, сообщение).
    """
    short = _SUMMARY_QUOTE.sub(r"\1", text, count=1)
    lines = [line for line in short.split("\n") if not line.startswith(_CARD_LINES)]
    return "\n".join(lines).strip() or text


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
