import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app.dart';
import '../../theme/modus_theme.dart';
import '../web/web_ui.dart';
import 'access_tab.dart';
import 'categories_tab.dart';
import 'deadlines_tab.dart';
import 'departments_tab.dart';
import 'unassigned_tab.dart';
import 'users_tab.dart';
import '../home/role_switch.dart';

/// Раздел настроек: название, пояснение, значок и экран.
class _Part {
  const _Part(this.code, this.title, this.sub, this.icon, this.body);

  final String code;
  final String title;
  final String sub;
  final IconData icon;
  final Widget body;
}

/// Настройки администратора (истории 64–70). Раздел в навигации виден только при
/// `Me.permissions.can_manage_settings`; права на сами операции проверяет бэкенд.
/// На телефоне — список разделов строками с шевроном; раздел открывается своим экраном.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = SessionScope.of(context).me.permissions;
    final c = ModusColors.of(context);
    // Администратор — все разделы; собственник — только «Доступ» (can_manage_access), как в вебе.
    final parts = <_Part>[
      if (p.canManageAccess)
        const _Part('access', 'Доступ', 'Заявки на вход и приглашения', LucideIcons.userPlus, AccessTab()),
      if (p.canManageSettings) ...const [
        _Part('unassigned', 'Нераспределённые', 'Обращения без ответственного', LucideIcons.inbox, UnassignedTab()),
        _Part('users', 'Сотрудники', 'Роли, подразделения, отсутствие', LucideIcons.users, UsersTab()),
        _Part('departments', 'Подразделения', 'Структура компании', LucideIcons.building2, DepartmentsTab()),
        _Part('categories', 'Категории', 'Темы и ответственные', LucideIcons.tags, CategoriesTab()),
        _Part('deadlines', 'Сроки', 'Сроки первого ответа', LucideIcons.timer, DeadlinesTab()),
      ],
    ];
    // Один раздел — сразу его содержимое, без лишнего шага.
    if (parts.length == 1) return _PartScreen(part: parts.single, root: true);
    return Scaffold(
      body: WebScrollPage(
        title: 'Настройки',
        tools: const [RoleSwitchAction()],
        children: [
          Container(
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(Web.rCard)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 64, color: c.palette.border),
                InkWell(
                  key: Key('settings-${parts[i].code}'),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => _PartScreen(part: parts[i]))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(11)),
                        child: Icon(parts[i].icon, size: 18, color: c.heading),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(parts[i].title,
                              style: TextStyle(color: c.heading, fontSize: 15.5, fontWeight: FontWeight.w600)),
                          Text(parts[i].sub, style: TextStyle(color: c.muted, fontSize: 13)),
                        ]),
                      ),
                      Icon(LucideIcons.chevronRight, size: 18, color: c.faint),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _PartScreen extends StatelessWidget {
  const _PartScreen({required this.part, this.root = false});

  final _Part part;
  final bool root;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          key: root ? Key('settings-${part.code}') : null,
          automaticallyImplyLeading: !root,
          title: Text(part.title),
          actions: root ? const [RoleSwitchAction()] : null,
        ),
        body: part.body,
      );
}
