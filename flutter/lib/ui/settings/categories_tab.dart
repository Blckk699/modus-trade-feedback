import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../app.dart';
import 'shared.dart';

typedef _Data = (List<Category>, List<Department>, List<User>);

/// Категории с ответственным и заместителем: по ним обращения распределяются сами (история 67).
class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return TabLoader<_Data>(
      load: (context) async {
        final api = SessionScope.read(context).api.dictionaries;
        return (
          (await api.listCategories(includeInactive: true)) ?? const <Category>[],
          (await api.listDepartments()) ?? const <Department>[],
          (await api.listUsers()) ?? const <User>[],
        );
      },
      builder: (context, data, set, _) {
        final (categories, departments, users) = data;
        Future<void> edit([Category? c]) async {
          final saved = await openSheet<Category>(
              context, CategoryForm(category: c, departments: departments, users: users));
          if (saved != null) set(([for (final x in categories) if (x.id != saved.id) x, saved], departments, users));
        }

        final sorted = [...categories]
          ..sort((a, b) => a.isActive != b.isActive ? (a.isActive ? -1 : 1) : a.name.compareTo(b.name));
        final scheme = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(
              'Новое обращение категории получает ответственный, а если он отсутствует — заместитель. '
              'Уже назначенные обращения при изменении не переназначаются.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('category-add'),
                onPressed: () => edit(),
                icon: const Icon(Icons.add),
                label: const Text('Добавить категорию'),
              ),
            ),
            for (final c in sorted)
              ListTile(
                key: Key('category-${c.id}'),
                contentPadding: EdgeInsets.zero,
                isThreeLine: true,
                title: Text(c.isActive ? c.name : '${c.name} · не используется',
                    style: c.isActive ? null : TextStyle(color: scheme.outline)),
                subtitle: Text.rich(TextSpan(children: [
                  TextSpan(text: '${c.department.name}\n'),
                  TextSpan(
                    text: 'Ответственный: ${c.responsible?.fullName ?? 'не назначен — обращения уйдут в очередь администратора'}',
                    style: c.responsible == null ? TextStyle(color: scheme.error) : null,
                  ),
                  TextSpan(text: ' · Заместитель: ${c.deputy?.fullName ?? 'нет'}'),
                ])),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => edit(c),
              ),
          ],
        );
      },
    );
  }
}

class CategoryForm extends StatefulWidget {
  const CategoryForm({super.key, this.category, required this.departments, required this.users});

  final Category? category;
  final List<Department> departments;
  final List<User> users;

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> with FormRunner {
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late int? _departmentId = widget.category?.department.id;
  late int? _responsibleId = widget.category?.responsible?.id;
  late int? _deputyId = widget.category?.deputy?.id;
  late bool _active = widget.category?.isActive ?? true;
  Map<String, String> _local = const {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final local = <String, String>{
      if (_name.text.trim().isEmpty) 'name': 'Укажите название.',
      if (_departmentId == null) 'department_id': 'Выберите подразделение.',
      if (_responsibleId != null && _responsibleId == _deputyId) 'deputy_id': 'Заместитель должен отличаться от ответственного.',
    };
    setState(() => _local = local);
    if (local.isNotEmpty) return;
    final api = SessionScope.read(context).api.admin;
    final c = widget.category;
    if (c == null) {
      run(() => api.adminCreateCategory(CategoryWrite(
            name: _name.text.trim(),
            departmentId: _departmentId!,
            responsibleId: _responsibleId,
            deputyId: _deputyId,
          )));
      return;
    }
    final body = changes({
      'name': c.name,
      'department_id': c.department.id,
      'responsible_id': c.responsible?.id,
      'deputy_id': c.deputy?.id,
      'is_active': c.isActive,
    }, {
      'name': _name.text.trim(),
      'department_id': _departmentId,
      'responsible_id': _responsibleId,
      'deputy_id': _deputyId,
      'is_active': _active,
    });
    if (body.isEmpty) {
      Navigator.pop(context, c);
      return;
    }
    run(() => api.adminUpdateCategory(c.id, CategoryPatch(body)));
  }

  String? _err(String f) => _local[f] ?? fieldErrors[f];

  @override
  Widget build(BuildContext context) {
    final people = assignable(widget.users);
    final departments = [...widget.departments]..sort((a, b) => a.name.compareTo(b.name));
    return SheetForm(
      title: widget.category?.name ?? 'Новая категория',
      busy: busy,
      error: error,
      submitLabel: widget.category == null ? 'Добавить' : 'Сохранить',
      onSubmit: _submit,
      children: [
        TextField(
          key: const Key('category-name'),
          controller: _name,
          decoration: InputDecoration(labelText: 'Название', errorText: _err('name'), border: const OutlineInputBorder()),
        ),
        DropdownButtonFormField<int?>(
          key: const Key('category-department'),
          initialValue: _departmentId,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: 'Подразделение', errorText: _err('department_id'), border: const OutlineInputBorder()),
          items: [for (final d in departments) DropdownMenuItem<int?>(value: d.id, child: Text(d.name))],
          onChanged: (v) => setState(() => _departmentId = v),
        ),
        PersonField(
          key: const Key('category-responsible'),
          label: 'Ответственный',
          users: people,
          value: _responsibleId,
          noneLabel: 'Не назначен',
          errorText: _err('responsible_id'),
          onChanged: (v) => setState(() => _responsibleId = v),
        ),
        PersonField(
          key: const Key('category-deputy'),
          label: 'Заместитель',
          users: people,
          value: _deputyId,
          noneLabel: 'Нет',
          errorText: _err('deputy_id'),
          onChanged: (v) => setState(() => _deputyId = v),
        ),
        if (widget.category != null)
          SwitchListTile(
            key: const Key('category-active'),
            contentPadding: EdgeInsets.zero,
            value: _active,
            title: const Text('Используется'),
            subtitle: const Text('Неиспользуемую категорию нельзя выбрать в новых обращениях'),
            onChanged: (v) => setState(() => _active = v),
          ),
      ],
    );
  }
}
