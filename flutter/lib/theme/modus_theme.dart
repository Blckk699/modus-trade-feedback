import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.g.dart';
import 'web_palette.dart';

export 'tokens.g.dart' show ModusRadius, ModusSpacing, StatusColor;
export 'web_palette.dart' show WebLook, WebExtra;

/// Фирменные цвета, которых нет в [ColorScheme]: статусы, акцент, ссылки, предупреждения.
/// Берутся из `design/tokens.json` через [ModusPalette].
@immutable
class ModusColors extends ThemeExtension<ModusColors> {
  const ModusColors(this.palette, this.extra);

  final ModusPalette palette;

  /// Цвета и тени веба, которых нет в токенах.
  final WebExtra extra;

  /// Цвета текущей темы. Без расширения (например, в тестах на голом MaterialApp) — палитра по яркости.
  static ModusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ModusColors>() ??
        (theme.brightness == Brightness.dark
            ? ModusColors(webDarkPalette, webDarkExtra)
            : ModusColors(webLightPalette, webLightExtra));
  }

  /// Цвета бейджа статуса по коду (`new`, `in_review`, …).
  StatusColor status(String code) => palette.status[code] ?? palette.status['closed']!;

  Color get accent => palette.accent;
  Color get onAccent => palette.onAccent;
  Color get heading => palette.heading;
  Color get muted => palette.muted;
  Color get surface2 => palette.surface2;
  Color get warn => palette.warn;
  Color get warnBg => palette.warnBg;
  Color get success => palette.success;
  Color get successBg => palette.successBg;
  Color get info => palette.info;
  Color get infoBg => palette.infoBg;
  Color get danger => palette.danger;
  Color get dangerBg => palette.dangerBg;
  Color get card => extra.card;
  Color get faint => extra.faint;
  Color get people => extra.people;
  Color get peopleBg => extra.peopleBg;
  Color get surface => palette.surface;
  Color get bg => palette.bg;

  @override
  ModusColors copyWith() => this;

  @override
  ModusColors lerp(ModusColors? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Тема приложения по токенам: `primary` — тёмно-синий, фирменный красный (`accent`)
/// только у главного действия экрана (FAB и [accentButtonStyle]). См. design/README.md.
ThemeData modusTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final p = light ? webLightPalette : webDarkPalette;
  final x = light ? webLightExtra : webDarkExtra;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.surface2,
    onPrimaryContainer: p.heading,
    // Красный не отдаём в secondary: на нём стандартные виджеты (переключатели, индикаторы).
    secondary: p.primary,
    onSecondary: p.onPrimary,
    secondaryContainer: p.surface2,
    onSecondaryContainer: p.heading,
    tertiary: p.link,
    onTertiary: p.onPrimary,
    tertiaryContainer: p.warnBg,
    onTertiaryContainer: p.warn,
    error: p.danger,
    onError: p.onAccent,
    errorContainer: p.dangerBg,
    onErrorContainer: p.danger,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface2,
    surfaceContainerHigh: p.surface2,
    surfaceContainerHighest: p.surface2,
    outline: p.borderInput,
    outlineVariant: p.border,
  );

  final text = _textTheme(p);
  const pill = StadiumBorder();
  const small = BorderRadius.all(Radius.circular(WebLook.controlRadius));
  const card = BorderRadius.all(Radius.circular(WebLook.cardRadius));
  const sheet = BorderRadius.vertical(top: Radius.circular(WebLook.cardRadius));
  const minSize = Size(64, WebLook.controlHeight);
  // Underline, а не Outline: у заполненного поля без рамки подпись остаётся внутри, а не над полем.
  const none = UnderlineInputBorder(borderRadius: small, borderSide: BorderSide.none);
  final buttonText = text.labelLarge;

  return ThemeData(
    useMaterial3: true,
    // Не Material-2016: без «волн» на всю плитку, без серой тонировки поверхностей, переходы как в iOS.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    }),
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: ModusFont.body,
    textTheme: text,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    extensions: [ModusColors(p, x)],
    // Заголовок экрана как `.head__title` в вебе: слева, крупно, 500, плотный трекинг.
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.heading,
      centerTitle: false,
      toolbarHeight: 64,
      titleSpacing: 16,
      titleTextStyle: TextStyle(
        fontFamily: ModusFont.body,
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.12,
        letterSpacing: -0.9,
        color: p.heading,
      ),
    ),
    cardTheme: CardThemeData(
      color: x.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: card),
    ),
    dividerTheme: DividerThemeData(color: p.border),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: pill,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      // Второстепенная кнопка как `.btn--soft`: серая подложка, без рамки.
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: pill,
        side: BorderSide.none,
        backgroundColor: x.surface3,
        foregroundColor: p.heading,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.link, textStyle: buttonText, shape: pill),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      shape: const CircleBorder(),
      extendedTextStyle: buttonText,
    ),
    badgeTheme: BadgeThemeData(backgroundColor: p.accent, textColor: p.onAccent),
    // Поля как в вебе (#154, #193): без рамок, заливка поверхностью; ошибка — заливкой danger-bg.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // Заливка отличается и от фона экрана, и от листов и карточек, иначе поле в нижнем листе не видно.
      fillColor: light ? p.surface2 : x.surface3,
      border: none,
      enabledBorder: none,
      focusedBorder: none,
      disabledBorder: none,
      errorBorder: none,
      focusedErrorBorder: none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: pill,
      side: BorderSide.none,
      backgroundColor: p.surface2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: x.card,
      indicatorColor: x.surface3,
      height: 64,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontFamily: ModusFont.body, fontSize: 11.5, fontWeight: FontWeight.w600, color: p.text)),
    ),
    // Переключатель как `.segmented`: пилюля на surface-3, выбранный — поверхностью.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(pill),
        side: const WidgetStatePropertyAll(BorderSide.none),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.surface : x.surface3),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.heading : p.muted),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: ModusFont.body, fontSize: 13.5, fontWeight: FontWeight.w600)),
      ),
    ),

    tabBarTheme: TabBarThemeData(labelColor: p.primary, unselectedLabelColor: p.muted, indicatorColor: p.primary),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: x.faint,
      dragHandleSize: const Size(40, 5),
      shape: const RoundedRectangleBorder(borderRadius: sheet),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(WebLook.cardRadius))),
    ),
    popupMenuTheme: PopupMenuThemeData(elevation: 3, color: p.surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: x.tipBg,
      contentTextStyle: TextStyle(fontFamily: ModusFont.body, color: x.tipText, fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// Кнопка главного действия экрана — фирменный красный. Одна на экран.
ButtonStyle accentButtonStyle(BuildContext context) {
  final c = ModusColors.of(context);
  return FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.onAccent);
}

/// Опасное действие («Отклонить»): обводка `danger`, без заливки.
ButtonStyle dangerButtonStyle(BuildContext context) {
  final c = ModusColors.of(context);
  return OutlinedButton.styleFrom(
    foregroundColor: c.danger,
    backgroundColor: Colors.transparent,
    side: BorderSide.none,
  );
}

/// Шрифт веба (#152): Manrope везде, заголовки 500–600 с плотным трекингом, без Montserrat.
TextTheme _textTheme(ModusPalette p) {
  TextStyle m(double size, FontWeight w, Color c, {double height = 1.35, double ls = 0}) =>
      TextStyle(fontFamily: ModusFont.body, fontSize: size, fontWeight: w, height: height, letterSpacing: ls, color: c);
  final h = p.heading;
  return TextTheme(
    displayLarge: m(40, FontWeight.w500, h, height: 1.1, ls: -1.4),
    displayMedium: m(34, FontWeight.w500, h, height: 1.1, ls: -1.2),
    displaySmall: m(28, FontWeight.w500, h, height: 1.15, ls: -0.9),
    headlineLarge: m(28, FontWeight.w500, h, height: 1.15, ls: -0.9),
    headlineMedium: m(26, FontWeight.w500, h, height: 1.12, ls: -0.9),
    headlineSmall: m(24, FontWeight.w600, h, height: 1.2, ls: -0.5),
    titleLarge: m(22, FontWeight.w600, h, height: 1.25, ls: -0.3),
    titleMedium: m(17, FontWeight.w600, h, ls: -0.2),
    titleSmall: m(15, FontWeight.w600, h),
    bodyLarge: m(16, FontWeight.w500, p.text, height: 1.5),
    bodyMedium: m(15, FontWeight.w500, p.text, height: 1.5),
    bodySmall: m(13, FontWeight.w500, p.muted, height: 1.4),
    labelLarge: m(14, FontWeight.w600, p.text, height: 1.2),
    labelMedium: m(12, FontWeight.w600, p.text, height: 1.5),
    labelSmall: m(12, FontWeight.w600, p.muted, height: 1.4),
  );
}
