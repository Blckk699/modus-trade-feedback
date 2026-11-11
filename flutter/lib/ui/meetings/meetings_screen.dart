import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/attachment_files.dart' show PickedFile;
import '../../format.dart';
import 'meeting_screen.dart';
import '../../theme/modus_theme.dart';

/// Форматы и лимит из контракта: до 200 МБ.
const meetingExtensions = ['mp3', 'm4a', 'wav', 'ogg', 'webm'];
const maxMeetingBytes = 200 * 1024 * 1024;

typedef AudioPicker = Future<PickedFile?> Function();

Future<PickedFile?> pickAudioFromDevice() async {
  // Document picker на iOS и системный выбор файлов на Android; FileType.audio
  // на iOS открыл бы медиатеку и потребовал отдельного разрешения.
  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: meetingExtensions);
  final f = result?.files.singleOrNull;
  if (f == null || f.path == null) return null;
  return PickedFile(name: f.name, path: f.path!, size: f.size);
}

/// Режим «совещание»: загрузка записи и список своих совещаний (истории 48, 62).
/// Раздел виден при `can_upload_meetings` — руководителю и собственнику.
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key, this.pickAudio = pickAudioFromDevice});

  final AudioPicker pickAudio;

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  List<MeetingBrief>? _items;
  String? _loadError;
  final _title = TextEditingController();
  PickedFile? _file;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await SessionScope.read(context).api.meetings.listMeetings();
      if (mounted) {
        setState(() {
          _items = items ?? const [];
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = AppError.from(e).message);
    }
  }

  Future<void> _pick() async {
    final f = await widget.pickAudio();
    if (f == null || !mounted) return;
    if (f.size > maxMeetingBytes) {
      setState(() => _error = 'Файл больше 200 МБ.');
      return;
    }
    setState(() {
      _file = f;
      _error = null;
    });
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;
    final api = SessionScope.read(context).api;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final part = await http.MultipartFile.fromPath('file', file.path, filename: file.name);
      final title = _title.text.trim();
      final m = await api.meetings.uploadMeeting(part, title: title.isEmpty ? null : title);
      if (m == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (!mounted) return;
      setState(() {
        _file = null;
        _title.clear();
      });
      await navigator.push(MaterialPageRoute<void>(builder: (_) => MeetingScreen(meetingId: m.id)));
      _load();
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(MeetingBrief m) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MeetingScreen(meetingId: m.id)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Совещания')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Загрузите запись встречи: система расшифрует её и предложит черновики обращений с цитатами. '
              'Без вашего подтверждения обращения не создаются.',
              style: muted,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('meeting-title'),
              controller: _title,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Планёрка закупок',
                helperText: 'Необязательно',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('meeting-pick'),
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.audio_file_outlined),
              label: Text(_file == null ? 'Выбрать аудиозапись' : 'Выбрать другой файл'),
            ),
            const SizedBox(height: 4),
            Text(
              _file == null ? 'mp3, m4a, wav, ogg, webm, до 200 МБ' : '${_file!.name} · ${formatSize(_file!.size)}',
              key: const Key('meeting-file'),
              style: muted,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('meeting-upload'),
              style: accentButtonStyle(context),
              onPressed: _busy || _file == null ? null : _upload,
              child: Text(_busy ? 'Загружаем…' : 'Загрузить и расшифровать'),
            ),
            const SizedBox(height: 24),
            Text('Загруженные записи', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (items == null && _loadError == null) const LinearProgressIndicator(),
            if (_loadError != null) Text(_loadError!, style: TextStyle(color: theme.colorScheme.error)),
            if (items != null && items.isEmpty) Text('Вы ещё не загружали записи.', style: muted),
            for (final m in items ?? const <MeetingBrief>[])
              ListTile(
                key: Key('meeting-${m.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(m.title),
                subtitle: Text([
                  formatDateTime(m.createdAt),
                  if (m.status == MeetingStatus.ready)
                    'черновиков: ${m.draftsTotal}${m.draftsPending > 0 ? ', ждут решения: ${m.draftsPending}' : ', все разобраны'}',
                ].join(' · ')),
                trailing: MeetingStatusBadge(m.status),
                onTap: () => _open(m),
              ),
          ],
        ),
      ),
    );
  }
}

class MeetingStatusBadge extends StatelessWidget {
  const MeetingStatusBadge(this.status, {super.key});

  final MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (text, bg, fg) = switch (status) {
      MeetingStatus.ready => ('Готово', scheme.primaryContainer, scheme.onPrimaryContainer),
      MeetingStatus.failed => ('Ошибка обработки', scheme.errorContainer, scheme.onErrorContainer),
      _ => ('Обрабатывается', scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ModusRadius.md)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
    );
  }
}
