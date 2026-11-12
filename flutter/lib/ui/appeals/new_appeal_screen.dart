import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/attachment_files.dart';
import '../../format.dart';
import 'appeal_screen.dart';
import '../../theme/modus_theme.dart';
import '../web/web_ui.dart';
import 'badges.dart';
import 'card_parts.dart' show FactsTile;

/// Выбор файлов вынесен, чтобы подменять его в тестах.
typedef FilesPicker = Future<List<PickedFile>> Function();

Future<List<PickedFile>> pickFilesFromDevice() async {
  final result = await FilePicker.platform.pickFiles(allowMultiple: true);
  return [
    for (final f in result?.files ?? const <PlatformFile>[])
      if (f.path != null) PickedFile(name: f.name, path: f.path!, size: f.size),
  ];
}

/// Подача через форму: тип, категория, приоритет, описание, предлагаемое решение, вложения.
/// Работает без AI-сервисов. Вложения загружаются после создания обращения.
class NewAppealScreen extends StatefulWidget {
  const NewAppealScreen({super.key, this.pickFiles = pickFilesFromDevice});

  final FilesPicker pickFiles;

  @override
  State<NewAppealScreen> createState() => _NewAppealScreenState();
}

class _FailedFile {
  const _FailedFile(this.name, this.message);
  final String name;
  final String message;
}

class _NewAppealScreenState extends State<NewAppealScreen> {
  AppealType _type = AppealType.problem;
  int? _categoryId;
  Priority _priority = Priority.medium;
  final _text = TextEditingController();
  final _solution = TextEditingController();
  final List<PickedFile> _files = [];

  late Future<List<Category>> _categories;
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  Appeal? _created;
  List<_FailedFile> _failed = const [];

  @override
  void initState() {
    super.initState();
    _categories = _loadCategories();
  }

  @override
  void dispose() {
    _text.dispose();
    _solution.dispose();
    super.dispose();
  }

  Future<List<Category>> _loadCategories() async {
    try {
      final all = await SessionScope.read(context).api.dictionaries.listCategories() ?? const [];
      return all.where((c) => c.isActive).toList();
    } catch (e) {
      throw AppError.from(e);
    }
  }

  Future<void> _addFiles() async {
    final picked = await widget.pickFiles();
    if (!mounted || picked.isEmpty) return;
    final tooLarge = picked.where((f) => f.size > maxAttachmentBytes).map((f) => f.name).toList();
    setState(() => _files.addAll(picked.where((f) => f.size <= maxAttachmentBytes)));
    if (tooLarge.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Больше 20 МБ, не добавлены: ${tooLarge.join(', ')}'),
      ));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_text.text.trim().isEmpty) {
      setState(() => _fieldErrors = {'text': 'Опишите проблему или предложение.'});
      return;
    }
    final api = SessionScope.read(context).api;
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      final Appeal? appeal;
      try {
        appeal = await api.appeals.createAppeal(AppealCreate(
          type: _type,
          categoryId: _categoryId,
          priority: _priority,
          text: _text.text.trim(),
          proposedSolution:
              _type == AppealType.praise || _solution.text.trim().isEmpty ? null : _solution.text.trim(),
          source_: AppealCreateSource_Enum.form,
        ));
      } catch (e) {
        throw AppError.from(e);
      }
      if (appeal == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      final failed = <_FailedFile>[];
      for (final file in _files) {
        try {
          await uploadAttachment(api, appeal.id, file);
        } on AppError catch (e) {
          failed.add(_FailedFile(file.name, e.message));
        }
      }
      if (mounted) {
        setState(() {
          _created = appeal;
          _failed = failed;
        });
      }
    } on AppError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _fieldErrors = e.fields;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _more = false;

  static const _hints = {
    AppealType.problem: 'Что-то мешает работать',
    AppealType.suggestion: 'Есть идея, как сделать лучше',
    AppealType.praise: 'Отметить хорошую работу',
  };

  static const _placeholders = {
    AppealType.problem: 'Что происходит, где и как часто',
    AppealType.suggestion: 'Что предлагаете изменить и что это даст',
    AppealType.praise: 'Что получилось хорошо и кого отметить',
  };

  Future<void> _pickCategory(List<Category> categories) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => _PickSheet(
        title: 'Категория',
        options: [(-1, 'Не знаю', 'Распределит администратор'), for (final c in categories) (c.id, c.name, null)],
        selected: _categoryId ?? -1,
      ),
    );
    if (picked != null) setState(() => _categoryId = picked == -1 ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    if (created != null) return _CreatedScreen(appeal: created, failed: _failed);
    final session = SessionScope.of(context);
    final dict = session.dictionaries;
    final c = ModusColors.of(context);
    final priorities = dict == null ? Priority.values : dict.priorities.map((p) => Priority.fromJson(p.code)!).toList();
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        body: WebScrollPage(
          over: 'Подача',
          title: 'Новое обращение',
          bottomPadding: 40,
          leading: ToolButton(icon: LucideIcons.x, tooltip: 'Закрыть', onTap: () => Navigator.of(context).maybePop()),
          children: [
            Text('Его получит ответственный за тему и ответит в срок.', style: TextStyle(color: c.muted, fontSize: 14.5)),
            const SizedBox(height: 18),
            // «О чём»: три карточки с подсказкой, как `.choice` в вебе.
            const WebLabel('О чём'),
            const SizedBox(height: 8),
            Column(
              key: const Key('field-type'),
              children: [
                for (final t in AppealType.values) ...[
                  if (t != AppealType.values.first) const SizedBox(height: 8),
                  _TypeChoice(
                    key: Key('type-${t.toJson()}'),
                    type: t,
                    label: session.typeLabel(t),
                    hint: _hints[t] ?? '',
                    selected: _type == t,
                    onTap: _busy ? null : () => setState(() => _type = t),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            WebInput(
              label: 'Описание',
              fieldKey: const Key('field-text'),
              controller: _text,
              enabled: !_busy,
              hint: _placeholders[_type],
              minLines: 5,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              error: _fieldErrors['text'],
              onChanged: (_) {
                if (_fieldErrors.containsKey('text')) setState(() => _fieldErrors = const {});
              },
            ),
            if (_type != AppealType.praise) ...[
              const SizedBox(height: 16),
              WebInput(
                label: 'Как это можно решить',
                optional: true,
                fieldKey: const Key('field-solution'),
                controller: _solution,
                enabled: !_busy,
                minLines: 2,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                error: _fieldErrors['proposed_solution'],
              ),
            ],
            const SizedBox(height: 16),
            // Категория и приоритет уже заданы разумно — прячем под «Уточнить».
            FutureBuilder<List<Category>>(
              future: _categories,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const <Category>[];
                final categoryName = _categoryId == null
                    ? 'Не знаю'
                    : categories.where((x) => x.id == _categoryId).map((x) => x.name).firstOrNull ?? '…';
                final error = _fieldErrors['category_id'] ??
                    (snapshot.hasError ? 'Категории не загрузились: ${(snapshot.error as AppError).message}' : null);
                return Container(
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Web.rTile)),
                  child: Column(children: [
                    _SettingRow(
                      key: const Key('more-fields'),
                      title: 'Уточнить',
                      value: _more ? null : '${_categoryId == null ? 'Без категории' : categoryName} · приоритет ${session.priorityLabel(_priority).toLowerCase()}',
                      trailing: AnimatedRotation(
                        turns: _more ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(LucideIcons.chevronDown, size: 18, color: c.muted),
                      ),
                      onTap: () => setState(() => _more = !_more),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: !_more
                          ? const SizedBox(width: double.infinity)
                          : Column(children: [
                              Divider(height: 1, indent: 16, endIndent: 16, color: c.palette.border),
                              _SettingRow(
                                key: const Key('field-category'),
                                title: 'Категория',
                                value: categoryName,
                                hint: _categoryId == null ? 'Без категории обращение распределит администратор' : null,
                                error: error,
                                trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.faint),
                                onTap: _busy ? null : () => _pickCategory(categories),
                              ),
                              Divider(height: 1, indent: 16, endIndent: 16, color: c.palette.border),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Приоритет', style: TextStyle(color: c.muted, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  _Segmented<Priority>(
                                    key: const Key('field-priority'),
                                    options: [for (final p in priorities) (p, session.priorityLabel(p))],
                                    value: _priority,
                                    onChanged: _busy ? null : (p) => setState(() => _priority = p),
                                  ),
                                ]),
                              ),
                            ]),
                    ),
                  ]),
                );
              },
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var i = 0; i < _files.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Web.rCtl)),
                  child: Row(children: [
                    Icon(LucideIcons.fileText, size: 18, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_files[i].name, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.heading))),
                    Text(formatSize(_files[i].size), style: TextStyle(color: c.muted, fontSize: 12.5)),
                    IconButton(
                      tooltip: 'Убрать',
                      icon: Icon(LucideIcons.x, size: 18, color: c.muted),
                      onPressed: _busy ? null : () => setState(() => _files.removeAt(i)),
                    ),
                  ]),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: c.danger)),
            ],
            const SizedBox(height: 20),
            // Подвал как `.compose__foot`: скрепка и «Отправить».
            Row(children: [
              ToolButton(
                key: const Key('add-files'),
                icon: LucideIcons.paperclip,
                tooltip: 'Приложить файлы — до 20 МБ',
                onTap: _busy ? () {} : _addFiles,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: WebButton(
                  key: const Key('submit-appeal'),
                  kind: WebButtonKind.accent,
                  label: _busy ? 'Отправляем…' : 'Отправить',
                  busy: _busy,
                  onPressed: _submit,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Карточка выбора типа: значок, название, подсказка, отметка.
class _TypeChoice extends StatelessWidget {
  const _TypeChoice({super.key, required this.type, required this.label, required this.hint, required this.selected, this.onTap});

  final AppealType type;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Web.rTile),
          border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          TypeIcon(type, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: c.heading, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(hint, style: TextStyle(color: c.muted, fontSize: 13)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? scheme.primary : Colors.transparent,
              border: Border.all(color: selected ? scheme.primary : c.faint, width: 1.5),
            ),
            child: selected ? Icon(LucideIcons.check, size: 14, color: scheme.onPrimary) : null,
          ),
        ]),
      ),
    );
  }
}

/// Строка настройки: название, значение, справа шеврон или своя иконка.
class _SettingRow extends StatelessWidget {
  const _SettingRow({super.key, required this.title, this.value, this.hint, this.error, required this.trailing, this.onTap});

  final String title;
  final String? value;
  final String? hint;
  final String? error;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Web.rTile),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: c.heading, fontSize: 15, fontWeight: FontWeight.w600)),
              if (value != null) ...[
                const SizedBox(height: 2),
                Text(value!, style: TextStyle(color: c.muted, fontSize: 13.5)),
              ],
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(hint!, style: TextStyle(color: c.muted, fontSize: 12.5)),
              ],
              if (error != null) ...[
                const SizedBox(height: 2),
                Text(error!, style: TextStyle(color: c.danger, fontSize: 12.5)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          trailing,
        ]),
      ),
    );
  }
}

/// Сегменты на подложке `--surface-2`: выбранный — белая плашка.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({super.key, required this.options, required this.value, this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(Web.rCtl)),
      child: Row(children: [
        for (final (v, label) in options)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChanged!(v);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == value ? c.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(Web.rCtl - 4),
                  boxShadow: v == value ? c.extra.shadowRaised : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: v == value ? c.heading : c.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Лист выбора из списка: строки с отметкой у выбранной.
class _PickSheet extends StatelessWidget {
  const _PickSheet({required this.title, required this.options, required this.selected});

  final String title;
  final List<(int, String, String?)> options;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(title, style: TextStyle(color: c.heading, fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              children: [
                for (final (id, name, hint) in options)
                  InkWell(
                    borderRadius: BorderRadius.circular(Web.rCtl),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: TextStyle(color: c.heading, fontSize: 15.5)),
                            if (hint != null) Text(hint, style: TextStyle(color: c.muted, fontSize: 12.5)),
                          ]),
                        ),
                        if (id == selected) Icon(LucideIcons.check, size: 18, color: Theme.of(context).colorScheme.primary),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Сразу после подачи: номер, ответственный и срок первого ответа.
class _CreatedScreen extends StatelessWidget {
  const _CreatedScreen({required this.appeal, required this.failed});

  final Appeal appeal;
  final List<_FailedFile> failed;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final due = appeal.firstResponseDueAt;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: c.successBg, shape: BoxShape.circle),
                  child: Icon(LucideIcons.check, size: 36, color: c.success),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Обращение ${appeal.number} подано',
              key: const Key('created-number'),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.heading, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              'Ответ придёт в приложение и в Telegram.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 14.5),
            ),
            const SizedBox(height: 24),
            FactsTile([
              ('Ответственный', appeal.assignee?.fullName ?? 'Назначит администратор'),
              ('Первый ответ', due != null ? 'до ${formatDateTime(due)}' : 'Без срока'),
            ]),
            if (failed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.dangerBg, borderRadius: BorderRadius.circular(Web.rTile)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Не все файлы загрузились — приложите их из карточки обращения:',
                      style: TextStyle(color: c.danger, fontWeight: FontWeight.w600)),
                  for (final f in failed) Text('${f.name}: ${f.message}', style: TextStyle(color: c.danger)),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            WebButton(
              key: const Key('open-created'),
              label: 'Открыть обращение',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<bool>(builder: (_) => AppealScreen(appealId: appeal.id), settings: const RouteSettings()),
                result: true,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                key: const Key('back-to-list'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('К моим обращениям', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
