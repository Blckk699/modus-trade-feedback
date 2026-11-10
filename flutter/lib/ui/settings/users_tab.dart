import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../app.dart';
import 'shared.dart';

const _roles = [Role.employee, Role.head, Role.owner, Role.admin];

typedef _UsersData = (List<User>, List<Department>);

/// Сотрудники: добавить по Telegram ID, роль, подразделение, отсутствие, отключение доступа
/// (истории 64, 65, 68).
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return TabLoader<_UsersData>(
      load: (context) async {
        final api = SessionScope.read(context).api.dictionaries;
        final users = await api.listUsers(includeDisabled: true);
        final departments = await api.listDepartments();
        return (users ?? const <User>[], departments ?? const <Department>[]);
      },
      builder: (context, data, set, _) {
        final (users, departments) = data;
        void replace(User u) => set(([for (final x in users) if (x.id != u.id) x, u], departments));
        Future<void> edit([User? user]) async {
          final saved = await openSheet<User>(context, UserForm(user: user, departments: departments));
          if (saved != null) replace(saved);
        }

        final needle = _q.trim().toLowerCase();
        final shown = [
          for (final u in users)
            if (needle.isEmpty || '${u.fullName} ${u.position ?? ''} ${u.telegramId ?? ''}'.toLowerCase().contains(needle)) u,
        ]..sort(byName);
        final session = SessionScope.of(context);
        final scheme = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('users-search'),
                  decoration: const InputDecoration(
                    hintText: 'Поиск по имени, должности, Telegram ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('user-add'),
                tooltip: 'Добавить сотрудника',
                onPressed: () => edit(),
                icon: const Icon(Icons.person_add_alt),
              ),
            ]),
            const SizedBox(height: 8),
            if (shown.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Никого не нашли.')),
            for (final u in shown)
              ListTile(
                key: Key('user-${u.id}'),
                contentPadding: EdgeInsets.zero,
                enabled: true,
                title: Text(u.fullName,
                    style: u.isDisabled ? TextStyle(color: scheme.outline, decoration: TextDecoration.lineThrough) : null),
                subtitle: Text([
                  [session.roleLabel(u.role), if (u.department != null) u.department!.name, if (u.position != null) u.position!]
                      .join(' · '),
                  'Telegram ID: ${u.telegramId ?? '—'}',
                  if (u.isAbsent) 'Отсутствует',
                  if (u.isDisabled) 'Доступ отключён',
                ].join('\n')),
                isThreeLine: true,
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => edit(u),
              ),
          ],
        );
      },
    );
  }
}

class UserForm extends StatefulWidget {
  const UserForm({super.key, this.user, required this.departments});

  final User? user;
  final List<Department> departments;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> with FormRunner {
  final _telegramId = TextEditingController();
  late final _fullName = TextEditingController(text: widget.user?.fullName ?? '');
  late final _position = TextEditingController(text: widget.user?.position ?? '');
  late Role _role = widget.user?.role ?? Role.employee;
  late int? _departmentId = widget.user?.department?.id;
  late bool _absent = widget.user?.isAbsent ?? false;
  late bool _disabled = widget.user?.isDisabled ?? false;
  Map<String, String> _local = const {};

  @override
  void dispose() {
    _telegramId.dispose();
    _fullName.dispose();
    _position.dispose();
    super.dispose();
  }

  void _submit() {
    final user = widget.user;
    final local = <String, String>{
      if (user == null && !RegExp(r'^\d{1,15}$').hasMatch(_telegramId.text.trim()))
        'telegram_id': 'Числовой Telegram ID, например 123456789.',
      if (_fullName.text.trim().isEmpty) 'full_name': 'Укажите имя и фамилию.',
    };
    setState(() => _local = local);
    if (local.isNotEmpty) return;
    final api = SessionScope.read(context).api.admin;
    final fields = <String, dynamic>{
      'full_name': _fullName.text.trim(),
      'position': _position.text.trim().isEmpty ? null : _position.text.trim(),
      'role': _role.toJson(),
      'department_id': _departmentId,
    };
    if (user == null) {
      run(() => api.adminCreateUser(UserCreate(
            telegramId: int.parse(_telegramId.text.trim()),
            fullName: fields['full_name'] as String,
            position: fields['position'] as String?,
            role: _role,
            departmentId: _departmentId,
          )));
      return;
    }
    final body = changes({
      'full_name': user.fullName,
      'position': user.position,
      'role': user.role.toJson(),
      'department_id': user.department?.id,
      'is_absent': user.isAbsent,
      'is_disabled': user.isDisabled,
    }, {
      ...fields,
      'is_absent': _absent,
      'is_disabled': _disabled,
    });
    if (body.isEmpty) {
      Navigator.pop(context, user);
      return;
    }
    run(() => api.adminUpdateUser(user.id, UserPatch(body)));
  }

  String? _err(String field) => _local[field] ?? fieldErrors[field];

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = widget.user;
    final departments = [...widget.departments]..sort((a, b) => a.name.compareTo(b.name));
    return SheetForm(
      title: user?.fullName ?? 'Новый сотрудник',
      busy: busy,
      error: error,
      submitLabel: user == null ? 'Добавить' : 'Сохранить',
      onSubmit: _submit,
      children: [
        if (user == null)
          TextField(
            key: const Key('user-telegram'),
            controller: _telegramId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Telegram ID',
              helperText: 'Числовой ID: сотрудник может узнать его у @userinfobot. По нему он войдёт в систему.',
              helperMaxLines: 3,
              errorText: _err('telegram_id'),
              border: const OutlineInputBorder(),
            ),
          ),
        TextField(
          key: const Key('user-name'),
          controller: _fullName,
          decoration: InputDecoration(
              labelText: 'Имя и фамилия', errorText: _err('full_name'), border: const OutlineInputBorder()),
        ),
        TextField(
          key: const Key('user-position'),
          controller: _position,
          decoration: const InputDecoration(labelText: 'Должность', border: OutlineInputBorder()),
        ),
        DropdownButtonFormField<Role>(
          key: const Key('user-role'),
          initialValue: _role,
          decoration: const InputDecoration(labelText: 'Роль', border: OutlineInputBorder()),
          items: [for (final r in _roles) DropdownMenuItem(value: r, child: Text(session.roleLabel(r)))],
          onChanged: (v) => setState(() => _role = v ?? _role),
        ),
        DropdownButtonFormField<int?>(
          key: const Key('user-department'),
          initialValue: _departmentId,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: 'Подразделение', errorText: _err('department_id'), border: const OutlineInputBorder()),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Без подразделения')),
            for (final d in departments) DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
          ],
          onChanged: (v) => setState(() => _departmentId = v),
        ),
        if (user != null) ...[
          SwitchListTile(
            key: const Key('user-absent'),
            contentPadding: EdgeInsets.zero,
            value: _absent,
            title: const Text('Отсутствует'),
            subtitle: const Text('Новые обращения его категорий получает заместитель'),
            onChanged: (v) => setState(() => _absent = v),
          ),
          SwitchListTile(
            key: const Key('user-disabled'),
            contentPadding: EdgeInsets.zero,
            value: _disabled,
            title: const Text('Отключить доступ'),
            subtitle: const Text('Вход запрещён, текущие сессии сбрасываются'),
            onChanged: (v) => setState(() => _disabled = v),
          ),
        ],
      ],
    );
  }
}
