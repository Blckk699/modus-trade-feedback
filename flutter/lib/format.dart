import 'package:intl/intl.dart';

/// Часовой пояс системы — UTC+5 (SPEC, «Сроки и эскалация»). Время показываем в нём,
/// независимо от пояса телефона, чтобы сроки совпадали с вебом и ботом.
const systemOffset = Duration(hours: 5);

DateTime _system(DateTime t) => t.toUtc().add(systemOffset);

final _dateTime = DateFormat('d MMMM y, HH:mm', 'ru');
final _date = DateFormat('d MMMM y', 'ru');
final _time = DateFormat('HH:mm', 'ru');
final _dayKey = DateFormat('yyyy-MM-dd', 'ru');

String formatDateTime(DateTime t) => _dateTime.format(_system(t));

String formatDate(DateTime t) => _date.format(_system(t));

/// Время по UTC+5: «14:05».
String formatTime(DateTime t) => _time.format(_system(t));

/// Календарный день по UTC+5 для группировки: «2026-11-12».
String dayKey(DateTime t) => _dayKey.format(_system(t));

/// Заголовок дня: «Сегодня», «Вчера» или «12 ноября 2026».
String formatDayTitle(DateTime t, {DateTime? now}) {
  final today = dayKey(now ?? DateTime.now());
  final key = dayKey(t);
  if (key == today) return 'Сегодня';
  if (key == dayKey((now ?? DateTime.now()).subtract(const Duration(days: 1)))) return 'Вчера';
  return formatDate(t);
}

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} КБ';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} МБ';
}
