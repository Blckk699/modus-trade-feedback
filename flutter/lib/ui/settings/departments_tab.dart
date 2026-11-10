import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../app.dart';
import 'shared.dart';

typedef _Data = (List<Department>, List<User>);

/// Подразделения и их руководители: по ним идёт эскалация (история 66).
class DepartmentsTab extends StatelessWidget {
  const DepartmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return TabLoader<_Data>(
      load: (context) async {
        final api = SessionScope.read(context).api.dictionaries;
        return ((await api.listDepartments()) ?? const <Department>[], (await api.listUsers()) ?? const <User>[]);
      },
      builder: (context, data, set, _) {
        final (departments, users) = data;
        Future<void> edit([Department? d]) async {
          final saved = await openSheet<Department>(context, DepartmentForm(department: d, users: users));
          if (saved != null) set(([for (final x in departments) if (x.id != saved.id) x, saved], users));
        }

        final sorted = [...departments]..sort((a, b) => a.name.compareTo(b.name));
        final scheme = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(
              'Руководитель получает эскалацию, если ответственный не ответил в срок, и утреннюю сводку по подразделению.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('department-add'),
                onPressed: () => edit(),
                icon: const Icon(Icons.add),
                label: const Text('Добавить подразделение'),
              ),
            ),
            for (final d in sorted)
              ListTile(
                key: Key('department-${d.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(d.name),
                subtitle: Text(
                  d.head != null ? 'Руководитель: ${d.head!.fullName}' : 'Руководитель не назначен',
                  style: d.head == null ? TextStyle(color: scheme.error) : null,
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => edit(d),
              ),
          ],
        );
      },
    );
  }
}

class DepartmentForm extends StatefulWidget {
  const DepartmentForm({super.key, this.department, required this.users});

  final Department? department;
  final List<User> users;

  @override
  State<DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends State<DepartmentForm> with FormRunner {
  late final _name = TextEditingController(text: widget.department?.name ?? '');
  late int? _headId = widget.department?.head?.id;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Укажите название.');
      return;
    }
    setState(() => _nameError = null);
    final api = SessionScope.read(context).api.admin;
    final d = widget.department;
    if (d == null) {
      run(() => api.adminCreateDepartment(DepartmentWrite(name: _name.text.trim(), headId: _headId)));
      return;
    }
    final body = changes({'name': d.name, 'head_id': d.head?.id}, {'name': _name.text.trim(), 'head_id': _headId});
    if (body.isEmpty) {
      Navigator.pop(context, d);
      return;
    }
    run(() => api.adminUpdateDepartment(d.id, DepartmentPatch(body)));
  }

  @override
  Widget build(BuildContext context) {
    // Действующие сотрудники, кроме администратора; роль «руководитель» — первой.
    final candidates = assignable(widget.users)
      ..sort((a, b) => (b.role == Role.head ? 1 : 0) - (a.role == Role.head ? 1 : 0));
    return SheetForm(
      title: widget.department?.name ?? 'Новое подразделение',
      busy: busy,
      error: error,
      submitLabel: widget.department == null ? 'Добавить' : 'Сохранить',
      onSubmit: _submit,
      children: [
        TextField(
          key: const Key('department-name'),
          controller: _name,
          decoration: InputDecoration(
            labelText: 'Название',
            errorText: _nameError ?? fieldErrors['name'],
            border: const OutlineInputBorder(),
          ),
        ),
        PersonField(
          key: const Key('department-head'),
          label: 'Руководитель',
          users: candidates,
          value: _headId,
          noneLabel: 'Не назначен',
          errorText: fieldErrors['head_id'],
          onChanged: (v) => setState(() => _headId = v),
        ),
      ],
    );
  }
}
