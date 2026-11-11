# Дизайн-токены «Модус Трейд»

Чтобы сотрудник с первого взгляда узнавал свою компанию, все наши клиенты (веб, Mini App, Flutter) используют фирменные цвета, шрифты и формы с сайта modus-trade.kz.

| Файл | Что в нём |
|---|---|
| `tokens.json` | Токены в формате W3C Design Tokens (DTCG): `primitive` (фирменная палитра с источником у каждого цвета), `color.light` / `color.dark` (смысловые токены тем), `font`, `typography`, `radius`, `spacing`, `shadow`, `size`. В `$extensions.kz.modus.contrast` лежат все проверки контраста. |
| `build_tokens.py` | Генератор `tokens.json` и `contrast.md`. Это источник истины: правки вносите здесь и запускайте `python3 design/build_tokens.py`. Скрипт печатает пары, которые не проходят WCAG. |
| `contrast.md` | Таблица контраста: 94 пары, все проходят AA. |

## Фирменный стиль: что взято и откуда

Цвета и шрифты сняты 11.11.2026 из CSS шаблона `modus_main` сайта https://modus-trade.kz. Сайт собран на 1С-Битрикс, CSS лежит в `/bitrix/cache/css/s1/modus_main/…`. Цвета логотипа взяты из файла логотипа в шапке сайта. Брендбук компании в открытом доступе не найден.

### Цвета

| Токен | Hex | Откуда | Как используем |
|---|---|---|---|
| `primitive.navy.900` | `#082742` | Логотип: тёмно-синее кольцо и надпись «МОДУС ТРЕЙД» (`logo-header.svg`, `fill="#082742"`). На сайте этим цветом набраны заголовки проектов и контакты в футере. | Заголовки, первичный цвет (выбранная вкладка, переключатели, активная навигация). |
| `primitive.red.logo` | `#ED1111` | Логотип: красный «зрачок». На сайте это фон кнопок `.btn`. | Только логотип и декор: белый текст на нём даёт 4.48:1, это ниже AA. |
| `primitive.red.600` | `#E40000` | Самый частый красный в CSS сайта (42 вхождения): ссылки `a`, наведение в шапке. | Главная кнопка (CTA), счётчик непрочитанного. Белый текст 4.89:1. |
| `primitive.red.700` | `#CC0000` | `.btn:hover` на сайте. | Наведение и нажатие на главную кнопку. |
| `primitive.ink.800` | `#323A47` | Основной цвет текста сайта (`--bs-font-color`, `.heading-h2`). | Основной текст. |
| `primitive.ink.600` | `#64748D` | Абзацы сайта (`.paragraph`, `.timeline__text`). | Второстепенный текст, только на белом. |
| `primitive.ink.550` | `#5A6A82` | Производный от `#64748D`. | Второстепенный текст (`muted`). Исходный `#64748D` на подложке `#EFF6FD` даёт 4.36:1 — не проходит AA, поэтому взят чуть темнее. |
| `primitive.ink.200` / `300` | `#D1D5DD` / `#B0B8C5` | Разделители и рамки на сайте. | Границы карточек. |
| `primitive.ink.400` | `#848FA0` | Производный. | Граница полей ввода: нужно не меньше 3:1 к фону (WCAG 1.4.11), а `#B0B8C5` даёт только 2.0. |
| `primitive.navy.50` | `#EFF6FD` | Подложка карточек проектов, новостей и фильтра на сайте. | `surface-2`: фильтры, выделенные блоки. |
| `primitive.ink.100` | `#F4F7FB` | Производный: среднее между `#F3F3F3` футера и `#EFF6FD` карточек. | Фон страницы. |
| `primitive.blue.500` | `#2F80ED` | Голубой акцент сайта: город в шапке, подзаголовки. | Кольцо фокуса. Как цвет текста не годится: 3.87:1. |
| `primitive.blue.600` | `#1A66C9` | Производный от `#2F80ED`. | Ссылки и статус «информация». |
| `primitive.orange.400` | `#FC8D3D` | Активный пункт левого меню сайта. | Только декор. Для текста «ожидает» используется `#9A4A00`. |

Цвета тёмной темы, статусов, `danger`, `warn` и `success` придуманы нами: на сайте компании нет ни тёмной темы, ни состояний. Тёмная тема построена на тёмно-синем `#082742`, а не на нейтральном сером, поэтому и ночью интерфейс выглядит «модусовским».

### Шрифты

| Роль | На сайте | У нас | Почему |
|---|---|---|---|
| Основной | **Gilroy** 400/500/600/700 (коммерческий шрифт, лежит в `/local/templates/modus_main/fonts/Gilroy/`) | **Manrope** (Google Fonts, есть кириллица) | Ближайший бесплатный геометрический гротеск с кириллицей: круглые «о» и «с», открытые формы. Лицензию Gilroy команда не покупала, а встраивать файлы с сайта нельзя. |
| Заголовки | **Montserrat** 700 (`.heading-h2`) | **Montserrat** 700 (Google Fonts, есть кириллица) | Тот же шрифт, что на сайте, и он бесплатный. |
| Декор | Involve (2 места на сайте) | — | Нам не нужен. |

Подключение на вебе: `https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700&family=Montserrat:wght@600;700&display=swap&subset=cyrillic`. Во Flutter — пакет `google_fonts` или файлы шрифтов в `assets/fonts` (лицензия OFL, их можно класть в репозиторий).

Шкала (`typography.*`): `display` 28/1.25 Montserrat Bold, `title` 22/1.3 Montserrat Bold, `subtitle` 18 Manrope SemiBold, `body` 16/1.5 Manrope Medium (как основной текст сайта Gilroy 500 16/24), `body-sm` 14, `caption` 12, `button` 15 SemiBold. На сайте кнопки набраны капсом; у нас регистр обычный, чтобы строка помещалась на узком экране Mini App.

### Формы, тени, отступы

- **Радиусы** взяты с сайта: 4px у кнопок и полей (`.btn`, `.footerForm__input`), 10px у карточек. Добавлены 8px (плашки), 16px (нижние шторки) и `pill` для бейджей. Сайт выглядит строго, «по-инженерному», поэтому крупных скруглений нет.
- **Тень** `shadow.md` = `0 4px 20px rgba(132,131,136,.2)` — единственная тень на сайте. `shadow.sm` добавлена для карточек списка. В тёмной теме глубину создаёт `surface-2`, а не тень.
- **Отступы**: шаг 4px (`spacing.1` = 4 … `spacing.12` = 48). Высота кнопки и поля — не меньше 44px.

### Логотип

Логотип состоит из знака и надписи. Знак — тёмно-синее (`#082742`) разомкнутое кольцо из двух дуг, похожее на глаз или объектив камеры. В центре — красный (`#ED1111`) круг с белым бликом: «зрачок». Это отсылка к видеонаблюдению и безопасности, основному направлению компании. Справа в две строки идёт надпись «МОДУС / ТРЕЙД» тёмно-синими прописными, рубленым шрифтом.

Источник: https://modus-trade.kz/upload/iblock/d2a/wav3zgzmn2frim29p8a7mt9dzux15j6w/logo-header.svg (знак отдельно — `https://modus-trade.kz/local/templates/modus_main/favicon.svg`). **Файлы бренда в репозиторий не кладём.** Если логотип нужен на экране входа, используйте его только с разрешения компании, на белом или `navy.50` фоне и с охранным полем не меньше высоты «зрачка».

### Иконки и иллюстрации

На сайте используются тонкие линейные иконки преимуществ («Надежность», «Инновации», «Партнерство») в тёмно-синем цвете с красным акцентом, фотографии объектов (аэропорт, Hilton) и карта мира. Пиктограммы мультяшного стиля и 3D не встречаются.

У нас: линейные иконки с обводкой 1.5–2px и скруглёнными концами (на вебе — Lucide, во Flutter — Material Symbols Rounded, начертание outlined, weight 400). Цвет иконок — `text` или `muted`. Красный (`accent`) допускается только у одной иконки на экране: главное действие или непрочитанное. Иллюстрации пустых состояний не рисуем: хватит иконки в круге `surface-2` и короткой строки текста.

## Правила применения цветов

1. **Красный — один на экран.** `accent` (`#E40000`) отдан главному действию: «Подать обращение», «Отправить», «Сохранить решение», а также счётчику непрочитанного. Всё остальное делается тёмно-синим `primary` или нейтральными цветами. Как и на сайте, красного там немного, и он сразу заметен.
2. **Ошибка — не фирменный красный.** `danger` (`#B3261E`) темнее фирменного красного и всегда выводится вместе с иконкой или текстом. Опасное действие («Отклонить», «Удалить») оформляется кнопкой с обводкой `danger` и не заливается красным, чтобы не спутать её с CTA.
3. **Статусы обращения** (7 статусов из SPEC) — это пары `color.<тема>.status.<код>.fg/bg`:

| Код | Статус | Светлая fg / bg | Тёмная fg / bg |
|---|---|---|---|
| `new` | Новое | `#1A62C4` / `#E6F0FC` | `#8DBBF5` / `#12304F` |
| `in_review` | На рассмотрении | `#082742` / `#E3EAF2` | `#C9D6E6` / `#1C3047` |
| `awaiting_info` | Ожидает уточнения | `#9A4A00` / `#FFEFE0` | `#F7B57A` / `#3A2614` |
| `in_progress` | В работе | `#5A3DB8` / `#EEE9FB` | `#B9A6F5` / `#2A2148` |
| `implemented` | Реализовано | `#17703A` / `#E5F4EA` | `#7FD39A` / `#143222` |
| `rejected` | Отклонено | `#B3261E` / `#FDECEA` | `#FF9B92` / `#3D1B1B` |
| `closed` | Закрыто | `#4F5B6B` / `#EDEFF2` | `#A9B4C2` / `#222C38` |

Контраст каждой пары не ниже 4.5:1, числа приведены в `contrast.md`.

## Карта: токен → веб (CSS-переменные)

Веб (`web/src/styles/global.css`) уже построен на CSS-переменных, поэтому токены ложатся на них один к одному: в `:root` пишутся значения светлой темы, в `:root[data-theme='dark']` и `@media (prefers-color-scheme: dark)` — тёмной.

| Токен | Переменная | Сейчас → станет (светлая) | Тёмная |
|---|---|---|---|
| `color.*.bg` | `--bg` | `#f5f6f8` → `#F4F7FB` | `#071521` |
| `color.*.surface` | `--surface` | `#ffffff` → `#FFFFFF` | `#0D2236` |
| `color.*.surface-2` | `--surface-2` | `#eef0f4` → `#EFF6FD` | `#142D45` |
| `color.*.text` | `--text` | `#1a1d23` → `#323A47` | `#E6ECF2` |
| `color.*.heading` | `--heading` (новая) | — → `#082742` | `#FFFFFF` |
| `color.*.muted` | `--muted` | `#5d6470` → `#5A6A82` | `#9AABBF` |
| `color.*.border` | `--border` | `#dde1e7` → `#D1D5DD` | `#23405C` |
| `color.*.border-input` | `--border-input` (новая) | — → `#848FA0` | `#5A7EA3` |
| `color.*.accent` | `--accent` | `#2563eb` → `#E40000` | `#E40000` |
| `color.*.accent-hover` | `--accent-hover` (новая) | — → `#CC0000` | `#C80000` |
| `color.*.on-accent` | `--accent-text` | `#ffffff` → `#FFFFFF` | `#0b1020` → `#FFFFFF` |
| `color.*.primary` | `--primary` (новая) | — → `#082742` | `#8CB8E6` |
| `color.*.on-primary` | `--primary-text` (новая) | — → `#FFFFFF` | `#082742` |
| `color.*.link` | `--link` (новая) | — → `#1A66C9` | `#8DBBF5` |
| `color.*.focus` | `--focus` (новая) | — → `#2F80ED` | `#8DBBF5` |
| `color.*.danger`, `danger-bg` | `--danger`, `--danger-bg` | `#c62828` → `#B3261E` | `#FF8A80` / `#3D1B1B` |
| `color.*.warn`, `warn-bg` | `--warn`, `--warn-bg` | `#8a5a00` → `#9A4A00` | `#F7B57A` / `#3A2614` |
| `color.*.success`, `success-bg` | `--success`, `--success-bg` | `#1b7f3b` → `#17703A` | `#7FD39A` / `#143222` |
| `color.*.info-bg` | `--info-bg` | `#e8f0fe` → `#E6F0FC` | `#12304F` |
| `color.*.status.<код>.fg/bg` | `--status-<код>`, `--status-<код>-bg` (новые) | заменяют общие `--info-bg` / `--warn-bg` в `.badge--status-*` | |
| `radius.lg` | `--radius` | `10px` (не меняется) | |
| `radius.sm`, `md`, `xl`, `pill` | `--radius-sm/md/xl/pill` (новые) | кнопки и поля 4px; захардкоженные 14px заменить на `--radius-xl` | |
| `shadow.sm`, `shadow.md` | `--shadow-sm`, `--shadow-md` (новые) | | `shadow.dark-md` |
| `font.family.body` | `--font-body` → `font` у `html, body` | `system-ui` → `Manrope, system-ui, …` | |
| `font.family.heading` | `--font-heading` → `h1, h2, .page-title` | — → `Montserrat` | |
| `size.topbar`, `size.bottombar` | `--topbar-h`, `--bottombar-h` | 56px / 60px (не меняются) | |

Внимание: в тёмной теме сейчас `--accent-text: #0b1020` (тёмный текст на голубой кнопке). С красной кнопкой текст должен быть белым.

## Mini App: что даёт Telegram и что остаётся нашим

`web/src/telegram/theme.ts` переписывает переменные цветами темы Telegram (`themeParams`) через inline-стиль на `<html>`. Telegram подставляет свои цвета: у каждого пользователя может быть своя тема, в том числе нестандартная. Делим так.

**Берём у Telegram** — фон и текст, чтобы Mini App выглядел продолжением чата и не «вспыхивал» при открытии:

| Переменная | Ключ Telegram |
|---|---|
| `--bg`, `--surface-2` | `secondary_bg_color` |
| `--surface` | `bg_color` |
| `--text` | `text_color` |
| `--muted` | `hint_color` |
| `--border` | `section_separator_color` |
| `--link` | `link_color` |

**Оставляем своё поверх Telegram** — это и делает приложение «модусовским»:

- `--accent`, `--accent-hover`, `--accent-text` — фирменная красная главная кнопка. **Строку `['--accent', 'button_color']` и `['--accent-text', 'button_text_color']` из `MAPPING` нужно убрать.** Белый текст на `#E40000` даёт 4.89:1 при любой теме Telegram, а сама кнопка на тёмном фоне Telegram (`#17212B`) имеет контраст 3.34:1 — выше порога 3:1 для элементов интерфейса.
- `--primary`, `--heading` — для них нет пары у Telegram. Берём наше значение по `colorScheme` (`light` или `dark`): в тёмной теме `#8CB8E6` и `#FFFFFF`.
- `--danger` и все `--status-*`, `--success`, `--warn`, `--info` — наши, по `colorScheme`. `destructive_text_color` у Telegram бывает почти таким же, как наш accent, а статусы должны совпадать на всех трёх клиентах.
- Шрифты, радиусы, отступы, тени — наши.
- Нативная `MainButton` Telegram (если её используют): `setParams({ color: '#E40000', text_color: '#FFFFFF' })`. Шапку красить не надо: `setHeaderColor('bg_color')` и `setBackgroundColor('secondary_bg_color')`, чтобы она совпадала с темой чата.

## Карта: токен → Flutter (ThemeData / ColorScheme)

Сейчас `flutter/lib/app.dart` строит тему из `colorSchemeSeed: Color(0xFF1F5FA8)`. Вместо этого предлагается задать `ColorScheme.fromSeed(seedColor: navy900, brightness: …)` с явными переопределениями ниже. Тогда неуказанные `surfaceContainer*` Material досчитает сам, но в нашей гамме.

| Токен | ColorScheme / ThemeData | Светлая | Тёмная |
|---|---|---|---|
| `primary` | `primary` | `0xFF082742` | `0xFF8CB8E6` |
| `on-primary` | `onPrimary` | `0xFFFFFFFF` | `0xFF082742` |
| `surface-2` | `primaryContainer`, `surfaceContainerHigh` | `0xFFEFF6FD` | `0xFF142D45` |
| `heading` | `onPrimaryContainer` | `0xFF082742` | `0xFFFFFFFF` |
| `accent` | `secondary` + `filledButtonTheme`, `floatingActionButtonTheme.backgroundColor`, `badgeTheme.backgroundColor` | `0xFFE40000` | `0xFFE40000` |
| `on-accent` | `onSecondary` | `0xFFFFFFFF` | `0xFFFFFFFF` |
| `link` / `info` | `tertiary` | `0xFF1A66C9` | `0xFF8DBBF5` |
| `danger` | `error` | `0xFFB3261E` | `0xFFFF8A80` |
| `danger-bg` | `errorContainer` | `0xFFFDECEA` | `0xFF3D1B1B` |
| `surface` | `surface`, `cardTheme.color` | `0xFFFFFFFF` | `0xFF0D2236` |
| `bg` | `scaffoldBackgroundColor`, `surfaceContainerLowest` | `0xFFF4F7FB` | `0xFF071521` |
| `text` | `onSurface` | `0xFF323A47` | `0xFFE6ECF2` |
| `muted` | `onSurfaceVariant` (используется в 8 местах) | `0xFF5A6A82` | `0xFF9AABBF` |
| `border` | `outlineVariant`, `dividerTheme.color` | `0xFFD1D5DD` | `0xFF23405C` |
| `border-input` | `outline` (рамка `InputDecoration`) | `0xFF848FA0` | `0xFF5A7EA3` |
| `focus` | `inputDecorationTheme.focusedBorder` | `0xFF2F80ED` | `0xFF8DBBF5` |
| `status.<код>` | `ThemeExtension<ModusStatusColors>` с полями fg/bg для 7 статусов | см. таблицу статусов | |
| `font.family.*` | `textTheme` через `GoogleFonts.manropeTextTheme()`, заголовки `display*/headline*/titleLarge` — Montserrat | | |
| `typography.*` | `displaySmall` ← display 28, `titleLarge` ← title 22, `titleMedium` ← subtitle 18, `bodyLarge` ← body 16, `bodyMedium` ← body-sm 14, `labelSmall` ← caption 12, `labelLarge` ← button 15 | | |
| `radius.sm` | `filledButtonTheme`/`outlinedButtonTheme` `shape: RoundedRectangleBorder(BorderRadius.circular(4))`, `inputDecorationTheme` | | |
| `radius.lg` | `cardTheme.shape` 10 (сейчас в коде `circular(12)` — заменить) | | |
| `radius.xl` | `bottomSheetTheme`, `dialogTheme` 16 | | |
| `shadow.*` | `cardTheme.elevation: 0` + обводка `border`; тень `md` — только для меню (`popupMenuTheme.elevation: 3`) | | |
| `size.control-height` | `minimumSize: Size.fromHeight(44)` у кнопок | | |

Почему фирменный красный стоит в `secondary`, а не в `primary`: в Material `primary` красит все выбранные элементы (вкладки, чекбоксы, переключатели, индикатор навигации). Если сделать его красным, экран станет красным целиком, и правило «красный — один на экран» нарушится. Поэтому `primary` — тёмно-синий, а красный явно назначен только кнопкам `FilledButton` и FAB.

## Что не подтверждено источником

- Брендбук и официальные цвета компании не опубликованы. Палитра восстановлена по CSS сайта и файлу логотипа. Сайт в марте 2025 пересобрало агентство ASMART (по данным `Ресерч_Модус_Трейд.md`), поэтому не исключено, что «фирменные» значения — это выбор агентства, а не брендбук.
- В логотипе и на кнопках два красных: `#ED1111` и `#E40000`. Какой из них официальный, неизвестно. Мы взяли `#E40000`, потому что он чаще встречается и проходит AA.
- Шрифт логотипа не определён: надпись в SVG нарисована кривыми, а не текстом.
- Нет данных о тёмной теме, цветах статусов и иконочном наборе компании — эти решения наши.
- Gilroy заменён на Manrope по визуальной близости; согласования с компанией не было.
