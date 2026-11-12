import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import 'badges.dart';
import '../web/web_ui.dart';
import '../../theme/modus_theme.dart';

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
        color: ModusColors.of(context).infoBg,
        borderRadius: BorderRadius.circular(Web.rTile),
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
              Row(children: [
                Expanded(
                  child: WebButton(
                    key: Key('dismiss-${s.id}'),
                    kind: WebButtonKind.soft,
                    tint: ModusColors.of(context).surface,
                    label: 'Это другое',
                    onPressed: _busy != null ? null : () => _dismiss(s),
                  ),
                ),
                if (canMerge && s.canMerge) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: WebButton(
                      key: Key('merge-${s.id}'),
                      label: 'Присоединить',
                      onPressed: _busy != null ? null : () => _merge(s),
                    ),
                  ),
                ],
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
  /// Сгенерированная модель отдаёт `bitrix_task` сырым объектом (nullable рядом с allOf).
  BitrixTask? get _task => BitrixTask.fromJson(widget.appeal.bitrixTask);

  Future<void> _open(BitrixTask task) async {
    final ok = await launchUrl(Uri.parse(task.url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Создать задачу — в «Ещё» у действий карточки; здесь только ссылка на созданную.
    final task = _task;
    if (task == null) return const SizedBox.shrink();
    final c = ModusColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        key: const Key('bitrix-link'),
        borderRadius: BorderRadius.circular(Web.rTile),
        onTap: () => _open(task),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(Web.rTile)),
          child: Row(children: [
            Icon(LucideIcons.listChecks, size: 20, color: c.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Задача №${task.taskId} в Битрикс24',
                  style: TextStyle(color: c.heading, fontWeight: FontWeight.w600)),
            ),
            Icon(LucideIcons.externalLink, size: 18, color: c.faint),
          ]),
        ),
      ),
    );
  }
}
