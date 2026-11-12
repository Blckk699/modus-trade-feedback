import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../session/session_controller.dart';
import '../appeals/appeal_screen.dart';

/// Кнопка демо-переключателя ролей в шапке (B-22, как W-14 в вебе): кто сейчас вошёл
/// и связанные пользователи. Без связанных пользователей не показывается.
/// [appealId] — открытая карточка: после переключения она остаётся, если видна новой роли.
class RoleSwitchAction extends StatelessWidget {
  const RoleSwitchAction({super.key, this.appealId});

  final int? appealId;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (session.status != SessionStatus.signedIn || session.me.switchTargets.isEmpty) return const SizedBox.shrink();
    final me = session.me;
    return IconButton(
      key: const Key('role-switch'),
      tooltip: 'Сменить роль. Сейчас: ${me.fullName}, ${session.roleLabel(me.role)}',
      icon: CircleAvatar(radius: 15, child: Text(_initial(me.fullName), style: const TextStyle(fontSize: 13))),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => RoleSwitchSheet(appealId: appealId),
      ),
    );
  }
}

String _initial(String name) => name.trim().isEmpty ? '?' : name.trim()[0];

/// Список ролей: текущий пользователь с галочкой и те, под кого можно переключиться.
class RoleSwitchSheet extends StatefulWidget {
  const RoleSwitchSheet({super.key, this.appealId});

  final int? appealId;

  @override
  State<RoleSwitchSheet> createState() => _RoleSwitchSheetState();
}

class _RoleSwitchSheetState extends State<RoleSwitchSheet> {
  int? _busyId;
  String? _error;

  Future<void> _switch(UserBrief target) async {
    final session = SessionScope.read(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busyId = target.id;
      _error = null;
    });
    try {
      await session.switchTo(target.id);
    } on AppError catch (e) {
      if (mounted) {
        setState(() {
          _busyId = null;
          _error = e.message;
        });
      }
      return;
    }
    // Новая роль начинает со своего стартового экрана; открытую карточку оставляем, если она ей видна.
    navigator.popUntil((r) => r.isFirst);
    final appealId = widget.appealId;
    if (appealId == null) return;
    try {
      await session.api.appeals.getAppeal(appealId);
      navigator.push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: appealId)));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('${target.fullName} не видит это обращение — открыт стартовый экран роли.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final me = session.me;
    final theme = Theme.of(context);
    Widget row(UserBrief u, {required bool current}) => ListTile(
          key: Key('switch-to-${u.id}'),
          leading: CircleAvatar(child: Text(_initial(u.fullName))),
          title: Text(u.fullName),
          subtitle: Text(_busyId == u.id
              ? 'Переключаем…'
              : [session.roleLabel(u.role), if (u.department != null) u.department!.name].join(' · ')),
          trailing: current ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
          enabled: _busyId == null,
          onTap: current ? () => Navigator.of(context).pop() : () => _switch(u),
        );
    final self = UserBrief(id: me.id, fullName: me.fullName, role: me.role, department: me.department);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Сменить роль', style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Демо: одно обращение под разными ролями',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          row(self, current: true),
          for (final t in me.switchTargets) row(t, current: false),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, key: const Key('switch-error'), style: TextStyle(color: theme.colorScheme.error)),
            ),
        ],
      ),
    );
  }
}
