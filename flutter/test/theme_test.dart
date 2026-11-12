import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/theme/modus_theme.dart';
import 'package:modus_feedback/theme/tokens.g.dart';

Color _hex(String v) {
  final h = v.substring(1);
  return Color(int.parse(h.length == 6 ? 'FF$h' : '${h.substring(6)}${h.substring(0, 6)}', radix: 16));
}

void main() {
  final tokens = jsonDecode(File('../design/tokens.json').readAsStringSync()) as Map<String, dynamic>;

  String resolve(String v) {
    while (v.startsWith('{')) {
      Object? node = tokens;
      for (final part in v.substring(1, v.length - 1).split('.')) {
        node = (node as Map<String, dynamic>)[part];
      }
      v = (node as Map<String, dynamic>)[r'$value'] as String;
    }
    return v;
  }

  test('tokens.g.dart совпадает с design/tokens.json (перегенерировать: python3 flutter/tool/generate_tokens.py)', () {
    for (final (theme, palette) in [('light', lightPalette), ('dark', darkPalette)]) {
      final c = tokens['color'][theme] as Map<String, dynamic>;
      Color token(String name) => _hex(resolve(c[name][r'$value'] as String));
      expect(palette.primary, token('primary'), reason: '$theme primary');
      expect(palette.accent, token('accent'), reason: '$theme accent');
      expect(palette.bg, token('bg'), reason: '$theme bg');
      expect(palette.text, token('text'), reason: '$theme text');
      expect(palette.danger, token('danger'), reason: '$theme danger');
      final status = c['status'] as Map<String, dynamic>;
      for (final code in AppealStatus.values.map((s) => s.toJson())) {
        expect(palette.status[code]!.fg, _hex(status[code]['fg'][r'$value'] as String), reason: '$theme $code fg');
        expect(palette.status[code]!.bg, _hex(status[code]['bg'][r'$value'] as String), reason: '$theme $code bg');
      }
    }
    expect(ModusRadius.sm, 4);
    expect(ModusRadius.lg, 10);
  });

  test('tokens.g.dart целиком совпадает с выводом генератора', () {
    final r = Process.runSync('python3', ['tool/generate_tokens.py', '--check']);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
  });

  test('тема: primary тёмно-синий, красный только у FAB и главной кнопки; шрифты из токенов', () {
    for (final b in Brightness.values) {
      final theme = modusTheme(b);
      final p = b == Brightness.light ? lightPalette : darkPalette;
      expect(theme.brightness, b);
      expect(theme.colorScheme.primary, p.primary);
      expect(theme.colorScheme.primary, isNot(p.accent), reason: 'красный не красит выбранные элементы');
      expect(theme.floatingActionButtonTheme.backgroundColor, p.accent);
      expect(theme.scaffoldBackgroundColor, p.bg);
      expect(theme.textTheme.titleLarge!.fontFamily, 'Montserrat');
      expect(theme.textTheme.bodyLarge!.fontFamily, 'Manrope');
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
      expect(theme.extension<ModusColors>()!.status('implemented').fg, p.status['implemented']!.fg);
    }
  });

  testWidgets('accentButtonStyle и dangerButtonStyle берут цвета из темы', (tester) async {
    late ButtonStyle accent;
    late ButtonStyle danger;
    await tester.pumpWidget(MaterialApp(
      theme: modusTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      home: Builder(builder: (context) {
        accent = accentButtonStyle(context);
        danger = dangerButtonStyle(context);
        return const SizedBox();
      }),
    ));
    expect(accent.backgroundColor!.resolve({}), darkPalette.accent);
    expect(danger.foregroundColor!.resolve({}), darkPalette.danger);
    expect(danger.backgroundColor, isNull, reason: 'опасное действие не заливается');
  });
}
