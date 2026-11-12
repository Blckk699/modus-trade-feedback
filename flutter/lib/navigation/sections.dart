import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';

/// Разделы приложения. Набор зависит от `Me.permissions`, как в вебе:
/// сотрудник видит «Мои обращения» и ленту, руководитель и собственник — ещё обработку
/// и сводку, администратор — настройки. Права клиент не вычисляет, только читает.
enum Section {
  home('Сегодня', 'Сегодня', LucideIcons.layoutGrid, LucideIcons.layoutGrid),
  myAppeals('Мои обращения', 'Мои', LucideIcons.fileText, LucideIcons.fileText),
  processing('Входящие', 'Входящие', LucideIcons.inbox, LucideIcons.inbox),
  feed('Лента', 'Лента', LucideIcons.messagesSquare, LucideIcons.messagesSquare),
  analytics('Сводка', 'Сводка', LucideIcons.chartColumn, LucideIcons.chartColumn),
  meetings('Совещания', 'Совещания', LucideIcons.audioLines, LucideIcons.audioLines),
  settings('Настройки', 'Настройки', LucideIcons.settings, LucideIcons.settings),
  profile('Профиль', 'Профиль', LucideIcons.circleUser, LucideIcons.circleUser);

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
