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
  const small = BorderRadius.all(Radius.circular(WebLook.controlRadius));
  const card = BorderRadius.all(Radius.circular(WebLook.cardRadius));
  const sheet = BorderRadius.vertical(top: Radius.circular(WebLook.cardRadius));
  const minSize = Size(64, WebLook.controlHeight);
  const none = OutlineInputBorder(borderRadius: small, borderSide: BorderSide.none);
  final buttonText = text.labelLarge;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: ModusFont.body,
    textTheme: text,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    extensions: [ModusColors(p, x)],
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.heading,
      titleTextStyle: text.titleLarge,
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
        shape: const RoundedRectangleBorder(borderRadius: small),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        shape: const RoundedRectangleBorder(borderRadius: small),
        side: BorderSide(color: p.borderInput),
        foregroundColor: p.primary,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.link, textStyle: buttonText),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      shape: const RoundedRectangleBorder(borderRadius: small),
      extendedTextStyle: buttonText,
    ),
    badgeTheme: BadgeThemeData(backgroundColor: p.accent, textColor: p.onAccent),
    // Поля как в вебе (#154, #193): без рамок, заливка поверхностью; ошибка — заливкой danger-bg.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: none,
      enabledBorder: none,
      focusedBorder: none,
      disabledBorder: none,
      errorBorder: none,
      focusedErrorBorder: none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: const RoundedRectangleBorder(borderRadius: small),
      side: BorderSide.none,
      backgroundColor: p.surface2,
    ),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: p.surface, indicatorColor: p.surface2, height: ModusSize.bottombar + 12),
    tabBarTheme: TabBarThemeData(labelColor: p.primary, unselectedLabelColor: p.muted, indicatorColor: p.primary),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: sheet),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(WebLook.cardRadius))),
    ),
    popupMenuTheme: const PopupMenuThemeData(elevation: 3),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
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
    side: BorderSide(color: c.danger),
  );
}

TextStyle _style(TypeToken t, Color color) => TextStyle(
  fontFamily: t.family,
  fontWeight: FontWeight.values[(t.weight ~/ 100) - 1],
  fontSize: t.size,
  height: t.height,
  letterSpacing: t.letterSpacing,
  color: color,
);

TextTheme _textTheme(ModusPalette p) {
  final heading = _style(ModusType.display, p.heading);
  return TextTheme(
    displayLarge: heading.copyWith(fontSize: 40),
    displayMedium: heading.copyWith(fontSize: 34),
    displaySmall: heading,
    headlineLarge: heading.copyWith(fontSize: 28),
    headlineMedium: heading.copyWith(fontSize: 26),
    headlineSmall: heading.copyWith(fontSize: 24),
    titleLarge: _style(ModusType.title, p.heading),
    titleMedium: _style(ModusType.subtitle, p.heading),
    titleSmall: _style(ModusType.bodySm, p.text).copyWith(fontWeight: FontWeight.w600),
    bodyLarge: _style(ModusType.body, p.text),
    bodyMedium: _style(ModusType.bodySm, p.text),
    bodySmall: _style(ModusType.caption, p.muted).copyWith(fontWeight: FontWeight.w500),
    labelLarge: _style(ModusType.button, p.text),
    labelMedium: _style(ModusType.caption, p.text),
    labelSmall: _style(ModusType.caption, p.muted),
  );
}
