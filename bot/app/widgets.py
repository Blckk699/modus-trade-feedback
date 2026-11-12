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
    if settings.widgets_enabled and len(caption) <= CAPTION_LIMIT:
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
            log.warning("sendWidget rejected, sending text instead: %s", exc)
    return await bot.send_message(chat_id=chat_id, text=caption, reply_markup=reply_markup)


# ------------------------------------------------------------------ шаблоны
# Шрифты — только системные (именованные Telegram вырезает), цвета — из темы чата (--tg-theme-*),
# фирменный красный — акцент. Сети, внешних картинок и форм в виджете нет.

_BASE_CSS = (
    ":root{color-scheme:light dark;--a:#E40000}"
    "body{margin:0;font:15px/1.35 system-ui,sans-serif;color:var(--tg-theme-text-color,#000);background:transparent}"
    ".w{padding:12px 14px}"
    ".m{font-size:13px;color:var(--tg-theme-hint-color,#888)}"
)

_ESCAPE_JS = (
    "function e(s){return String(s==null?'':s).replace(/[&<>\"]/g,function(c){"
    "return{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]})}"
    "var W=window.TelegramWidget||{};"
    "function D(){try{return JSON.parse(W.chatData||'{}')}catch(x){return{}}}"
)

# Карточка обращения: номер, статус плашкой, суть, ответственный и срок, полоса этапов.
# chat_data: {n: номер, k: тип, s: суть, st: код статуса, sl: подпись статуса, a: ответственный, d: срок, h: заголовок}
APPEAL_CARD = (
    "<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width\"><style>"
    + _BASE_CSS
    + ".h{display:flex;align-items:center;gap:8px}"
    ".n{font-weight:700;font-size:18px}"
    ".k{font-size:12px;color:var(--tg-theme-hint-color,#888)}"
    ".p{margin-left:auto;font-size:12px;font-weight:600;padding:3px 9px;border-radius:10px;background:var(--a);color:#fff;white-space:nowrap}"
    ".p.ok{background:#1F9D55}.p.no{background:var(--tg-theme-hint-color,#888)}"
    ".s{margin:8px 0 10px}"
    ".r{display:flex;gap:6px;margin-top:3px}.r b{font-weight:600;color:var(--tg-theme-text-color,#000)}"
    ".st{display:flex;gap:4px;margin:12px 0 4px}"
    ".st i{flex:1;height:4px;border-radius:2px;background:var(--tg-theme-secondary-bg-color,#8884)}"
    ".st i.on{background:var(--a)}.st.ok i.on{background:#1F9D55}"
    ".sl{display:flex;justify-content:space-between;font-size:11px;color:var(--tg-theme-hint-color,#888)}"
    "</style></head><body><div class=\"w\" id=\"r\"></div><script>"
    + _ESCAPE_JS
    + "var STEPS=['new','in_review','in_progress','implemented'],NAMES=['Новое','Рассмотрение','В работе','Готово'],"
    "AT={new:0,in_review:1,awaiting_info:1,in_progress:2,implemented:3,closed:3};"
    "function render(){var d=D(),i=AT[d.st],ok=d.st==='implemented'||d.st==='closed',no=d.st==='rejected',h='';"
    "if(d.h)h+='<div class=\"m\">'+e(d.h)+'</div>';"
    "h+='<div class=\"h\"><div><div class=\"n\">'+e(d.n)+'</div><div class=\"k\">'+e(d.k)+'</div></div>'"
    "+'<span class=\"p'+(ok?' ok':no?' no':'')+'\">'+e(d.sl)+'</span></div>';"
    "if(d.s)h+='<div class=\"s\">'+e(d.s)+'</div>';"
    "if(d.a)h+='<div class=\"r m\">Ответственный: <b>'+e(d.a)+'</b></div>';"
    "if(d.d)h+='<div class=\"r m\">Срок ответа: <b>'+e(d.d)+'</b></div>';"
    "if(!no){h+='<div class=\"st'+(ok?' ok':'')+'\">';for(var j=0;j<STEPS.length;j++)h+='<i class=\"'+(i>=j?'on':'')+'\"></i>';"
    "h+='</div><div class=\"sl\">';for(j=0;j<NAMES.length;j++)h+='<span>'+NAMES[j]+'</span>';h+='</div>'}"
    "document.getElementById('r').innerHTML=h}"
    "render();if(W.onEvent)W.onEvent('chatDataChanged',render);if(W.ready)W.ready();"
    "</script></body></html>"
)

# Код входа: крупные цифры, «Скопировать» (copyText) и обратный отсчёт до истечения.
# chat_data: {c: код, e: истекает (мс с эпохи)}
LOGIN_CODE = (
    "<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width\"><style>"
    + _BASE_CSS
    + ".w{text-align:center}"
    ".c{font:700 34px/1.2 ui-monospace,monospace;letter-spacing:8px;margin:6px 0 10px}"
    ".c.x{opacity:.35;text-decoration:line-through}"
    "button{font:600 15px system-ui,sans-serif;border:0;border-radius:10px;padding:9px 22px;background:var(--a);color:#fff}"
    "button:disabled{background:var(--tg-theme-hint-color,#888)}"
    ".t{margin-top:8px}"
    "</style></head><body><div class=\"w\"><div class=\"m\">Код входа в «Модус Трейд»</div>"
    "<div class=\"c\" id=\"c\"></div><button id=\"b\">Скопировать</button><div class=\"t m\" id=\"t\"></div></div><script>"
    + _ESCAPE_JS
    + "var d=D(),c=document.getElementById('c'),b=document.getElementById('b'),t=document.getElementById('t');"
    "c.textContent=d.c||'';"
    "b.onclick=function(){if(W.copyText&&d.c)W.copyText(String(d.c));"
    "if(W.HapticFeedback&&W.HapticFeedback.notificationOccurred)W.HapticFeedback.notificationOccurred('success')};"
    "function tick(){var s=Math.round(((d.e||0)-Date.now())/1000);"
    "if(s<=0){t.textContent='Код истёк — запросите новый в меню';c.className='c x';b.disabled=true;return false}"
    "t.textContent='Действует ещё '+Math.floor(s/60)+':'+('0'+s%60).slice(-2);return true}"
    "if(tick()&&typeof setInterval==='function'){var iv=setInterval(function(){if(!tick())clearInterval(iv)},1000)}"
    "if(W.ready)W.ready();"
    "</script></body></html>"
)
