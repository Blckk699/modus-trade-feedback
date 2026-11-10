import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import 'shared.dart';

const _priorities = [Priority.high, Priority.medium, Priority.low];

/// Сроки первого ответа по приоритетам (история 69) и время утренней сводки.
class DeadlinesTab extends StatelessWidget {
  const DeadlinesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return TabLoader<(List<DeadlineRule>, SystemSettings)>(
      load: (context) async {
        final api = SessionScope.read(context).api.admin;
        final rules = await api.adminGetDeadlineRules();
        final settings = await api.adminGetSettings();
        if (settings == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
        return (rules ?? const <DeadlineRule>[], settings);
      },
      builder: (context, data, set, _) => _DeadlinesForm(
        key: ValueKey(data),
        rules: data.$1,
        settings: data.$2,
        onSaved: set,
      ),
    );
  }
}

class _DeadlinesForm extends StatefulWidget {
  const _DeadlinesForm({super.key, required this.rules, required this.settings, required this.onSaved});

  final List<DeadlineRule> rules;
  final SystemSettings settings;
  final ValueChanged<(List<DeadlineRule>, SystemSettings)> onSaved;

  @override
  State<_DeadlinesForm> createState() => _DeadlinesFormState();
}

class _DeadlinesFormState extends State<_DeadlinesForm> {
  late final Map<Priority, TextEditingController> _days = {
    for (final p in _priorities)
      if (widget.rules.any((r) => r.priority == p))
        p: TextEditingController(text: '${widget.rules.firstWhere((r) => r.priority == p).businessDays}'),
  };
  late String _digestTime = widget.settings.digestTime;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _days.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _valid(String v) {
    final n = int.tryParse(v.trim());
    return n != null && n >= 1 && n <= 30 && RegExp(r'^\d+$').hasMatch(v.trim());
  }

  Future<void> _pickTime() async {
    final parts = _digestTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0),
      helpText: 'Утренняя сводка',
    );
    if (picked != null) {
      setState(() => _digestTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_days.values.any((c) => !_valid(c.text))) {
      setState(() => _error = 'Срок — целое число рабочих дней от 1 до 30.');
      return;
    }
    final api = SessionScope.read(context).api.admin;
    setState(() => _busy = true);
    try {
      final rules = await api.adminUpdateDeadlineRules([
        for (final e in _days.entries) DeadlineRule(priority: e.key, businessDays: int.parse(e.value.text.trim())),
      ]);
      final settings = _digestTime != widget.settings.digestTime
          ? await api.adminUpdateSettings(AdminUpdateSettingsRequest(digestTime: _digestTime))
          : widget.settings;
      if (rules == null || settings == null) {
        throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(key: Key('deadlines-saved'), content: Text('Сроки сохранены.')));
      }
      widget.onSaved((rules, settings));
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Text(
          'Срок первого ответа — в рабочих днях. Новые сроки применяются к новым обращениям и к переназначениям '
          'после сохранения.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final e in _days.entries) ...[
          TextField(
            key: Key('deadline-${e.key.toJson()}'),
            controller: e.value,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Приоритет «${session.priorityLabel(e.key)}»',
              suffixText: 'раб. дн.',
              border: const OutlineInputBorder(),
              errorText: _valid(e.value.text) ? null : 'От 1 до 30',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
        ],
        ListTile(
          key: const Key('digest-time'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Утренняя сводка'),
          subtitle: Text('Время отправки в Telegram, UTC${widget.settings.timezone}'),
          trailing: Text(_digestTime, style: theme.textTheme.titleMedium),
          onTap: _busy ? null : _pickTime,
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('deadlines-save'),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Сохраняем…' : 'Сохранить'),
        ),
      ],
    );
  }
}
