"""Генератор design/tokens.json и design/contrast.md. Источник истины для токенов — этот файл.
Запуск: python3 design/build_tokens.py  (печатает непрошедшие пары WCAG; 0 fail — норма)."""
import json, sys, re

import os; OUT=sys.argv[1] if len(sys.argv)>1 else os.path.join(os.path.dirname(os.path.abspath(__file__)),"tokens.json")
SITE="https://modus-trade.kz (CSS шаблона modus_main, снято 11.11.2026)"
LOGO="https://modus-trade.kz/upload/iblock/d2a/wav3zgzmn2frim29p8a7mt9dzux15j6w/logo-header.svg"
def c(v,desc,src): return {"$type":"color","$value":v,"$description":desc,"$extensions":{"kz.modus.source":src}}
P={
 "navy":{
  "900":c("#082742","Фирменный тёмно-синий: кольцо и надпись логотипа, заголовки сайта","логотип: "+LOGO+" (fill #082742); на сайте — заголовки, футер"),
  "700":c("#0E3A61","Наведение на тёмно-синие элементы","производный: navy.900 светлее на 8% L"),
  "300":c("#8CB8E6","Тёмно-синий для тёмной темы (первичный цвет на тёмном фоне)","производный от navy.900 и #2F80ED сайта"),
  "50": c("#EFF6FD","Светло-голубая подложка карточек проектов, новостей, фильтра","сайт: .projectCard, .categoryCard, .filter — background #eff6fd"),
 },
 "red":{
  "logo":c("#ED1111","Красный «зрачок» логотипа и фон кнопок .btn. Только для логотипа и декора: белый текст на нём 4.48:1 — ниже AA","логотип (fill #ED1111); сайт .btn background-color"),
  "600":c("#E40000","Рабочий фирменный красный: главная кнопка, акценты. Белый текст 4.89:1","сайт: ссылки a, .header__link:hover — color #e40000 (самый частый красный в CSS)"),
  "700":c("#CC0000","Наведение/нажатие на красную кнопку","сайт: .btn:hover background #c00"),
 },
 "ink":{
  "800":c("#323A47","Основной текст","сайт: --bs-font-color, .heading-h2 #323a47"),
  "600":c("#64748D","Второстепенный текст сайта (абзацы). У нас — только на белом","сайт: .paragraph, .timeline__text #64748d"),
  "550":c("#5A6A82","Второстепенный текст на любой светлой поверхности (AA на #EFF6FD)","производный: #64748D темнее, чтобы пройти AA на navy.50"),
  "400":c("#848FA0","Граница полей ввода (≥3:1 к фону, WCAG 1.4.11)","производный от #B0B8C5 сайта"),
  "300":c("#B0B8C5","Сильный разделитель","сайт: #b0b8c5"),
  "200":c("#D1D5DD","Граница карточек и разделители","сайт: #d1d5dd"),
  "100":c("#F4F7FB","Фон страницы","производный: между #f3f3f3 футера и #eff6fd карточек"),
  "0":  c("#FFFFFF","Поверхность карточки","сайт: фон страниц и шапки #fff"),
 },
 "blue":{
  "500":c("#2F80ED","Голубой акцент сайта (город в шапке, подзаголовки). Только для фокуса/декора: на белом 3.87:1","сайт: .header__cityName, .heading-subtitle #2f80ed"),
  "600":c("#1A66C9","Ссылки и «информация» в светлой теме (AA)","производный: #2F80ED темнее до 5.54:1 на белом"),
 },
 "orange":{"400":c("#FC8D3D","Оранжевый акцент сайта (активный пункт меню). Только декор","сайт: ul.left-menu a.selected #fc8d3d")},
}
def a(path): return "{primitive."+path+"}"
def t(v,d=""): return {"$type":"color","$value":v,**({"$description":d} if d else {})}
light={
 "bg":t(a("ink.100"),"Фон страницы"),
 "surface":t(a("ink.0"),"Карточки, шапка, листы"),
 "surface-2":t(a("navy.50"),"Подложка: фильтры, выделенные блоки, бейдж по умолчанию"),
 "text":t(a("ink.800")),
 "heading":t(a("navy.900"),"Заголовки и логотип-ориентированные элементы"),
 "muted":t(a("ink.550")),
 "border":t(a("ink.200")),
 "border-input":t(a("ink.400"),"Граница полей ввода и чекбоксов"),
 "primary":t(a("navy.900"),"Выбранное: вкладки, переключатели, активная навигация, второстепенные кнопки"),
 "primary-hover":t(a("navy.700")),
 "on-primary":t(a("ink.0")),
 "accent":t(a("red.600"),"Главная кнопка (CTA), счётчик непрочитанного"),
 "accent-hover":t(a("red.700")),
 "on-accent":t(a("ink.0")),
 "link":t(a("blue.600")),
 "focus":t(a("blue.500"),"Кольцо фокуса"),
 "danger":t("#B3261E","Ошибки и отклонение. Темнее фирменного красного, всегда с иконкой или текстом"),
 "danger-bg":t("#FDECEA"),
 "warn":t("#9A4A00"),"warn-bg":t("#FFEFE0"),
 "success":t("#17703A"),"success-bg":t("#E5F4EA"),
 "info":t(a("blue.600")),"info-bg":t("#E6F0FC"),
}
dark={
 "bg":t("#071521","Фон: тёмно-синий из navy.900"),
 "surface":t("#0D2236"),
 "surface-2":t("#142D45"),
 "text":t("#E6ECF2"),
 "heading":t(a("ink.0")),
 "muted":t("#9AABBF"),
 "border":t("#23405C"),
 "border-input":t("#5A7EA3"),
 "primary":t(a("navy.300")),
 "primary-hover":t("#A9CBEF"),
 "on-primary":t(a("navy.900")),
 "accent":t(a("red.600"),"Тот же фирменный красный: белый текст 4.89:1, к фону ≥3:1"),
 "accent-hover":t("#C80000"),
 "on-accent":t(a("ink.0")),
 "link":t("#8DBBF5"),
 "focus":t("#8DBBF5"),
 "danger":t("#FF8A80"),"danger-bg":t("#3D1B1B"),
 "warn":t("#F7B57A"),"warn-bg":t("#3A2614"),
 "success":t("#7FD39A"),"success-bg":t("#143222"),
 "info":t("#8DBBF5"),"info-bg":t("#12304F"),
}
ST=[("new","Новое"),("in_review","На рассмотрении"),("awaiting_info","Ожидает уточнения"),("in_progress","В работе"),("implemented","Реализовано"),("rejected","Отклонено"),("closed","Закрыто")]
SL={"new":("#1A62C4","#E6F0FC"),"in_review":("#082742","#E3EAF2"),"awaiting_info":("#9A4A00","#FFEFE0"),"in_progress":("#5A3DB8","#EEE9FB"),"implemented":("#17703A","#E5F4EA"),"rejected":("#B3261E","#FDECEA"),"closed":("#4F5B6B","#EDEFF2")}
SD={"new":("#8DBBF5","#12304F"),"in_review":("#C9D6E6","#1C3047"),"awaiting_info":("#F7B57A","#3A2614"),"in_progress":("#B9A6F5","#2A2148"),"implemented":("#7FD39A","#143222"),"rejected":("#FF9B92","#3D1B1B"),"closed":("#A9B4C2","#222C38")}
for theme,src in ((light,SL),(dark,SD)):
    theme["status"]={k:{"$description":ru,"fg":t(src[k][0]),"bg":t(src[k][1])} for k,ru in ST}

def dim(v,d=""): return {"$type":"dimension","$value":v,**({"$description":d} if d else {})}
tokens={
 "$description":"Дизайн-токены «Модус Трейд»: система обращений сотрудников. Формат W3C Design Tokens (DTCG). Источники и карта применения — design/README.md.",
 "primitive":P,
 "color":{"light":light,"dark":dark},
 "font":{
  "family":{
   "heading":{"$type":"fontFamily","$value":["Montserrat","Manrope","system-ui","sans-serif"],"$description":"Montserrat — заголовки сайта (.heading-h2). Есть в Google Fonts с кириллицей"},
   "body":{"$type":"fontFamily","$value":["Manrope","system-ui","-apple-system","Segoe UI","Roboto","sans-serif"],"$description":"Бесплатная замена Gilroy (основной шрифт сайта, коммерческий). Google Fonts, кириллица"},
   "mono":{"$type":"fontFamily","$value":["JetBrains Mono","ui-monospace","Menlo","monospace"],"$description":"Номера обращений, коды"},
  },
  "weight":{k:{"$type":"fontWeight","$value":v} for k,v in [("regular",400),("medium",500),("semibold",600),("bold",700)]},
 },
 "typography":{},
 "radius":{
  "sm":dim("4px","Кнопки и поля — как .btn и поля формы сайта"),
  "md":dim("8px","Бейджи-плашки, мелкие карточки, пункты меню"),
  "lg":dim("10px","Карточки и листы — как радиус 10px на сайте; совпадает с текущим --radius веба"),
  "xl":dim("16px","Модальные листы и нижние шторки (Mini App, Flutter)"),
  "pill":dim("999px","Бейджи статуса, счётчики"),
 },
 "spacing":{k:dim(f"{v}px") for k,v in [("0",0),("1",4),("2",8),("3",12),("4",16),("5",20),("6",24),("8",32),("10",40),("12",48)]},
 "shadow":{
  "sm":{"$type":"shadow","$value":{"color":"#0827420F","offsetX":"0px","offsetY":"1px","blur":"2px","spread":"0px"},"$description":"Карточка в списке (светлая)"},
  "md":{"$type":"shadow","$value":{"color":"#84838833","offsetX":"0px","offsetY":"4px","blur":"20px","spread":"0px"},"$description":"Как на сайте: 0 4px 20px rgba(132,131,136,.2) — всплывающие меню, наведение на карточку"},
  "dark-md":{"$type":"shadow","$value":{"color":"#00000066","offsetX":"0px","offsetY":"4px","blur":"20px","spread":"0px"},"$description":"Тёмная тема: тени почти не видны, глубину даёт surface-2"},
 },
 "size":{"control-height":dim("44px","Минимальная высота кнопки и поля: удобно пальцем"),"topbar":dim("56px"),"bottombar":dim("60px")},
}
def ty(fam,w,size,lh,ls="0px",d=""):
    return {"$type":"typography","$value":{"fontFamily":"{font.family.%s}"%fam,"fontWeight":"{font.weight.%s}"%w,"fontSize":size,"lineHeight":lh,"letterSpacing":ls},**({"$description":d} if d else {})}
tokens["typography"]={
 "display":ty("heading","bold","28px",1.25,d="Заголовок экрана на вебе (сайт: h2 40/52, у нас компактнее)"),
 "title":ty("heading","bold","22px",1.3,d="Заголовок экрана в Mini App и Flutter"),
 "subtitle":ty("body","semibold","18px",1.35,d="Заголовок карточки обращения"),
 "body":ty("body","medium","16px",1.5,d="Основной текст. Сайт: Gilroy 500 16/24"),
 "body-sm":ty("body","medium","14px",1.45,d="Мета-данные: автор, срок, категория"),
 "caption":ty("body","semibold","12px",1.35,"0.01em",d="Бейджи, подписи"),
 "button":ty("body","semibold","15px",1.2,"0.01em",d="Кнопки. Сайт пишет кнопки капсом; у нас обычный регистр — короче строки в Mini App"),
}

# ---- contrast check
def L(h):
    h=h.lstrip('#')[:6]; r=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    r=[x/12.92 if x<=0.03928 else ((x+0.055)/1.055)**2.4 for x in r]
    return 0.2126*r[0]+0.7152*r[1]+0.0722*r[2]
def cr(a,b):
    x,y=sorted([L(a),L(b)],reverse=True); return round((x+0.05)/(y+0.05),2)
def res(v):
    m=re.fullmatch(r"\{primitive\.([\w-]+)\.([\w-]+)\}",v)
    return P[m.group(1)][m.group(2)]["$value"] if m else v
report=[]
for name,th in (("light",light),("dark",dark)):
    g=lambda k: res(th[k]["$value"])
    checks=[]
    for fg in ["text","heading","muted","link","danger","warn","success","info"]:
        for bg in ["bg","surface","surface-2"]:
            checks.append((fg,bg,4.5))
    for fg,bg in [("danger","danger-bg"),("warn","warn-bg"),("success","success-bg"),("info","info-bg"),("on-accent","accent"),("on-accent","accent-hover"),("on-primary","primary"),("on-primary","primary-hover")]:
        checks.append((fg,bg,4.5))
    for fg in ["border-input","accent","primary","focus"]:
        for bg in ["bg","surface"]:
            checks.append((fg,bg,3.0))
    for fg,bg,need in checks:
        r=cr(g(fg),g(bg)); report.append((name,fg,bg,g(fg),g(bg),r,need,r>=need))
    for k,_ in ST:
        f,b=th["status"][k]["fg"]["$value"],th["status"][k]["bg"]["$value"]
        r=cr(f,b); report.append((name,f"status.{k}.fg",f"status.{k}.bg",f,b,r,4.5,r>=4.5))
bad=[x for x in report if not x[7]]
for x in bad: print("FAIL",x)
print(len(report),"checks,",len(bad),"fail")
tokens["$extensions"]={"kz.modus.contrast":{"$description":"WCAG 2.1: текст ≥4.5:1, границы и не-текстовые элементы ≥3:1. Пересчитывается скриптом design/build_tokens.py","checks":[{"theme":t_,"fg":f,"bg":b,"fgHex":fh,"bgHex":bh,"ratio":r,"required":n,"pass":p} for t_,f,b,fh,bh,r,n,p in report]}}
json.dump(tokens,open(OUT,"w",encoding="utf-8"),ensure_ascii=False,indent=2)
open(OUT.replace("tokens.json","contrast.md"),"w").write("| Тема | Текст / элемент | Фон | Пара | Контраст | Нужно |\n|---|---|---|---|---|---|\n"+"\n".join(f"| {t_} | `{f}` | `{b}` | {fh} на {bh} | **{r}** | {n} |" for t_,f,b,fh,bh,r,n,p in report)+"\n")
