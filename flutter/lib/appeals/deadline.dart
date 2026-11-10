import '../format.dart';

/// Срок обсуждения выбирается датой; бэкенд ждёт date-time. Берём конец рабочего дня 18:00
/// в поясе системы UTC+5 (как `deadlineFromDate` в вебе), чтобы срок был одинаков для всех.
DateTime deadlineFromDate(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day, 18).subtract(systemOffset);

/// Сегодняшняя дата в поясе системы.
DateTime systemToday([DateTime? now]) {
  final t = (now ?? DateTime.now()).toUtc().add(systemOffset);
  return DateTime(t.year, t.month, t.day);
}
