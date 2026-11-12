import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/modus_theme.dart';
import 'brand_logo.g.dart';

/// Значения веба на телефоне (`@media (max-width: 760px)` в web/src/styles/global.css).
abstract final class Web {
  /// `--ctl-h` на телефоне.
  static const double ctlH = 46;

  /// `--r-ctl`.
  static const double rCtl = 14;

  /// `--r-card` на телефоне.
  static const double rCard = 22;

  /// `--r-tile`.
  static const double rTile = 18;

  /// `--gap` на телефоне.
  static const double gap = 12;
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Логотип «Модус Трейд» (BrandLogo). [ink] — цвет тёмных частей, по умолчанию `--heading`.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 104, this.height = 33, this.ink, this.surface});

  final double width;
  final double height;
  final Color? ink;
  final Color? surface;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return SvgPicture.string(
      brandLogo(ink: _hex(ink ?? c.heading), accent: _hex(c.accent), surface: _hex(surface ?? c.surface)),
      width: width,
      height: height,
    );
  }
}

/// Знак без надписи (BrandMark).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 27});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return SvgPicture.string(
      brandMark(ink: _hex(c.heading), accent: _hex(c.accent), surface: _hex(c.surface)),
      width: size,
      height: size,
    );
  }
}

/// `.field__label`: 13.5 / 600 / --heading, отступ 6 до поля.
class WebLabel extends StatelessWidget {
  const WebLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (optional)
              TextSpan(
                text: ' · необязательно',
                style: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.input`: поверхность, радиус 14, мягкая тень, без рамки; в фокусе — тень `--shadow-focus`;
/// ошибка — заливка `--danger-bg`. Подпись — над полем, как в вебе.
class WebInput extends StatefulWidget {
  const WebInput({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.error,
    this.helper,
    this.enabled = true,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.fieldKey,
    this.optional = false,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final String? error;
  final String? helper;
  final bool enabled;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final Key? fieldKey;
  final bool optional;
  final TextCapitalization textCapitalization;
  final bool autocorrect;

  @override
  State<WebInput> createState() => _WebInputState();
}

class _WebInputState extends State<WebInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final theme = Theme.of(context);
    final invalid = widget.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          DefaultTextStyle.merge(
            style: TextStyle(color: c.heading, fontSize: 13.5, fontWeight: FontWeight.w600),
            child: WebLabel(widget.label!, optional: widget.optional),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: Web.ctlH),
          decoration: BoxDecoration(
            color: invalid ? c.dangerBg : c.surface,
            borderRadius: BorderRadius.circular(Web.rCtl),
            boxShadow: invalid ? null : (_focus.hasFocus ? c.extra.shadowFocus : c.extra.shadowRaised),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: widget.fieldKey,
                  focusNode: _focus,
                  controller: widget.controller,
                  enabled: widget.enabled,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  minLines: widget.minLines,
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  autocorrect: widget.autocorrect,
                  textCapitalization: widget.textCapitalization,
                  enableSuggestions: !widget.obscure,
                  style: widget.style ?? TextStyle(fontSize: 15, height: 1.45, color: theme.colorScheme.onSurface),
                  cursorColor: c.heading,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    hintText: widget.hint,
                    hintStyle: TextStyle(color: c.muted, fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
              ?widget.suffix,
            ],
          ),
        ),
        if (widget.error != null || widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(widget.error ?? widget.helper!, style: TextStyle(fontSize: 13, height: 1.45, color: invalid ? c.danger : c.muted)),
          ),
      ],
    );
  }
}

enum WebButtonKind { primary, accent, soft, ghostDanger }

/// `.btn`: пилюля высотой `--ctl-h`, 14 / 600; нажатие — лёгкое сжатие (scale 0.98), как `:active` в вебе.
class WebButton extends StatefulWidget {
  const WebButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = WebButtonKind.primary,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final WebButtonKind kind;
  final Widget? icon;
  final bool busy;
  final bool expand;

  @override
  State<WebButton> createState() => _WebButtonState();
}

class _WebButtonState extends State<WebButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (widget.kind) {
      WebButtonKind.primary => (scheme.primary, scheme.onPrimary),
      WebButtonKind.accent => (c.accent, c.onAccent),
      WebButtonKind.soft => (c.extra.surface3, c.heading),
      WebButtonKind.ghostDanger => (Colors.transparent, c.danger),
    };
    final enabled = widget.onPressed != null && !widget.busy;
    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.busy)
          SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(color: fg, size: 18),
            child: widget.icon!,
          ),
          const SizedBox(width: 8),
        ],
        if (!widget.busy)
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            opacity: enabled || widget.busy ? 1 : 0.45,
            duration: const Duration(milliseconds: 150),
            child: Container(
              constraints: const BoxConstraints(minHeight: Web.ctlH),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// `--tile-navy`: фирменная плитка — градиент 150° и точечная сетка в правом верхнем углу (`.auth__brand`).
class BrandTile extends StatelessWidget {
  const BrandTile({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 22), this.radius = 22});

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark
        ? const [Color(0xFF262626), Color(0xFF333333), Color(0xFF474747)]
        : const [Color(0xFF082742), Color(0xFF0F4A80), Color(0xFF1A66C9)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // 150° в CSS: от верхнего левого угла вниз-вправо.
          gradient: LinearGradient(
            begin: const Alignment(-0.5, -1),
            end: const Alignment(0.5, 1),
            colors: colors,
            stops: const [0, 0.62, 1],
          ),
        ),
        child: CustomPaint(
          painter: _DotsPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Блик сверху справа: radial-gradient(90% 60% at 100% 0%, white 20%, transparent 60%).
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 0.9,
        colors: const [Color(0x33FFFFFF), Color(0x00FFFFFF)],
        stops: const [0, 0.6],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
    // Точки 14px, видны у верхнего правого угла и гаснут к низу-слева (mask 200°).
    final dot = Paint();
    for (double y = 7; y < size.height; y += 14) {
      for (double x = 7; x < size.width; x += 14) {
        final fade = ((x / size.width) * 0.6 + (1 - y / size.height) * 0.7 - 0.45).clamp(0.0, 1.0);
        if (fade <= 0) continue;
        dot.color = Color.fromRGBO(255, 255, 255, 0.16 * fade);
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// «или» с линиями по бокам (`.auth__or`).
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.text = 'или'});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final line = Expanded(child: Container(height: 1, color: c.palette.border));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(color: c.muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        line,
      ],
    );
  }
}

/// Пункт нижней панели (`.tabbar__link`): значок lucide и подпись 11 / 600;
/// выбранный — `--heading` на `--surface-2`, радиус 14.
class WebTab {
  const WebTab({this.key, required this.icon, required this.label, required this.onTap, this.active = false, this.badge = 0});

  final Key? key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final int badge;
}

/// Нижняя панель разделов (`.tabbar` на телефоне): поверхность 92% с размытием, линия сверху.
class WebTabBar extends StatelessWidget {
  const WebTabBar({super.key, required this.items});

  final List<WebTab> items;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(6, 6, 6, 6 + bottom),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: c.palette.border)),
          ),
          child: Row(
            children: [for (final t in items) Expanded(child: _TabButton(tab: t))],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab});

  final WebTab tab;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final color = tab.active ? c.heading : c.muted;
    Widget icon = Icon(tab.icon, size: 22, color: color);
    if (tab.badge > 0) {
      icon = Badge(
        key: const Key('unread-badge'),
        backgroundColor: c.accent,
        label: Text(tab.badge > 99 ? '99+' : '${tab.badge}'),
        child: icon,
      );
    }
    return Semantics(
      selected: tab.active,
      button: true,
      label: tab.label,
      child: GestureDetector(
        key: tab.key,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          tab.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(color: tab.active ? c.surface2 : Colors.transparent, borderRadius: BorderRadius.circular(14)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Круглая кнопка шапки (`.tool-btn` / `.cmd__toggle` на телефоне): 40×40, поверхность, мягкая тень.
class ToolButton extends StatelessWidget {
  const ToolButton({super.key, required this.icon, required this.onTap, this.badge = 0, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    Widget btn = Material(
      color: c.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(dimension: 40, child: Icon(icon, size: 20, color: c.heading)),
      ),
    );
    btn = DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: c.extra.shadowRaised),
      child: btn,
    );
    if (badge > 0) {
      btn = Badge(backgroundColor: c.accent, offset: const Offset(-2, 2), label: Text(badge > 99 ? '99+' : '$badge'), child: btn);
    }
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Шапка раздела на телефоне (`.head`): знак бренда в плашке 40×40, справа кнопки, ниже —
/// надзаголовок 12.5 / 600 / --muted и заголовок 27 / 500 / -0.035em.
class WebPageHead extends StatelessWidget {
  const WebPageHead({super.key, required this.title, this.over, this.tools = const [], this.leading});

  final String title;
  final String? over;
  final List<Widget> tools;

  /// Вместо знака бренда (например, «Назад» на вложенном экране).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading ??
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(13), boxShadow: c.extra.shadowRaised),
                    child: const BrandMark(size: 27),
                  ),
              const Spacer(),
              for (var i = 0; i < tools.length; i++) ...[if (i > 0) const SizedBox(width: 6), tools[i]],
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (over != null)
                  Text(
                    over!,
                    style: TextStyle(color: c.muted, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                Text(
                  title,
                  style: TextStyle(color: c.heading, fontSize: 27, fontWeight: FontWeight.w500, height: 1.12, letterSpacing: -0.95),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.card` на телефоне: `--card`, радиус 22, отступ 18.
class WebCard extends StatelessWidget {
  const WebCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
    color: ModusColors.of(context).card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Web.rCard)),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

/// `.card__head`: заголовок 17 / 600, счётчик, подзаголовок 13 / --muted, справа — чип-действие.
class WebCardHead extends StatelessWidget {
  const WebCardHead({super.key, required this.title, this.sub, this.count, this.action});

  final String title;
  final String? sub;
  final int? count;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(color: c.heading, fontSize: 17, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.25),
                      ),
                    ),
                    if (count != null) ...[const SizedBox(width: 8), WebCount(count!)],
                  ],
                ),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(sub!, style: TextStyle(color: c.muted, fontSize: 13, height: 1.4)),
                  ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

/// `.count`: фиолетовый кружок со счётом.
class WebCount extends StatelessWidget {
  const WebCount(this.n, {super.key});

  final int n;

  @override
  Widget build(BuildContext context) {
    final s = ModusColors.of(context).status('in_progress');
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        '$n',
        style: TextStyle(color: s.fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// `.chip`: белая пилюля 34, тень, 13 / 600 / --heading; нажатие сжимает.
class WebChip extends StatelessWidget {
  const WebChip({super.key, required this.label, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(shape: const StadiumBorder(), shadows: c.extra.shadowRaised),
      child: Material(
        color: c.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 14, color: c.heading), const SizedBox(width: 6)],
                Text(
                  label,
                  style: TextStyle(color: c.heading, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.more-link`: «Вся сводка →».
class WebMoreLink extends StatelessWidget {
  const WebMoreLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: c.heading, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Icon(LucideIcons.arrowRight, size: 16, color: c.heading),
        ],
      ),
    );
  }
}

/// `.fab` на телефоне: красный круг 56 с тенью `--shadow-fab`.
class WebFab extends StatelessWidget {
  const WebFab({super.key, required this.onTap, this.tooltip = 'Подать обращение'});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: dark
              ? const [
                  BoxShadow(color: Color(0x4D000000), offset: Offset(0, 2), blurRadius: 4),
                  BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 18),
                ]
              : const [
                  BoxShadow(color: Color(0x1F082742), offset: Offset(0, 2), blurRadius: 4),
                  BoxShadow(color: Color(0x29082742), offset: Offset(0, 8), blurRadius: 18),
                ],
        ),
        child: Material(
          color: c.accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: SizedBox.square(dimension: 56, child: Icon(LucideIcons.plus, size: 28, color: c.onAccent)),
          ),
        ),
      ),
    );
  }
}
