"""HTML-виджеты Telegram (Bot API 10.4, `sendWidget`): карточки вместо простого текста.

aiogram 3.31 метода ещё не знает, поэтому он описан здесь своим `TelegramMethod`.
Код виджета (HTML) неизменен; данные карточки идут в `chat_data` (JSON до 1024 байт) и читаются
скриптом виджета из `TelegramWidget.chatData`.

Подпись (`caption`) — тот же HTML-текст, что бот отправлял раньше: его видят клиенты без поддержки
виджетов, он же идёт в уведомления и список чатов. Если Telegram отклонил виджет (старый Bot API,
неподдерживаемый чат, длинная подпись), бот отправляет этот текст обычным сообщением — поток не ломается.
"""

import json
import logging
from typing import Any

from aiogram import Bot
from aiogram.exceptions import TelegramBadRequest, TelegramNotFound
from aiogram.methods.base import TelegramMethod
from aiogram.types import Message, ReplyMarkupUnion

from app.config import Settings

log = logging.getLogger(__name__)

CAPTION_LIMIT = 1024
# Bot API без sendWidget (метод не найден) — больше не пробуем до перезапуска: иначе лишний запрос на каждое сообщение.
_unsupported = False
DATA_LIMIT = 1024


class SendWidget(TelegramMethod[Message]):
    """https://core.telegram.org/bots/api#sendwidget"""

    __returning__ = Message
    __api_method__ = "sendWidget"

    chat_id: int | str
    html: str
    width: int | None = None
    height: int | None = None
    chat_data: str | None = None
    caption: str | None = None
    parse_mode: str | None = None
    show_caption_above_media: bool | None = None
    disable_notification: bool | None = None
    reply_markup: ReplyMarkupUnion | None = None


def reset() -> None:
    """Снова пробовать виджеты (для тестов)."""
    global _unsupported
    _unsupported = False


def pack(data: dict[str, Any], shrink: str | None = None) -> str:
    """JSON для chat_data. Не влезает в 1024 байта — укорачиваем поле `shrink` (обычно суть обращения)."""
    raw = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    while len(raw.encode()) > DATA_LIMIT and shrink and data.get(shrink):
        data[shrink] = data[shrink][: max(len(data[shrink]) - 20, 0)].rstrip() + "…"
        if len(data[shrink]) <= 1:
            data[shrink] = ""
        raw = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    return raw


async def send_card(
    bot: Bot,
    settings: Settings,
    chat_id: int,
    *,
    html: str,
    data: str,
    caption: str,
    reply_markup: ReplyMarkupUnion | None = None,
) -> Message:
    """Виджет с подписью; при отказе Telegram — тот же текст обычным сообщением."""
    global _unsupported
    if settings.widgets_enabled and not _unsupported and len(caption) <= CAPTION_LIMIT:
        try:
            return await bot(
                SendWidget(
                    chat_id=chat_id,
                    html=html,
                    chat_data=data,
                    caption=caption,
                    parse_mode="HTML",
                    reply_markup=reply_markup,
                )
            )
        except (TelegramBadRequest, TelegramNotFound) as exc:
            if isinstance(exc, TelegramNotFound) or "method not found" in str(exc).lower():
                _unsupported = True
                log.warning("sendWidget is not supported by this Bot API, widgets off until restart: %s", exc)
            else:
                log.warning("sendWidget rejected, sending text instead: %s", exc)
    return await bot.send_message(chat_id=chat_id, text=caption, reply_markup=reply_markup)


# ------------------------------------------------------------------ шаблоны
# Оформление — как на сайте. Значения скопированы из web/src/styles/global.css (переменные :root и тёмной
# темы, классы .badge, .badge--status-*, .badge--due-*, .type-icon--*, .btn--accent, .sheet__title/.sheet__sub)
# и design/tokens.json. web/ не импортируется: при смене токенов на сайте обновить и здесь.
# Светлая или тёмная тема — по prefers-color-scheme: внутри виджета он следует теме чата Telegram.
# Шрифт — системный: именованные шрифты (Manrope сайта) Telegram из виджетов вырезает.

_TOKENS = (
    ":root{color-scheme:light dark;"
    "--surface:#fff;--surface-3:#e6eaf0;--text:#323a47;--heading:#082742;--muted:#5a6a82;"
    "--accent:#e40000;--accent-text:#fff;"
    "--danger:#b3261e;--danger-bg:#fdecea;--warn:#9a4a00;--warn-bg:#ffefe0;--success:#17703a;--success-bg:#e5f4ea;"
    "--s-new:#1a62c4;--s-new-bg:#e6f0fc;--s-in_review:#082742;--s-in_review-bg:#e3eaf2;"
    "--s-awaiting_info:#9a4a00;--s-awaiting_info-bg:#ffefe0;--s-in_progress:#5a3db8;--s-in_progress-bg:#eee9fb;"
    "--s-implemented:#17703a;--s-implemented-bg:#e5f4ea;--s-rejected:#b3261e;--s-rejected-bg:#fdecea;"
    "--s-closed:#4f5b6b;--s-closed-bg:#edeff2}"
    "@media (prefers-color-scheme:dark){:root{"
    "--surface:#202020;--surface-3:#2c2c2c;--text:#e8e8e8;--heading:#fff;--muted:#a6a6a6;"
    "--danger:#ff8a80;--danger-bg:#3d1b1b;--warn:#f7b57a;--warn-bg:#3a2614;--success:#7fd39a;--success-bg:#143222;"
    "--s-new:#8dbbf5;--s-new-bg:#12304f;--s-in_review:#e0e0e0;--s-in_review-bg:#343434;"
    "--s-awaiting_info:#f7b57a;--s-awaiting_info-bg:#3a2614;--s-in_progress:#b9a6f5;--s-in_progress-bg:#2a2148;"
    "--s-implemented:#7fd39a;--s-implemented-bg:#143222;--s-rejected:#ff9b92;--s-rejected-bg:#3d1b1b;"
    "--s-closed:#a6a6a6;--s-closed-bg:#262626}}"
)

_BASE_CSS = (
    _TOKENS
    + "body{margin:0;font:14px/1.4 system-ui,-apple-system,sans-serif;color:var(--text);background:var(--surface)}"
    ".w{padding:14px 16px 12px}"
    ".m{font-size:13px;color:var(--muted)}"
    ".bg{display:inline-flex;align-items:center;gap:6px;padding:3px 10px;border-radius:999px;font-size:12px;"
    "font-weight:600;line-height:1.5;white-space:nowrap;background:var(--surface-3);color:var(--text)}"
    ".dot:before{content:'';width:6px;height:6px;border-radius:50%;background:currentColor}"
    ".due_soon{background:var(--warn-bg);color:var(--warn)}.overdue{background:var(--danger-bg);color:var(--danger)}"
    ".answered{background:var(--success-bg);color:var(--success)}"
)

_ESCAPE_JS = (
    "function e(s){return String(s==null?'':s).replace(/[&<>\"]/g,function(c){"
    "return{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]})}"
    "var W=window.TelegramWidget||{};"
    "function D(){try{return JSON.parse(W.chatData||'{}')}catch(x){return{}}}"
)

# Значки типа — lucide (как TypeIcon на сайте): circle-alert, lightbulb, heart.
_ICONS_JS = (
    "var IC={problem:'<circle cx=\"12\" cy=\"12\" r=\"10\"/><path d=\"M12 8v4M12 16h.01\"/>',"
    "suggestion:'<path d=\"M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5M9 18h6M10 22h4\"/>',"
    "praise:'<path d=\"M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.8 0-3 .5-4.5 2-1.5-1.5-2.7-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7Z\"/>'};"
    "function icon(t){return '<span class=\"ti '+e(t)+'\"><svg width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" "
    "stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">'+(IC[t]||IC.problem)+'</svg></span>'}"
)

# Карточка обращения — как шапка карточки на сайте (.sheet): бейджи статуса и срока, значок типа,
# суть заголовком, «A-021 · Проблема · категория · приоритет …», ответственный, полоса этапов.
# chat_data: {h: заголовок, n: номер, t: код типа, k: тип, c: категория, p: приоритет, st: код статуса,
#             sl: подпись статуса, a: ответственный, d: срок, ds: состояние срока, dl: подпись состояния, s: суть}
APPEAL_CARD = (
    "<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width\"><style>"
    + _BASE_CSS
    + "".join(f".s-{c}{{background:var(--s-{c}-bg);color:var(--s-{c})}}" for c in (
        "new", "in_review", "awaiting_info", "in_progress", "implemented", "rejected", "closed"))
    + ".hd{display:flex;flex-wrap:wrap;gap:6px;margin:6px 0 12px}"
    ".ld{display:flex;gap:12px;align-items:flex-start}"
    ".ti{flex:none;display:grid;place-items:center;width:40px;height:40px;border-radius:50%;"
    "background:var(--warn-bg);color:var(--warn)}"
    ".ti.suggestion{background:var(--s-in_progress-bg);color:var(--s-in_progress)}"
    ".ti.praise{background:var(--success-bg);color:var(--success)}"
    ".tt{font-size:17px;font-weight:500;line-height:1.25;letter-spacing:-.02em;color:var(--heading)}"
    ".sb{margin-top:4px;font-size:13px;color:var(--muted)}"
    ".as{margin-top:10px}.as b{font-weight:600;color:var(--text)}"
    ".st{display:flex;gap:4px;margin:12px 0 4px}"
    ".st i{flex:1;height:4px;border-radius:2px;background:var(--surface-3)}"
    ".sl{display:flex;justify-content:space-between;font-size:11px;color:var(--muted)}"
    "</style></head><body><div class=\"w\" id=\"r\"></div><script>"
    + _ESCAPE_JS
    + _ICONS_JS
    + "var NAMES=['Новое','Рассмотрение','В работе','Готово'],"
    "AT={new:0,in_review:1,awaiting_info:1,in_progress:2,implemented:3,closed:3};"
    "function render(){var d=D(),i=AT[d.st],h='';"
    "if(d.h)h+='<div class=\"m\">'+e(d.h)+'</div>';"
    "h+='<div class=\"hd\"><span class=\"bg dot s-'+e(d.st)+'\">'+e(d.sl)+'</span>';"
    "if(d.dl)h+='<span class=\"bg '+e(d.ds)+'\">'+e(d.dl)+(d.d?' · до '+e(d.d):'')+'</span>';"
    "h+='</div><div class=\"ld\">'+icon(d.t)+'<div><div class=\"tt\">'+e(d.s||('Обращение '+d.n))+'</div>';"
    "var sub=[d.n,d.k,d.c,d.p?'приоритет '+String(d.p).toLowerCase():''].filter(Boolean);"
    "h+='<div class=\"sb\">'+e(sub.join(' · '))+'</div></div></div>';"
    "if(d.a)h+='<div class=\"as m\">Ответственный: <b>'+e(d.a)+'</b></div>';"
    "if(i!=null){h+='<div class=\"st\">';for(var j=0;j<4;j++)h+='<i'+(i>=j?' style=\"background:var(--s-'+e(d.st)+')\"':'')+'></i>';"
    "h+='</div><div class=\"sl\">';for(j=0;j<4;j++)h+='<span>'+NAMES[j]+'</span>';h+='</div>'}"
    "document.getElementById('r').innerHTML=h}"
    "render();if(W.onEvent)W.onEvent('chatDataChanged',render);if(W.ready)W.ready();"
    "</script></body></html>"
)

# Код входа: крупные цифры и бейдж срока действия в цветах .badge--due-*: обычный → «скоро»
# (последняя минута) → «просрочено». Копирует код кнопка Telegram под виджетом (copy_text):
# виджеты в проде идут с защитой контента, и copyText изнутри Telegram запрещает
# («копирование и пересылка отключены в этом чате»).
# chat_data: {c: код, e: истекает (мс с эпохи)}
LOGIN_CODE = (
    "<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width\"><style>"
    + _BASE_CSS
    + ".w{text-align:center}"
    ".c{font:600 34px/1.2 ui-monospace,monospace;letter-spacing:8px;margin:6px 0 12px;color:var(--heading)}"
    ".c.x{opacity:.35;text-decoration:line-through}"
    ".t{margin-top:4px}"
    "</style></head><body><div class=\"w\"><div class=\"m\">Код входа в «Модус Трейд»</div>"
    "<div class=\"c\" id=\"c\"></div>"
    "<div class=\"t\"><span class=\"bg\" id=\"t\"></span></div></div><script>"
    + _ESCAPE_JS
    + "var d=D(),c=document.getElementById('c'),t=document.getElementById('t');"
    "c.textContent=d.c||'';"
    "function tick(){var s=Math.round(((d.e||0)-Date.now())/1000);"
    "if(s<=0){t.textContent='Код истёк — запросите новый';t.className='bg overdue';c.className='c x';return false}"
    "t.className=s<=60?'bg due_soon':'bg';"
    "t.textContent='Действует ещё '+Math.floor(s/60)+':'+('0'+s%60).slice(-2);return true}"
    "if(tick()&&typeof setInterval==='function'){var iv=setInterval(function(){if(!tick())clearInterval(iv)},1000)}"
    "if(W.ready)W.ready();"
    "</script></body></html>"
)
