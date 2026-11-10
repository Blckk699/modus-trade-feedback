import 'package:flutter/material.dart';

import 'categories_tab.dart';
import 'deadlines_tab.dart';
import 'departments_tab.dart';
import 'unassigned_tab.dart';
import 'users_tab.dart';

/// Настройки администратора (истории 64–70). Раздел в навигации виден только при
/// `Me.permissions.can_manage_settings`; права на сами операции проверяет бэкенд.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Настройки'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(key: Key('settings-users'), text: 'Сотрудники'),
              Tab(key: Key('settings-departments'), text: 'Подразделения'),
              Tab(key: Key('settings-categories'), text: 'Категории'),
              Tab(key: Key('settings-deadlines'), text: 'Сроки'),
              Tab(key: Key('settings-unassigned'), text: 'Нераспределённые'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          UsersTab(),
          DepartmentsTab(),
          CategoriesTab(),
          DeadlinesTab(),
          UnassignedTab(),
        ]),
      ),
    );
  }
}
