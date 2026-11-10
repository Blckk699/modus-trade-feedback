import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

/// Разделы приложения. Набор зависит от `Me.permissions`, как в вебе:
/// сотрудник видит «Мои обращения» и ленту, руководитель и собственник — ещё обработку
/// и сводку, администратор — настройки. Права клиент не вычисляет, только читает.
enum Section {
  myAppeals('Мои обращения', 'Обращения', Icons.inbox_outlined, Icons.inbox),
  processing('Обработка', 'Обработка', Icons.assignment_outlined, Icons.assignment),
  feed('Обсуждения и реализованное', 'Лента', Icons.forum_outlined, Icons.forum),
  analytics('Сводка', 'Сводка', Icons.insights_outlined, Icons.insights),
  meetings('Совещания', 'Совещания', Icons.groups_outlined, Icons.groups),
  settings('Настройки', 'Настройки', Icons.tune_outlined, Icons.tune),
  profile('Профиль', 'Профиль', Icons.person_outline, Icons.person);

  const Section(this.title, this.shortTitle, this.icon, this.selectedIcon);

  final String title;
  final String shortTitle;
  final IconData icon;
  final IconData selectedIcon;
}

/// Разделы, доступные пользователю, в порядке показа.
List<Section> sectionsFor(Me me) {
  final p = me.permissions;
  return [
    if (p.canCreateAppeal) Section.myAppeals,
    if (p.canProcessAppeals) Section.processing,
    Section.feed,
    if (p.analyticsScope != PermissionsAnalyticsScopeEnum.none) Section.analytics,
    if (p.canUploadMeetings) Section.meetings,
    if (p.canManageSettings) Section.settings,
    Section.profile,
  ];
}

/// Стартовый экран роли: собственник и руководитель — сводка, администратор — настройки,
/// у кого есть открытые назначенные обращения — обработка, остальные — свои обращения.
Section startSectionFor(Me me) {
  final available = sectionsFor(me);
  final preferred = switch (me.role) {
    Role.owner || Role.head => Section.analytics,
    Role.admin => Section.settings,
    _ => me.assignedOpenCount > 0 ? Section.processing : Section.myAppeals,
  };
  return available.contains(preferred) ? preferred : available.first;
}
