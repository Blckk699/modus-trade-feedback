import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../web/web_ui.dart';
import '../../format.dart';
import '../appeals/appeal_screen.dart';
import 'meetings_screen.dart' show MeetingStatusBadge;
import '../../theme/modus_theme.dart';

/// Совещание: ход обработки, черновики с цитатами, расшифровка (истории 49–51).
class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key, required this.meetingId, this.pollInterval = const Duration(seconds: 3)});

  final int meetingId;
  final Duration pollInterval;

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  Meeting? _m;
  AppError? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final m = await SessionScope.read(context).api.meetings.getMeeting(widget.meetingId);
      if (m == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (!mounted) return;
      setState(() {
        _m = m;
        _error = null;
      });
      _schedule();
    } catch (e) {
      // Сбой одного опроса не ломает экран: оставляем последние данные и пробуем на следующем тике.
      if (!mounted) return;
      if (!quiet || _m == null) setState(() => _error = AppError.from(e));
      _schedule();
    }
  }

  /// Пока идёт обработка — опрашиваем `GET /meetings/{id}`, как велит контракт.
  void _schedule() {
    _poll?.cancel();
    if (_m?.status == MeetingStatus.processing) {
      _poll = Timer(widget.pollInterval, () => _load(quiet: true));
    }
  }

  void _updateDraft(MeetingDraft d) {
    final m = _m!;
    setState(() => m.drafts = [for (final x in m.drafts) x.id == d.id ? d : x]);
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(m?.title ?? 'Совещание')),
      body: m == null
          ? (_error == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!.status == 404 ? 'Совещание не найдено.' : _error!.message, textAlign: TextAlign.center),
                      if (_error!.status != 404)
                        TextButton(onPressed: _load, child: const Text('Повторить')),
                    ]),
                  ),
                ))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Row(children: [
                    MeetingStatusBadge(m.status),
                    const SizedBox(width: 8),
                    Text('Загружено ${formatDateTime(m.createdAt)}', style: theme.textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 12),
                  if (m.status == MeetingStatus.processing)
                    const _Notice(
                      key: Key('meeting-processing'),
                      progress: true,
                      text: 'Расшифровываем запись и ищем вопросы. Это займёт пару минут — экран обновится сам.',
                    ),
                  if (m.status == MeetingStatus.failed)
                    _Notice(
                      key: const Key('meeting-failed'),
                      danger: true,
                      text: '${m.error ?? 'Не удалось обработать запись.'} Попробуйте загрузить её ещё раз.',
                    ),
                  if (m.status == MeetingStatus.ready) ...[
                    Text(_readySummary(m), key: const Key('meeting-summary'), style: theme.textTheme.bodyMedium),
                    for (final d in m.drafts)
                      DraftCard(key: ValueKey('draft-${d.id}-${d.status.toJson()}'), draft: d, onUpdated: _updateDraft),
                    if (m.transcript != null)
                      ExpansionTile(
                        key: const Key('meeting-transcript'),
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Расшифровка'),
                        children: [SelectableText(m.transcript!)],
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  static String _readySummary(Meeting m) {
    final pending = m.drafts.where((d) => d.status == MeetingDraftStatus.pending).length;
    if (m.drafts.isEmpty) return 'В записи не нашлось вопросов для обращений.';
    if (pending > 0) {
      return 'Черновиков: ${m.drafts.length}. Ждут решения: $pending. '
          'Проверьте каждый: подтвердите, поправьте или отбросьте.';
    }
    return 'Все черновики разобраны (${m.drafts.length}).';
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.text, this.progress = false, this.danger = false});

  final String text;
  final bool progress;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ModusRadius.lg),
      ),
      child: Row(children: [
        if (progress) ...[
          const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
        ],
        Expanded(child: Text(text, style: TextStyle(color: danger ? scheme.onErrorContainer : null))),
      ]),
    );
  }
}

/// Поля черновика для правки. `author_id: null` — автор загрузивший запись.
class _Form {
  _Form.from(MeetingDraft d)
      : type = d.type,
        categoryId = d.category?.id,
        priority = d.priority,
        summary = TextEditingController(text: d.summary),
        text = TextEditingController(text: d.text),
        solution = TextEditingController(text: d.proposedSolution ?? ''),
        authorId = d.author?.id;

  AppealType type;
  int? categoryId;
  Priority priority;
  final TextEditingController summary;
  final TextEditingController text;
  final TextEditingController solution;
  int? authorId;

  bool get valid => summary.text.trim().isNotEmpty && text.text.trim().isNotEmpty;

  MeetingDraftUpdate toUpdate() => MeetingDraftUpdate(
        type: type,
        categoryId: categoryId,
        priority: priority,
        summary: summary.text.trim(),
        text: text.text.trim(),
        proposedSolution: solution.text.trim().isEmpty ? null : solution.text.trim(),
        authorId: authorId,
      );

  void dispose() {
    summary.dispose();
    text.dispose();
    solution.dispose();
  }
}

class DraftCard extends StatefulWidget {
  const DraftCard({super.key, required this.draft, required this.onUpdated});

  final MeetingDraft draft;
  final ValueChanged<MeetingDraft> onUpdated;

  @override
  State<DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<DraftCard> {
  late _Form _form = _Form.from(widget.draft);
  bool _editing = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  MeetingDraft get d => widget.draft;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset(MeetingDraft next) {
    _form.dispose();
    _form = _Form.from(next);
  }

  Future<void> _save() => _run(() async {
        final next = await SessionScope.read(context)
            .api
            .meetings
            .updateMeetingDraft(d.meetingId, d.id, _form.toUpdate());
        if (next == null) return;
        widget.onUpdated(next);
        setState(() {
          _reset(next);
          _editing = false;
        });
      });

  /// Подтверждение сразу передаёт текущие правки (контракт это разрешает) и создаёт обращение.
  Future<void> _confirm() => _run(() async {
        final appeal = await SessionScope.read(context)
            .api
            .meetings
            .confirmMeetingDraft(d.meetingId, d.id, meetingDraftUpdate: _form.toUpdate());
        if (appeal == null) return;
        widget.onUpdated(d
          ..status = MeetingDraftStatus.confirmed
          ..summary = appeal.summary ?? d.summary
          ..appeal = AppealRef(
            id: appeal.id,
            number: appeal.number,
            summary: appeal.summary,
            status: appeal.status,
            type: appeal.type,
          ));
      });

  Future<void> _discard() => _run(() async {
        final next = await SessionScope.read(context).api.meetings.discardMeetingDraft(d.meetingId, d.id);
        if (next != null) widget.onUpdated(next);
      });

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final pending = d.status == MeetingDraftStatus.pending;
    return Card(elevation: 0, color: ModusColors.of(context).card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text(
                '${session.typeLabel(_editing ? _form.type : d.type)} · ${d.category?.name ?? 'Без категории'} · '
                '${session.priorityLabel(d.priority)}',
                style: muted,
              ),
            ),
            if (d.status == MeetingDraftStatus.confirmed)
              Text('Подтверждён', style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary)),
            if (d.status == MeetingDraftStatus.discarded) Text('Отброшен', style: theme.textTheme.labelMedium),
          ]),
          const SizedBox(height: 8),
          Container(
            key: Key('quote-${d.id}'),
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: scheme.outlineVariant, width: 3))),
            child: Text('«${d.quote}»', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 8),
          if (!_editing) ...[
            Text(d.summary, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(d.text),
            if (d.proposedSolution != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Предлагаемое решение: ${d.proposedSolution}', style: muted),
              ),
            const SizedBox(height: 4),
            Text('Автор: ${d.author?.fullName ?? 'вы (загрузивший запись)'}', style: muted),
          ],
          if (_editing && pending) _DraftForm(form: _form, onChanged: () => setState(() {})),
          if (d.status == MeetingDraftStatus.confirmed && d.appeal != null)
            TextButton(
              key: Key('draft-appeal-${d.id}'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: d.appeal!.id))),
              child: Text('Создано обращение ${d.appeal!.number}'),
            ),
          // Одно главное действие; правка и отказ — под «⋯».
          if (pending && !_editing) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: WebButton(
                  key: Key('draft-confirm-${d.id}'),
                  label: 'Подтвердить',
                  busy: _busy,
                  onPressed: _form.valid ? _confirm : null,
                ),
              ),
              const SizedBox(width: 8),
              MoreButton(
                key: Key('draft-more-${d.id}'),
                onTap: _busy
                    ? null
                    : () async {
                        final i = await showActionSheet(context, [
                          SheetAction(key: Key('draft-edit-${d.id}'), label: 'Поправить', icon: LucideIcons.pencil),
                          SheetAction(
                              key: Key('draft-discard-${d.id}'), label: 'Отбросить', icon: LucideIcons.trash2, danger: true),
                        ]);
                        if (i == 0) setState(() => _editing = true);
                        if (i == 1) await _discard();
                      },
              ),
            ]),
          ],
          if (pending && _editing) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: WebButton(
                  kind: WebButtonKind.soft,
                  label: 'Отменить',
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _reset(d);
                            _editing = false;
                          }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: WebButton(
                  key: Key('draft-save-${d.id}'),
                  label: 'Сохранить',
                  busy: _busy,
                  onPressed: _form.valid ? _save : null,
                ),
              ),
            ]),
          ],
          if (_error != null) Text(_error!, style: TextStyle(color: scheme.error)),
        ]),
      ),
    );
  }
}

class _DraftForm extends StatefulWidget {
  const _DraftForm({required this.form, required this.onChanged});

  final _Form form;
  final VoidCallback onChanged;

  @override
  State<_DraftForm> createState() => _DraftFormState();
}

class _DraftFormState extends State<_DraftForm> {
  late final Future<List<Category>> _categories;
  late final Future<List<User>> _users;

  @override
  void initState() {
    super.initState();
    final api = SessionScope.read(context).api.dictionaries;
    _categories = api.listCategories().then((v) => [for (final c in v ?? const <Category>[]) if (c.isActive) c]);
    _users = api.listUsers().then((v) => [for (final u in v ?? const <User>[]) if (!u.isDisabled) u]);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.form;
    final session = SessionScope.of(context);
    void changed(VoidCallback fn) {
      setState(fn);
      widget.onChanged();
    }

    const gap = SizedBox(height: 12);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<AppealType>(
        key: const Key('draft-type'),
        initialValue: f.type,
        decoration: const InputDecoration(labelText: 'Тип', border: OutlineInputBorder()),
        items: [for (final t in AppealType.values) DropdownMenuItem(value: t, child: Text(session.typeLabel(t)))],
        onChanged: (v) => changed(() => f.type = v ?? f.type),
      ),
      gap,
      FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, s) => DropdownButtonFormField<int?>(
          // Пока список грузится, выбранного пункта ещё нет — без значения, затем поле пересоздаётся.
          key: Key('draft-category-${s.hasData}'),
          initialValue: s.hasData ? f.categoryId : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Не указана')),
            for (final c in s.data ?? const <Category>[])
              DropdownMenuItem<int?>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => changed(() => f.categoryId = v),
        ),
      ),
      gap,
      DropdownButtonFormField<Priority>(
        key: const Key('draft-priority'),
        initialValue: f.priority,
        decoration: const InputDecoration(labelText: 'Приоритет', border: OutlineInputBorder()),
        items: [for (final p in Priority.values) DropdownMenuItem(value: p, child: Text(session.priorityLabel(p)))],
        onChanged: (v) => changed(() => f.priority = v ?? f.priority),
      ),
      gap,
      FutureBuilder<List<User>>(
        future: _users,
        builder: (context, s) => DropdownButtonFormField<int?>(
          // Пока список грузится, выбранного пункта ещё нет — без значения, затем поле пересоздаётся.
          key: Key('draft-author-${s.hasData}'),
          initialValue: s.hasData ? f.authorId : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Автор', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Я (загрузивший)')),
            for (final u in s.data ?? const <User>[])
              DropdownMenuItem<int?>(
                value: u.id,
                child: Text([u.fullName, if (u.department != null) '— ${u.department!.name}'].join(' '),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => changed(() => f.authorId = v),
        ),
      ),
      gap,
      TextField(
        key: const Key('draft-summary'),
        controller: f.summary,
        decoration: const InputDecoration(labelText: 'Краткая суть', border: OutlineInputBorder()),
        onChanged: (_) => widget.onChanged(),
      ),
      gap,
      TextField(
        key: const Key('draft-text'),
        controller: f.text,
        minLines: 3,
        maxLines: 8,
        decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
        onChanged: (_) => widget.onChanged(),
      ),
      gap,
      TextField(
        key: const Key('draft-solution'),
        controller: f.solution,
        minLines: 2,
        maxLines: 6,
        decoration: const InputDecoration(
            labelText: 'Предлагаемое решение', helperText: 'Необязательно', border: OutlineInputBorder()),
      ),
    ]);
  }
}
