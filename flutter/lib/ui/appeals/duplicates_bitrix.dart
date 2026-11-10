import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import 'badges.dart';

/// «человек / человека / человек» для числа.
String plural(int n, (String, String, String) forms) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return forms.$1;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return forms.$2;
  return forms.$3;
}

/// Подсказки о похожих обращениях (истории 34–36). Бэкенд сам решает, кому их показывать
/// (автору — пустой список) и можно ли склеить сейчас (`can_merge`).
class DuplicatesSection extends StatefulWidget {
  const DuplicatesSection({super.key, required this.appeal, required this.onMerged, required this.onOpen});

  final Appeal appeal;

  /// После склейки карточку перечитываем: повтор становится «Закрыто» со ссылкой на основное.
  final Future<void> Function() onMerged;
  final ValueChanged<int> onOpen;

  @override
  State<DuplicatesSection> createState() => _DuplicatesSectionState();
}

class _DuplicatesSectionState extends State<DuplicatesSection> {
  List<DuplicateSuggestion>? _items;
  AppError? _loadError;
  int? _busy;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await SessionScope.read(context).api.duplicates.listSimilar(widget.appeal.id);
      if (mounted) setState(() => _items = items ?? const []);
    } catch (e) {
      if (mounted) setState(() => _loadError = AppError.from(e));
    }
  }

  Future<void> _merge(DuplicateSuggestion s) async {
    setState(() {
      _busy = s.id;
      _error = null;
    });
    try {
      await SessionScope.read(context)
          .api
          .duplicates
          .mergeAppeal(widget.appeal.id, MergeAppealRequest(mainAppealId: s.similarAppeal.id));
      await widget.onMerged();
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _dismiss(DuplicateSuggestion s) async {
    setState(() {
      _busy = s.id;
      _error = null;
    });
    try {
      await SessionScope.read(context).api.duplicates.dismissSuggestion(s.id);
      if (mounted) setState(() => _items = _items?.where((x) => x.id != s.id).toList());
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError?.status == 403) return const SizedBox.shrink();
    final items = _items;
    if (_loadError == null && (items == null || items.isEmpty)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canMerge = widget.appeal.allowedActions.contains(AppealAction.merge);
    return Container(
      key: const Key('duplicates'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Похожие обращения', style: theme.textTheme.titleMedium),
        if (_loadError != null) Text(_loadError!.message, style: TextStyle(color: scheme.error)),
        for (final s in items ?? const <DuplicateSuggestion>[])
          Padding(
            key: Key('suggestion-${s.id}'),
            padding: const EdgeInsets.only(top: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              InkWell(
                onTap: () => widget.onOpen(s.similarAppeal.id),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${s.similarAppeal.number} ', style: theme.textTheme.titleSmall),
                  TextSpan(
                    text: s.similarAppeal.summary ?? 'Без краткой сути',
                    style: TextStyle(color: scheme.primary, decoration: TextDecoration.underline),
                  ),
                ])),
              ),
              const SizedBox(height: 4),
              StatusBadge(s.similarAppeal.status),
              const SizedBox(height: 4),
              Text(s.explanation, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (canMerge && s.canMerge)
                  FilledButton(
                    key: Key('merge-${s.id}'),
                    onPressed: _busy != null ? null : () => _merge(s),
                    child: Text('Присоединить к ${s.similarAppeal.number}'),
                  ),
                OutlinedButton(
                  key: Key('dismiss-${s.id}'),
                  onPressed: _busy != null ? null : () => _dismiss(s),
                  child: const Text('Это другое'),
                ),
              ]),
            ]),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
      ]),
    );
  }
}

/// Задача в Битрикс24 (история 39): кнопка по `allowed_actions`, после создания — ссылка на задачу.
class BitrixSection extends StatefulWidget {
  const BitrixSection({super.key, required this.appeal, required this.onUpdated});

  final Appeal appeal;
  final ValueChanged<Appeal> onUpdated;

  @override
  State<BitrixSection> createState() => _BitrixSectionState();
}

class _BitrixSectionState extends State<BitrixSection> {
  bool _busy = false;
  String? _error;

  /// Сгенерированная модель отдаёт `bitrix_task` сырым объектом (nullable рядом с allOf).
  BitrixTask? get _task => BitrixTask.fromJson(widget.appeal.bitrixTask);

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final task = await SessionScope.read(context).api.bitrix.createBitrixTask(widget.appeal.id);
      if (task == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      // Ответ — сама задача; подставляем её в обращение, как в вебе.
      widget.onUpdated(widget.appeal..bitrixTask = task.toJson());
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(BitrixTask task) async {
    final ok = await launchUrl(Uri.parse(task.url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final canCreate = widget.appeal.allowedActions.contains(AppealAction.createBitrixTask);
    if (task == null && !canCreate) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Битрикс24', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (task != null)
          TextButton.icon(
            key: const Key('bitrix-link'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => _open(task),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text('Задача №${task.taskId} в Битрикс24'),
          )
        else ...[
          OutlinedButton.icon(
            key: const Key('bitrix-create'),
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.add_task),
            label: Text(_busy ? 'Создаём…' : 'Создать задачу в Битрикс24'),
          ),
          if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ]),
    );
  }
}
