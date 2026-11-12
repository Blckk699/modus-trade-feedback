import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app.dart';
import '../../theme/modus_theme.dart';
import '../appeals/card_parts.dart' show FactsTile;
import '../web/web_ui.dart';
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
    final c = ModusColors.of(context);
    return Scaffold(
      body: WebScrollPage(
        title: 'Профиль',
        tools: const [RoleSwitchAction()],
        children: [
          WebCard(
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
                child: Text(initials(me.fullName),
                    style: TextStyle(color: c.heading, fontSize: 19, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(me.fullName, style: TextStyle(color: c.heading, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(me.position ?? session.roleLabel(me.role), style: TextStyle(color: c.muted, fontSize: 14)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: Web.gap),
          FactsTile([
            ('Роль', session.roleLabel(me.role)),
            if (me.department != null) ('Подразделение', me.department!.name),
            if (me.responsibleFor.isNotEmpty) ('Отвечаю за', me.responsibleFor.map((x) => x.name).join(', ')),
            if (me.deputyFor.isNotEmpty) ('Замещаю по темам', me.deputyFor.map((x) => x.name).join(', ')),
          ]),
          const SizedBox(height: 28),
          WebButton(
            key: const Key('logout'),
            kind: WebButtonKind.ghostDanger,
            icon: const Icon(LucideIcons.logOut),
            label: 'Выйти',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(height: 8),
          Text('Сервер: ${session.serverUrl}', textAlign: TextAlign.center, style: TextStyle(color: c.faint, fontSize: 12)),
        ],
      ),
    );
  }
}
