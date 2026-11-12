import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../app.dart';
import '../../theme/modus_theme.dart';
import '../../format.dart';
import '../appeals/appeal_screen.dart';
import 'shared.dart';

/// Очередь нераспределённых: администратор назначает ответственного вручную (история 70).
class UnassignedTab extends StatelessWidget {
  const UnassignedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return TabLoader<(List<AppealListItem>, List<User>)>(
      load: (context) async {
        final api = SessionScope.read(context).api;
        final page = await api.appeals.listAppeals(scope: AppealScope.unassigned, sort: 'created_asc', pageSize: 100);
        final users = await api.dictionaries.listUsers();
        return (page?.items ?? const <AppealListItem>[], users ?? const <User>[]);
      },
      builder: (context, data, set, _) {
        final (items, users) = data;
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text('Сюда попадают обращения без категории или из категории без ответственного.',
                style: theme.textTheme.bodySmall),
            if (items.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('Нераспределённых обращений нет.')),
            for (final item in items)
              Card(elevation: 0, color: ModusColors.of(context).card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                key: Key('unassigned-${item.id}'),
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    InkWell(
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: item.id))),
                      child: Text('${item.number} · ${item.summary ?? 'Без краткой сути'}', style: theme.textTheme.titleSmall),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        item.category != null ? 'Категория: ${item.category!.name} — без ответственного' : 'Категория не указана',
                        'подано ${formatDateTime(item.createdAt)}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: Key('assign-${item.id}'),
                      onPressed: () async {
                        final done = await openSheet<Appeal>(context, AssignForm(item: item, users: users));
                        if (done != null) set(([for (final x in items) if (x.id != item.id) x], users));
                      },
                      child: const Text('Назначить ответственного'),
                    ),
                  ]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AssignForm extends StatefulWidget {
  const AssignForm({super.key, required this.item, required this.users});

  final AppealListItem item;
  final List<User> users;

  @override
  State<AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<AssignForm> with FormRunner {
  int? _assigneeId;
  final _reason = TextEditingController(text: 'Распределено администратором');
  String? _local;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final local = _assigneeId == null
        ? 'Выберите ответственного.'
        : _reason.text.trim().isEmpty
            ? 'Укажите причину — она попадёт в историю обращения.'
            : null;
    setState(() => _local = local);
    if (local != null) return;
    final api = SessionScope.read(context).api.appealActions;
    run(() => api.reassignAppeal(
        widget.item.id, ReassignAppealRequest(assigneeId: _assigneeId!, reason: _reason.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return SheetForm(
      title: 'Назначить: ${widget.item.number}',
      busy: busy,
      error: _local ?? error,
      submitLabel: 'Назначить',
      onSubmit: _submit,
      children: [
        PersonField(
          key: const Key('assign-user'),
          label: 'Ответственный',
          users: assignable(widget.users),
          value: _assigneeId,
          noneLabel: 'Выберите сотрудника',
          onChanged: (v) => setState(() => _assigneeId = v),
        ),
        TextField(
          key: const Key('assign-reason'),
          controller: _reason,
          decoration: const InputDecoration(labelText: 'Причина — попадёт в историю', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
