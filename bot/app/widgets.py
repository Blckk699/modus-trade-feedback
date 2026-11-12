"""HTML-виджеты Telegram (Bot API 10.4, `sendWidget`): карточки вместо простого текста.

aiogram 3.31 методов виджетов ещё не знает, поэтому они описаны здесь своими `TelegramMethod`.
Код виджета (HTML) неизменен; данные карточки идут в `chat_data` (JSON до 1024 байт) и читаются
скриптом виджета из `TelegramWidget.chatData`. Карточку черновика бот перерисовывает
`editMessageWidgetData` — новым `chat_data` у того же сообщения.

Подпись (`caption`) Telegram показывает под виджетом всем, поэтому она короткая и не повторяет карточку:
событие и что делать дальше. Полный прежний текст (`text`) уходит обычным сообщением, если Telegram
отклонил виджет (старый Bot API, неподдерживаемый чат) — поток не ломается.
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


class EditMessageWidgetData(TelegramMethod[bool]):
    """https://core.telegram.org/bots/api#editmessagewidgetdata — новый chat_data у отправленного виджета."""

    __returning__ = bool
    __api_method__ = "editMessageWidgetData"

    chat_id: int | str
    message_id: int
    chat_data: str


def reset() -> None:
    """Снова пробовать виджеты (для тестов)."""
    global _unsupported
    _unsupported = False


def _dump(data: dict[str, Any]) -> str:
    return json.dumps(data, ensure_ascii=False, separators=(",", ":"))


def pack(data: dict[str, Any], shrink: str | tuple[str, ...] | None = None) -> str:
    """JSON для chat_data. Не влезает в 1024 байта — укорачиваем поля `shrink`: сначала самое длинное
    из всех, кроме последнего, и только потом последнее (обычно это суть — её режем в крайнем случае)."""
    fields = (shrink,) if isinstance(shrink, str) else tuple(shrink or ())
    raw = _dump(data)
    while len(raw.encode()) > DATA_LIMIT:
        pool = [f for f in fields[:-1] if data.get(f)] or [f for f in fields[-1:] if data.get(f)]
        if not pool:
            break
        field = max(pool, key=lambda f: len(data[f]))
        data[field] = data[field][: max(len(data[field]) - 20, 0)].rstrip() + "…"
        if len(data[field]) <= 1:
            data[field] = ""
        raw = _dump(data)
    return raw


def is_widget(message: Message) -> bool:
    """Сообщение — виджет (у текстового есть text, у виджета только подпись)."""
    return message.text is None


async def send_card(
    bot: Bot,
    settings: Settings,
    chat_id: int,
    *,
    html: str,
    data: str,
    caption: str | None,
    text: str | None = None,
    reply_markup: ReplyMarkupUnion | None = None,
) -> Message:
    """Виджет с короткой подписью; при отказе Telegram — полный `text` (или подпись) обычным сообщением."""
    global _unsupported
    fallback = text or caption or ""
    if settings.widgets_enabled and not _unsupported and len(caption or "") <= CAPTION_LIMIT:
        try:
            return await bot(
                SendWidget(
                    chat_id=chat_id,
                    html=html,
                    chat_data=data,
                    caption=caption,
                    parse_mode="HTML" if caption else None,
                    reply_markup=reply_markup,
                )
            )
        except (TelegramBadRequest, TelegramNotFound) as exc:
            if isinstance(exc, TelegramNotFound) or "method not found" in str(exc).lower():
                _unsupported = True
                log.warning("sendWidget is not supported by this Bot API, widgets off until restart: %s", exc)
            else:
                log.warning("sendWidget rejected, sending text instead: %s", exc)
    return await bot.send_message(chat_id=chat_id, text=fallback, reply_markup=reply_markup)


async def edit_card(bot: Bot, chat_id: int, message_id: int, data: str) -> bool:
    """Перерисовать виджет новыми данными. False — Telegram не дал (тогда вызывающий шлёт карточку заново)."""
    try:
        await bot(EditMessageWidgetData(chat_id=chat_id, message_id=message_id, chat_data=data))
    except (TelegramBadRequest, TelegramNotFound) as exc:
        if "not modified" in str(exc).lower():
            return True
        log.warning("editMessageWidgetData rejected: %s", exc)
        return False
    return True


# ------------------------------------------------------------------ шаблоны
# Оформление — как на сайте. Значения скопированы из web/src/styles/global.css (переменные :root и тёмной
# темы, .badge, .badge--status-*, .badge--due-*, .type-icon--*, .avatar, .row, .tile--navy, .sheet__title)
# и web/src/app/Avatar.tsx (инициалы и цвет по имени). web/ не импортируется: при смене токенов на сайте
# обновить и здесь. Светлая или тёмная тема — по prefers-color-scheme: внутри виджета он следует теме чата.
# Шрифт — системный: именованные шрифты (Manrope сайта) Telegram из виджетов вырезает.
# Ограничения Telegram: HTML до 32 КБ и до 4 КБ после сжатия, без сети — проверяет tests/test_widgets.py.

STATUSES = ("new", "in_review", "awaiting_info", "in_progress", "implemented", "rejected", "closed")


def _min(code: str) -> str:
    """Склеить строки без отступов: в шаблонах каждая инструкция JS закончена `;` или `}`."""
    return "".join(line.strip() for line in code.strip().splitlines())


_TOKENS = _min("""
:root{color-scheme:light dark;
--surface:#fff;--surface-2:#f1f3f7;--surface-3:#e6eaf0;--line:#e2e6ec;
--text:#323a47;--heading:#082742;--muted:#5a6a82;--faint:#8591a3;--accent:#e40000;
--danger:#b3261e;--danger-bg:#fdecea;--warn:#9a4a00;--warn-bg:#ffefe0;--success:#17703a;--success-bg:#e5f4ea;
--s-new:#1a62c4;--s-new-bg:#e6f0fc;--s-in_review:#082742;--s-in_review-bg:#e3eaf2;
--s-awaiting_info:#9a4a00;--s-awaiting_info-bg:#ffefe0;--s-in_progress:#5a3db8;--s-in_progress-bg:#eee9fb;
--s-implemented:#17703a;--s-implemented-bg:#e5f4ea;--s-rejected:#b3261e;--s-rejected-bg:#fdecea;
--s-closed:#4f5b6b;--s-closed-bg:#edeff2;
--tile:linear-gradient(150deg,#082742 0%,#0f4a80 62%,#1a66c9 100%)}
@media (prefers-color-scheme:dark){:root{
--surface:#202020;--surface-2:#1b1b1b;--surface-3:#2c2c2c;--line:#2a2a2a;
--text:#e8e8e8;--heading:#fff;--muted:#a6a6a6;--faint:#808080;
--danger:#ff8a80;--danger-bg:#3d1b1b;--warn:#f7b57a;--warn-bg:#3a2614;--success:#7fd39a;--success-bg:#143222;
--s-new:#8dbbf5;--s-new-bg:#12304f;--s-in_review:#e0e0e0;--s-in_review-bg:#343434;
--s-awaiting_info:#f7b57a;--s-awaiting_info-bg:#3a2614;--s-in_progress:#b9a6f5;--s-in_progress-bg:#2a2148;
--s-implemented:#7fd39a;--s-implemented-bg:#143222;--s-rejected:#ff9b92;--s-rejected-bg:#3d1b1b;
--s-closed:#a6a6a6;--s-closed-bg:#262626;
--tile:linear-gradient(150deg,#262626 0%,#333 62%,#474747 100%)}}
""")

_BASE_CSS = _TOKENS + _min("""
body{margin:0;font:14px/1.4 system-ui,-apple-system,sans-serif;color:var(--text);background:var(--surface);
-webkit-font-smoothing:antialiased}
.w{padding:14px 16px 16px}
.m{font-size:13px;color:var(--muted)}
.top{display:flex;align-items:center;justify-content:space-between;gap:8px;min-height:24px}
.no{flex:none;padding:2px 9px;border-radius:999px;background:var(--surface-2);color:var(--heading);
font:600 12px/1.5 ui-monospace,monospace}
.bg{display:inline-flex;align-items:center;gap:6px;padding:3px 10px;border-radius:999px;font-size:12px;
font-weight:600;line-height:1.5;white-space:nowrap;background:var(--surface-3);color:var(--text)}
.dot:before{content:'';width:6px;height:6px;border-radius:50%;background:currentColor}
.due_soon{background:var(--warn-bg);color:var(--warn)}.overdue{background:var(--danger-bg);color:var(--danger)}
.answered{background:var(--success-bg);color:var(--success)}
.ti{flex:none;display:grid;place-items:center;width:40px;height:40px;border-radius:50%;
background:var(--warn-bg);color:var(--warn)}
.ti.suggestion{background:var(--s-in_progress-bg);color:var(--s-in_progress)}
.ti.praise{background:var(--success-bg);color:var(--success)}
.ld{display:flex;gap:12px;align-items:flex-start;margin-top:12px}
.mn{min-width:0;flex:1}
.tt{font-size:18px;font-weight:500;line-height:1.25;letter-spacing:-.025em;color:var(--heading);
overflow-wrap:anywhere}
.sb{margin-top:4px;font-size:13px;color:var(--muted)}
""") + "".join(f".s-{c}{{background:var(--s-{c}-bg);color:var(--s-{c})}}" for c in STATUSES)

_ESCAPE_JS = _min("""
function e(s){return String(s==null?'':s).replace(/[&<>"]/g,function(c){
return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]})}
var W=window.TelegramWidget||{};
function D(){try{return JSON.parse(W.chatData||'{}')}catch(x){return{}}}
""")

# Значки типа — lucide (как TypeIcon на сайте): circle-alert, lightbulb, heart.
_ICONS_JS = _min("""
var IC={problem:'<circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/>',
suggestion:'<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5M9 18h6M10 22h4"/>',
praise:'<path d="M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.8 0-3 .5-4.5 2-1.5-1.5-2.7-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7Z"/>'};
function icon(t,z){z=z||20;return '<span class="ti '+e(t)+'"><svg width="'+z+'" height="'+z+'" viewBox="0 0 24 24" fill="none" '+
'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'+(IC[t]||IC.problem)+'</svg></span>'}
""")

_HEAD = "<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width\"><style>"
_READY = "if(W.ready)W.ready();"

# Карточка обращения — как карточка на сайте (.sheet): событие и номер, значок типа и суть заголовком,
# тип · категория · приоритет, бейджи статуса и срока, ответственный с аватаркой, полоса этапов.
# chat_data: {h: событие, n: номер, t: код типа, k: тип, c: категория, p: приоритет, st: код статуса,
#             sl: подпись статуса, a: ответственный, d: срок, ds: состояние срока, dl: подпись состояния, s: суть}
APPEAL_CARD = (
    _HEAD
    + _BASE_CSS
    + _min("""
.hd{display:flex;flex-wrap:wrap;gap:6px;margin-top:12px}
.pp{display:flex;align-items:center;gap:10px;margin-top:14px;padding-top:12px;border-top:1px solid var(--line)}
.av{flex:none;display:grid;place-items:center;width:32px;height:32px;border-radius:50%;font-size:11.5px;
font-weight:700;letter-spacing:.02em}
.pp b{display:block;font-weight:600;color:var(--heading);line-height:1.3}
.pp .m{font-size:12px}
.st{display:flex;gap:4px;margin:14px 0 6px}
.st i{flex:1;height:4px;border-radius:2px;background:var(--surface-3)}
.sl{display:flex;justify-content:space-between;font-size:11px;color:var(--faint)}
.sl .on{color:var(--heading);font-weight:600}
</style></head><body><div class="w" id="r"></div><script>
""")
    + _ESCAPE_JS
    + _ICONS_JS
    + _min("""
var NAMES=['Новое','Рассмотрение','В работе','Готово'],
AT={new:0,in_review:1,awaiting_info:1,in_progress:2,implemented:3,closed:3},
TONES=['new','in_progress','implemented','awaiting_info','in_review','closed'];
function ini(n){var p=String(n).trim().split(/\\s+/);return((p[0]||'').charAt(0)+(p[1]||'').charAt(0)).toUpperCase()||'?'}
function tone(n){var h=0;for(var c of String(n))h=(h*31+c.charCodeAt(0))>>>0;return TONES[h%TONES.length]}
function render(){var d=D(),i=AT[d.st],h='';
h+='<div class="top"><span class="m">'+e(d.h||'Обращение')+'</span><span class="no">'+e(d.n)+'</span></div>';
h+='<div class="ld">'+icon(d.t)+'<div class="mn"><div class="tt">'+e(d.s||('Обращение '+d.n))+'</div>';
var sub=[d.k,d.c,d.p?'приоритет '+String(d.p).toLowerCase():''].filter(Boolean);
if(sub.length)h+='<div class="sb">'+e(sub.join(' · '))+'</div>';
h+='</div></div><div class="hd"><span class="bg dot s-'+e(d.st)+'">'+e(d.sl)+'</span>';
if(d.dl)h+='<span class="bg '+e(d.ds)+'">'+e(d.dl)+(d.d?' · до '+e(d.d):'')+'</span>';
h+='</div>';
if(d.a){var t=tone(d.a);h+='<div class="pp"><span class="av" style="background:var(--s-'+t+'-bg);color:var(--s-'+t+')">'+
e(ini(d.a))+'</span><span><b>'+e(d.a)+'</b><span class="m">Ответственный</span></span></div>'}
if(i!=null){h+='<div class="st">';for(var j=0;j<4;j++)h+='<i'+(i>=j?' style="background:var(--s-'+e(d.st)+')"':'')+'></i>';
h+='</div><div class="sl">';for(j=0;j<4;j++)h+='<span'+(i==j?' class="on"':'')+'>'+NAMES[j]+'</span>';h+='</div>'}
document.getElementById('r').innerHTML=h}
render();if(W.onEvent)W.onEvent('chatDataChanged',render);
""")
    + _READY
    + "</script></body></html>"
)

# Код входа — плитка в стиле .tile--navy сайта: пилюли «Код входа» и обратного отсчёта, цифры в ячейках,
# полоса оставшегося времени. Отсчёт желтеет в последнюю минуту (цвета .badge--due-*), истёкший код гаснет.
# Копирует код кнопка Telegram под виджетом (copy_text): виджеты в проде идут с защитой контента,
# и copyText изнутри Telegram запрещает («копирование и пересылка отключены в этом чате»).
# chat_data: {c: код, e: истекает (мс с эпохи), l: срок жизни кода в секундах}
LOGIN_CODE = (
    _HEAD
    + _BASE_CSS
    + _min("""
body{background:var(--tile)}
.k{position:relative;padding:14px 14px 16px;color:#fff;isolation:isolate}
.k:after{content:'';position:absolute;inset:0;z-index:-1;
background:radial-gradient(120% 90% at 85% 0%,rgba(255,255,255,.22),transparent 55%)}
.pl{padding:5px 12px;border-radius:999px;background:rgba(255,255,255,.94);color:#082742;font-size:12.5px;
font-weight:600;line-height:1.3;white-space:nowrap}
.pl.due_soon{background:#ffefe0;color:#9a4a00}.pl.overdue{background:#fdecea;color:#b3261e}
.c{display:flex;justify-content:center;gap:6px;margin:22px 0 20px}
.c span{display:grid;place-items:center;width:42px;height:54px;border-radius:12px;background:rgba(255,255,255,.14);
font:600 28px/1 ui-monospace,monospace}
.c.x span{opacity:.4}
.b{height:4px;border-radius:2px;background:rgba(255,255,255,.2);overflow:hidden}
.b i{display:block;height:100%;border-radius:2px;background:#fff}
</style></head><body><div class="k"><div class="top"><span class="pl">Код входа</span><span class="pl" id="t"></span></div>
<div class="c" id="c"></div><div class="b"><i id="b"></i></div></div><script>
""")
    + _ESCAPE_JS
    + _min("""
var d=D(),c=document.getElementById('c'),t=document.getElementById('t'),b=document.getElementById('b'),
code=String(d.c||''),life=(d.l||300)*1000;
c.innerHTML=code.split('').map(function(x){return '<span>'+e(x)+'</span>'}).join('');
function tick(){var left=(d.e||0)-Date.now(),s=Math.round(left/1000);
b.style.width=Math.max(0,Math.min(100,left/life*100))+'%';
if(s<=0){t.textContent='Код истёк — запросите новый';t.className='pl overdue';c.className='c x';return false}
t.className=s<=60?'pl due_soon':'pl';
t.textContent='Действует ещё '+Math.floor(s/60)+':'+('0'+s%60).slice(-2);return true}
if(tick()&&typeof setInterval==='function'){var iv=setInterval(function(){if(!tick())clearInterval(iv)},1000)}
""")
    + _READY
    + "</script></body></html>"
)

# Черновик обращения — то, что пойдёт в обращение: суть заголовком, поля плитками, исходный текст.
# Бот перерисовывает его (editMessageWidgetData) после каждой правки кнопками, а после отправки
# или отмены сворачивает до сути с пометкой «Отправлен · A-021» или «Отменён».
# chat_data: {t: код типа, k: тип, c: категория, p: приоритет, s: суть, q: текст, o: предложенное решение,
#             v: 1 — расшифровка голосового, f: откуда переслано, x: sent|cancelled, n: номер после отправки}
DRAFT_CARD = (
    _HEAD
    + _BASE_CSS
    + _min("""
.src{margin-top:10px;padding:6px 10px;border-radius:10px;background:var(--surface-2);font-size:12.5px;color:var(--muted)}
.f{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:6px;margin-top:14px}
.f div{padding:8px 10px;border-radius:12px;background:var(--surface-2);min-width:0}
.f span{display:block;font-size:11px;color:var(--muted)}
.f b{display:block;margin-top:1px;font-size:13px;font-weight:600;color:var(--heading);line-height:1.3;overflow-wrap:anywhere}
.f b.n{color:var(--muted);font-weight:500}
.q{margin-top:10px;padding:10px 12px;border-radius:12px;background:var(--surface-2);font-size:13.5px;line-height:1.45;
white-space:pre-wrap;overflow-wrap:anywhere;display:-webkit-box;-webkit-line-clamp:7;-webkit-box-orient:vertical;overflow:hidden}
.q2 span{display:block;margin-bottom:2px;font-size:11px;color:var(--muted)}
.off .f,.off .q,.off .src{display:none}.off .ld{opacity:.6}
</style></head><body><div class="w" id="r"></div><script>
""")
    + _ESCAPE_JS
    + _ICONS_JS
    + _min("""
function render(){var d=D(),h='',x=d.x;
h+='<div class="top"><span class="m">Черновик обращения</span>';
if(x=='sent')h+='<span class="bg answered">Отправлен'+(d.n?' · '+e(d.n):'')+'</span>';
else if(x=='cancelled')h+='<span class="bg">Отменён</span>';
else h+='<span class="bg s-new">Не отправлен</span>';
h+='</div>';
if(d.v)h+='<div class="src">🎙 Расшифровка голосового — проверьте, что вас поняли верно</div>';
else if(d.f)h+='<div class="src">Переслано из: '+e(d.f)+'</div>';
h+='<div class="ld">'+icon(d.t)+'<div class="mn"><div class="tt">'+e(d.s||'Без краткой сути')+'</div></div></div>';
h+='<div class="f"><div><span>Тип</span><b>'+e(d.k)+'</b></div><div><span>Категория</span>'+
(d.c?'<b>'+e(d.c)+'</b>':'<b class="n">Определит администратор</b>')+'</div><div><span>Приоритет</span><b>'+e(d.p)+'</b></div></div>';
if(d.q)h+='<div class="q">'+e(d.q)+'</div>';
if(d.o)h+='<div class="q q2"><span>Предлагаемое решение</span>'+e(d.o)+'</div>';
var r=document.getElementById('r');r.className='w'+(x?' off':'');r.innerHTML=h}
render();if(W.onEvent)W.onEvent('chatDataChanged',render);
""")
    + _READY
    + "</script></body></html>"
)

# «Мои обращения» — список как .row на сайте: значок типа, суть, номер и дата, бейдж статуса.
# chat_data: {T: всего, L: {код статуса: подпись}, i: [[номер, код типа, код статуса, суть, дата, 1 — есть новое]]}
APPEAL_LIST = (
    _HEAD
    + _BASE_CSS
    + _min("""
.w{padding-bottom:8px}
.r{display:flex;align-items:center;gap:12px;padding:10px 0}
.r+.r{border-top:1px solid var(--line)}
.r .ti{width:32px;height:32px}
.rt{font-size:14.5px;font-weight:600;line-height:1.35;color:var(--heading);overflow-wrap:anywhere;
display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.u:before{content:'';display:inline-block;width:7px;height:7px;margin:0 6px 1px 0;border-radius:50%;background:var(--accent)}
.rm{font-size:12.5px;color:var(--muted)}
.ft{padding:8px 0 4px;border-top:1px solid var(--line);font-size:12.5px;color:var(--muted)}
</style></head><body><div class="w" id="r"></div><script>
""")
    + _ESCAPE_JS
    + _ICONS_JS
    + _min("""
function render(){var d=D(),L=d.L||{},it=d.i||[],h='';
h+='<div class="top"><span class="m">Мои обращения</span><span class="no">'+e(d.T||it.length)+'</span></div><div style="margin-top:4px">';
it.forEach(function(a){h+='<div class="r">'+icon(a[1],16)+'<div class="mn"><div class="rt'+(a[5]?' u':'')+'">'+
e(a[3]||'Без краткой сути')+'</div><div class="rm">'+e(a[0])+(a[4]?' · '+e(a[4]):'')+'</div></div>'+
'<span class="bg dot s-'+e(a[2])+'">'+e(L[a[2]]||a[2])+'</span></div>'});
h+='</div>';
if(d.T>it.length)h+='<div class="ft">Ещё '+e(d.T-it.length)+' — в приложении</div>';
document.getElementById('r').innerHTML=h}
render();if(W.onEvent)W.onEvent('chatDataChanged',render);
""")
    + _READY
    + "</script></body></html>"
)
