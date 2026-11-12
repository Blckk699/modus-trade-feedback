import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

/// Разделы приложения. Набор зависит от `Me.permissions`, как в вебе:
/// сотрудник видит «Мои обращения» и ленту, руководитель и собственник — ещё обработку
/// и сводку, администратор — настройки. Права клиент не вычисляет, только читает.
enum Section {
  home('Сегодня', 'Сегодня', Icons.grid_view_outlined, Icons.grid_view_rounded),
  myAppeals('Мои обращения', 'Мои', Icons.description_outlined, Icons.description),
  processing('Входящие', 'Входящие', Icons.inbox_outlined, Icons.inbox),
  feed('Лента', 'Лента', Icons.forum_outlined, Icons.forum),
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
    Section.home,
    if (p.canCreateAppeal) Section.myAppeals,
    if (p.canProcessAppeals || p.canViewDepartment || p.canViewAllAppeals || p.canViewUnassigned)
      Section.processing,
    Section.feed,
    if (p.analyticsScope != PermissionsAnalyticsScopeEnum.none) Section.analytics,
    if (p.canUploadMeetings) Section.meetings,
    if (p.canManageSettings || p.canManageAccess) Section.settings,
    Section.profile,
  ];
}

/// Стартовый экран — «Сегодня» для всех ролей, как `startPath` в вебе: он сам собирается под права.
Section startSectionFor(Me me) => Section.home;
