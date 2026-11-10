import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';

/// Только изменённые поля — PATCH не трогает остальное (как `changes` в вебе).
/// Сгенерированные `*Update.toJson` отправляют все поля, а отсутствующие — как `null`,
/// что для PATCH означало бы «очистить». Поэтому тело собираем сами.
Map<String, dynamic> changes(Map<String, dynamic> before, Map<String, dynamic> after) => {
      for (final e in after.entries)
        if (before[e.key] != e.value) e.key: e.value,
    };

class UserPatch extends UserUpdate {
  UserPatch(this.body);
  final Map<String, dynamic> body;
  @override
  Map<String, dynamic> toJson() => body;
}

class DepartmentPatch extends DepartmentUpdate {
  DepartmentPatch(this.body);
  final Map<String, dynamic> body;
  @override
  Map<String, dynamic> toJson() => body;
}

class CategoryPatch extends CategoryUpdate {
  CategoryPatch(this.body);
  final Map<String, dynamic> body;
  @override
  Map<String, dynamic> toJson() => body;
}

/// Кого можно назначить ответственным: действующие сотрудники, кроме администратора.
List<User> assignable(List<User> users) =>
    [for (final u in users) if (!u.isDisabled && u.role != Role.admin) u]..sort(byName);

int byName(User a, User b) => a.fullName.compareTo(b.fullName);

/// Выбор сотрудника из списка; `null` — «нет».
class PersonField extends StatelessWidget {
  const PersonField({
    super.key,
    required this.label,
    required this.users,
    required this.value,
    required this.noneLabel,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final List<User> users;
  final int? value;
  final String noneLabel;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    // Текущий человек мог стать недоступным (отключён) — тогда показываем его отдельным пунктом.
    final known = value == null || users.any((u) => u.id == value);
    return DropdownButtonFormField<int?>(
      initialValue: known ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: errorText),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(noneLabel)),
        for (final u in users)
          DropdownMenuItem<int?>(
            value: u.id,
            child: Text([u.fullName, if (u.department != null) '— ${u.department!.name}'].join(' '),
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Лист с формой: заголовок, поля, ошибка, «Сохранить» / «Отмена».
class SheetForm extends StatelessWidget {
  const SheetForm({
    super.key,
    required this.title,
    required this.children,
    required this.busy,
    required this.onSubmit,
    required this.submitLabel,
    this.error,
  });

  final String title;
  final List<Widget> children;
  final bool busy;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final c in children) ...[c, const SizedBox(height: 12)],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(error!, key: const Key('form-error'), style: TextStyle(color: theme.colorScheme.error)),
              ),
            Row(children: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Отмена')),
              const Spacer(),
              FilledButton(
                key: const Key('form-submit'),
                onPressed: busy ? null : onSubmit,
                child: Text(busy ? 'Сохраняем…' : submitLabel),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Состояние отправки формы: занято, общая ошибка, ошибки полей из 422.
mixin FormRunner<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;
  Map<String, String> fieldErrors = const {};

  /// Выполняет запрос; при успехе закрывает лист с результатом.
  Future<void> run<R>(Future<R?> Function() request) async {
    setState(() {
      busy = true;
      error = null;
      fieldErrors = const {};
    });
    try {
      final result = await request();
      if (result == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      final err = AppError.from(e);
      if (mounted) {
        setState(() {
          error = err.message;
          fieldErrors = err.fields;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

/// Загрузка вкладки: индикатор, ошибка с повтором, обновление свайпом.
class TabLoader<D> extends StatefulWidget {
  const TabLoader({super.key, required this.load, required this.builder});

  final Future<D> Function(BuildContext context) load;
  final Widget Function(BuildContext context, D data, void Function(D) set, Future<void> Function() reload) builder;

  @override
  State<TabLoader<D>> createState() => _TabLoaderState<D>();
}

class _TabLoaderState<D> extends State<TabLoader<D>> with AutomaticKeepAliveClientMixin {
  D? _data;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final data = await widget.load(context);
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _data;
    if (data == null) {
      if (_error == null) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextButton(onPressed: _reload, child: const Text('Повторить')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: widget.builder(context, data, (d) => setState(() => _data = d), _reload),
    );
  }
}

Future<R?> openSheet<R>(BuildContext context, Widget form) => showModalBottomSheet<R>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => form,
    );
