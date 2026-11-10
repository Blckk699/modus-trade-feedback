import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

/// Разделы приложения. Набор зависит от `Me.permissions`, как в вебе:
/// сотрудник видит «Мои обращения» и ленту, руководитель и собственник — ещё обработку
/// и сводку, администратор — настройки. Права клиент не вычисляет, только читает.
enum Section {
  myAppeals('Мои обращения', 'Обращения', Icons.inbox_outlined, Icons.inbox),
  processing('Обработка', 'Обработка', Icons.assignment_outlined, Icons.assignment),
  feed('Лента реализованного', 'Лента', Icons.forum_outlined, Icons.forum),
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

/// Разделы, доступные пользователю, в порядке показа. Повторяет `buildNav` из
/// `web/src/app/navigation.ts`; профиль — только в мобильном приложении.
List<Section> sectionsFor(Me me) {
  final p = me.permissions;
  return [
    if (p.canCreateAppeal) Section.myAppeals,
    Section.feed,
    if (p.canProcessAppeals || p.canViewDepartment || p.canViewAllAppeals || p.canViewUnassigned)
      Section.processing,
    if (p.analyticsScope != PermissionsAnalyticsScopeEnum.none) Section.analytics,
    if (p.canUploadMeetings) Section.meetings,
    if (p.canManageSettings) Section.settings,
    Section.profile,
  ];
}

/// Стартовый экран роли, как `startPath` в вебе: собственник и руководитель — сводка,
/// администратор — настройки (если раздела нет — обработка, затем свои обращения),
/// остальные — свои обращения.
Section startSectionFor(Me me) {
  final available = sectionsFor(me);
  final preferred = switch (me.role) {
    Role.owner || Role.head => const [Section.analytics, Section.processing, Section.myAppeals],
    Role.admin => const [Section.settings, Section.processing, Section.myAppeals],
    _ => const [Section.myAppeals],
  };
  return preferred.firstWhere(available.contains, orElse: () => available.first);
}
