import 'package:flutter/painting.dart';

import 'tokens.g.dart';

/// Веб после редизайна (#152–#154) ушёл от `design/tokens.json`: светлые фоны, тёмная тема
/// на нейтральных серых без синего оттенка, крупные скругления, поля без рамок.
/// Приложение повторяет веб (F-14, #196): значения — из `web/src/styles/global.css`,
/// поверх токенов (статусы, акцент, danger/warn/success остаются из токенов).
abstract final class WebLook {
  /// `--r-card`: карточки и листы.
  static const double cardRadius = 24;

  /// `--r-tile`: плитки, блоки внутри карточки.
  static const double tileRadius = 18;

  /// `--r-ctl`: кнопки и поля.
  static const double controlRadius = 14;

  /// `--ctl-h`.
  static const double controlHeight = 44;
}

/// Цвета веба, которых нет в [ModusPalette].
class WebExtra {
  const WebExtra({
    required this.card,
    required this.surface3,
    required this.faint,
    required this.people,
    required this.peopleBg,
    required this.shadowRaised,
    required this.shadowFocus,
    required this.tipBg,
    required this.tipText,
  });

  /// `--card`: фон карточек на `--bg`.
  final Color card;

  /// `--surface-3`.
  final Color surface3;

  /// `--faint`: самый тихий текст.
  final Color faint;

  /// `--people` / `--people-bg`: чип «Об этом сказали N человек».
  final Color people;
  final Color peopleBg;

  /// Тени поля: в покое (`--shadow-raised`) и в фокусе (`--shadow-focus`).
  final List<BoxShadow> shadowRaised;
  final List<BoxShadow> shadowFocus;

  /// `--tip-bg` / `--tip-text`: всплывающие сообщения.
  final Color tipBg;
  final Color tipText;
}

final webLightPalette = lightPalette.copyWith(
  bg: const Color(0xFFEDF0F4),
  surface: const Color(0xFFFFFFFF),
  surface2: const Color(0xFFF1F3F7),
  border: const Color(0xFFE2E6EC),
  borderInput: const Color(0xFF848FA0),
  primaryHover: const Color(0xFF123A5E),
);

const webLightExtra = WebExtra(
  card: Color(0xFFF8F9FB),
  surface3: Color(0xFFE6EAF0),
  faint: Color(0xFF8591A3),
  people: Color(0xFF7A5300),
  peopleBg: Color(0xFFFFF1C2),
  shadowRaised: [
    BoxShadow(color: Color(0x0F082742), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0D082742), offset: Offset(0, 2), blurRadius: 8),
  ],
  shadowFocus: [
    BoxShadow(color: Color(0x12082742), spreadRadius: 2),
    BoxShadow(color: Color(0x14082742), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color(0x1F082742), offset: Offset(0, 8), blurRadius: 22),
  ],
  tipBg: Color(0xFF0B1F33),
  tipText: Color(0xFFFFFFFF),
);

final webDarkPalette = darkPalette.copyWith(
  bg: const Color(0xFF0D0D0D),
  surface: const Color(0xFF202020),
  surface2: const Color(0xFF1B1B1B),
  text: const Color(0xFFE8E8E8),
  heading: const Color(0xFFFFFFFF),
  muted: const Color(0xFFA6A6A6),
  border: const Color(0xFF2A2A2A),
  borderInput: const Color(0xFF787878),
  primary: const Color(0xFFF2F2F2),
  primaryHover: const Color(0xFFFFFFFF),
  onPrimary: const Color(0xFF111111),
  status: {
    ...darkPalette.status,
    'in_review': const StatusColor(Color(0xFFE0E0E0), Color(0xFF343434)),
    'closed': const StatusColor(Color(0xFFA6A6A6), Color(0xFF262626)),
  },
);

const webDarkExtra = WebExtra(
  card: Color(0xFF171717),
  surface3: Color(0xFF2C2C2C),
  faint: Color(0xFF808080),
  people: Color(0xFFF5D06B),
  peopleBg: Color(0xFF3A3010),
  shadowRaised: [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2)],
  shadowFocus: [
    BoxShadow(color: Color(0x14FFFFFF), spreadRadius: 2),
    BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 22),
  ],
  tipBg: Color(0xFFEDEDED),
  tipText: Color(0xFF111111),
);
