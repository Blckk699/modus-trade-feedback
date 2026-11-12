import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('время с суффиксом Z и со смещением +05:00 показывается одинаково — по UTC+5', () {
    final z = DateTime.parse('2026-11-14T13:00:00Z');
    final plus5 = DateTime.parse('2026-11-14T18:00:00+05:00');
    expect(formatDateTime(z), '14 ноября 2026, 18:00');
    expect(formatDateTime(plus5), '14 ноября 2026, 18:00');
    expect(formatDate(plus5), formatDate(z));
  });
}
