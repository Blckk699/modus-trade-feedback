import 'package:flutter/material.dart';

import '../../app.dart';
import 'access_tab.dart';
import 'categories_tab.dart';
import 'deadlines_tab.dart';
import 'departments_tab.dart';
import 'unassigned_tab.dart';
import 'users_tab.dart';
import '../home/role_switch.dart';

/// Настройки администратора (истории 64–70). Раздел в навигации виден только при
/// `Me.permissions.can_manage_settings`; права на сами операции проверяет бэкенд.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = SessionScope.of(context).me.permissions;
    // Администратор — все вкладки; собственник — только «Доступ» (can_manage_access), как в вебе.
    final tabs = <(Tab, Widget)>[
      if (p.canManageSettings) ...[
        (const Tab(key: Key('settings-users'), text: 'Сотрудники'), const UsersTab()),
        (const Tab(key: Key('settings-departments'), text: 'Подразделения'), const DepartmentsTab()),
        (const Tab(key: Key('settings-categories'), text: 'Категории'), const CategoriesTab()),
        (const Tab(key: Key('settings-deadlines'), text: 'Сроки'), const DeadlinesTab()),
        (const Tab(key: Key('settings-unassigned'), text: 'Нераспределённые'), const UnassignedTab()),
      ],
      if (p.canManageAccess) (const Tab(key: Key('settings-access'), text: 'Доступ'), const AccessTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Настройки'),
          actions: const [RoleSwitchAction()],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final (t, _) in tabs) t],
          ),
        ),
        body: TabBarView(children: [for (final (_, w) in tabs) w]),
      ),
    );
  }
}
