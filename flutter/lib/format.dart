import 'package:intl/intl.dart';

/// Часовой пояс системы — UTC+5 (SPEC, «Сроки и эскалация»). Время показываем в нём,
/// независимо от пояса телефона, чтобы сроки совпадали с вебом и ботом.
const systemOffset = Duration(hours: 5);

DateTime _system(DateTime t) => t.toUtc().add(systemOffset);

final _dateTime = DateFormat('d MMMM y, HH:mm', 'ru');
final _date = DateFormat('d MMMM y', 'ru');

String formatDateTime(DateTime t) => _dateTime.format(_system(t));

String formatDate(DateTime t) => _date.format(_system(t));

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} КБ';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} МБ';
}
