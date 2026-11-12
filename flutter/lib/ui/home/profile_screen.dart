import 'package:flutter/material.dart';

import '../../app.dart';
import 'role_switch.dart';

/// Кто я: роль, подразделение, назначения ответственным; выход.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из приложения?'),
        content: const Text('Чтобы войти снова, понадобится новый код из бота.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            key: const Key('logout-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await SessionScope.read(context).logout();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final me = session.me;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль'), actions: const [RoleSwitchAction()]),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(me.fullName.isEmpty ? '?' : me.fullName[0])),
            title: Text(me.fullName, style: theme.textTheme.titleMedium),
            subtitle: Text(me.position ?? session.roleLabel(me.role)),
          ),
          const Divider(),
          _Row(label: 'Роль', value: session.roleLabel(me.role)),
          if (me.department != null) _Row(label: 'Подразделение', value: me.department!.name),
          if (me.responsibleFor.isNotEmpty)
            _Row(label: 'Ответственный', value: me.responsibleFor.map((c) => c.name).join(', ')),
          if (me.deputyFor.isNotEmpty)
            _Row(label: 'Заместитель', value: me.deputyFor.map((c) => c.name).join(', ')),
          _Row(label: 'Сервер', value: session.serverUrl),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const Key('logout'),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(label, style: Theme.of(context).textTheme.bodySmall),
        subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      );
}
