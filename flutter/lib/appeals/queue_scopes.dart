import 'package:modus_api/api.dart';

/// Охваты очереди только по `Me.permissions`, как `queueScopes` в вебе.
List<AppealScope> queueScopes(Me me) {
  final p = me.permissions;
  return [
    if (p.canViewDepartment) AppealScope.department,
    if (p.canViewAllAppeals) AppealScope.all,
    if (p.canViewUnassigned) AppealScope.unassigned,
    if (p.canProcessAppeals) AppealScope.assigned,
  ];
}

/// Стартовый охват — самый широкий, с которым роль работает (как `defaultScope` в вебе).
AppealScope? defaultQueueScope(Me me) {
  final scopes = queueScopes(me);
  final preferred = switch (me.role) {
    Role.owner => AppealScope.all,
    Role.head => AppealScope.department,
    Role.admin => AppealScope.unassigned,
    _ => AppealScope.assigned,
  };
  if (scopes.contains(preferred)) return preferred;
  return scopes.isEmpty ? null : scopes.first;
}

String scopeLabel(AppealScope scope) => switch (scope) {
      AppealScope.assigned => 'Назначенные мне',
      AppealScope.department => 'Подразделение',
      AppealScope.all => 'Все обращения',
      AppealScope.unassigned => 'Нераспределённые',
      AppealScope.mine => 'Мои',
    };

/// Открытые статусы — фильтр очереди по умолчанию.
const openStatuses = [
  AppealStatus.new_,
  AppealStatus.inReview,
  AppealStatus.awaitingInfo,
  AppealStatus.inProgress,
];

/// Сколько осталось до срока первого ответа. Сам срок и `due_state` считает бэкенд
/// в рабочих днях; здесь только разница во времени для показа (как `timeLeftLabel` в вебе).
String timeLeftLabel(DateTime dueAt, DateTime now) {
  final diffMin = (dueAt.difference(now).inSeconds / 60).round();
  final abs = diffMin.abs();
  final days = abs ~/ 1440;
  final hours = (abs % 1440) ~/ 60;
  final mins = abs % 60;
  final span = days > 0 ? '$days д $hours ч' : hours > 0 ? '$hours ч $mins мин' : '$mins мин';
  return diffMin >= 0 ? 'осталось $span' : 'просрочено на $span';
}
