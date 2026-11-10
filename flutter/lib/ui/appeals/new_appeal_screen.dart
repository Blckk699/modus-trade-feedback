import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/attachment_files.dart';
import '../../format.dart';
import 'appeal_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final created = _created;
    if (created != null) return _CreatedScreen(appeal: created, failed: _failed);
    final session = SessionScope.of(context);
    final dict = session.dictionaries;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Новое обращение')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Тип', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                key: const Key('field-type'),
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final t in AppealType.values)
                    ChoiceChip(
                      key: Key('type-${t.toJson()}'),
                      label: Text(session.typeLabel(t)),
                      selected: _type == t,
                      onSelected: _busy ? null : (_) => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Category>>(
                future: _categories,
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? const <Category>[];
                  return DropdownButtonFormField<int?>(
                    key: const Key('field-category'),
                    initialValue: _categoryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Категория',
                      helperText: _categoryId == null ? 'Без категории обращение распределит администратор' : null,
                      helperMaxLines: 2,
                      border: const OutlineInputBorder(),
                      errorText: _fieldErrors['category_id'] ??
                          (snapshot.hasError ? 'Категории не загрузились: ${(snapshot.error as AppError).message}' : null),
                      errorMaxLines: 3,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Не знаю')),
                      for (final c in categories) DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _categoryId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                key: const Key('field-priority'),
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Приоритет', border: OutlineInputBorder()),
                items: [
                  for (final p in dict == null ? Priority.values : dict.priorities.map((p) => Priority.fromJson(p.code)!))
                    DropdownMenuItem(value: p, child: Text(session.priorityLabel(p))),
                ],
                onChanged: _busy ? null : (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('field-text'),
                controller: _text,
                enabled: !_busy,
                minLines: 5,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  hintText: _type == AppealType.praise
                      ? 'Что работает хорошо и кого отметить'
                      : 'Что происходит, где и как часто',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  errorText: _fieldErrors['text'],
                ),
                onChanged: (_) {
                  if (_fieldErrors.containsKey('text')) setState(() => _fieldErrors = const {});
                },
              ),
              if (_type != AppealType.praise) ...[
                const SizedBox(height: 16),
                TextField(
                  key: const Key('field-solution'),
                  controller: _solution,
                  enabled: !_busy,
                  minLines: 3,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Предлагаемое решение',
                    helperText: 'Необязательно',
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    errorText: _fieldErrors['proposed_solution'],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text('Вложения — до 20 МБ на файл', style: theme.textTheme.labelLarge)),
                TextButton.icon(
                  key: const Key('add-files'),
                  onPressed: _busy ? null : _addFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Добавить'),
                ),
              ]),
              for (var i = 0; i < _files.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(_files[i].name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatSize(_files[i].size)),
                  trailing: IconButton(
                    tooltip: 'Убрать',
                    icon: const Icon(Icons.close),
                    onPressed: _busy ? null : () => setState(() => _files.removeAt(i)),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('submit-appeal'),
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Отправляем…' : 'Отправить'),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);
    final due = appeal.firstResponseDueAt;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Обращение подано'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Обращение ${appeal.number} подано',
                key: const Key('created-number'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Ответственный'),
              subtitle: Text(appeal.assignee?.fullName ?? 'Назначит администратор'),
            ),
            ListTile(
              title: const Text('Первый ответ'),
              subtitle: Text(due != null ? 'до ${formatDateTime(due)}' : 'Без срока'),
            ),
            if (failed.isNotEmpty)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Не все файлы загрузились — приложите их из карточки обращения:',
                        style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                    for (final f in failed)
                      Text('${f.name}: ${f.message}', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ]),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('open-created'),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<bool>(builder: (_) => AppealScreen(appealId: appeal.id), settings: const RouteSettings()),
                result: true,
              ),
              child: const Text('Открыть обращение'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('back-to-list'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('К моим обращениям'),
            ),
          ],
        ),
      ),
    );
  }
}
