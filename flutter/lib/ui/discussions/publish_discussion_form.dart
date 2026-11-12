import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/deadline.dart';
import '../../format.dart';
import '../sheet_header.dart';

/// Вынос на общее обсуждение (история 38): публичная формулировка и срок голосования.
/// Закрывается с созданным обсуждением.
class PublishDiscussionForm extends StatefulWidget {
  const PublishDiscussionForm({super.key, required this.appeal});

  final Appeal appeal;

  @override
  State<PublishDiscussionForm> createState() => _PublishDiscussionFormState();
}

class _PublishDiscussionFormState extends State<PublishDiscussionForm> {
  late final _text = TextEditingController(text: widget.appeal.publicSummary ?? widget.appeal.summary ?? '');
  late DateTime _date = systemToday().add(const Duration(days: 3));
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = systemToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Голосование до',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await SessionScope.read(context).api.discussions.publishDiscussion(
            widget.appeal.id,
            DiscussionCreate(publicText: _text.text.trim(), deadline: deadlineFromDate(_date)),
          );
      if (d == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (mounted) Navigator.of(context).pop(d);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _text.text.trim().isNotEmpty && !_busy;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SheetHeader('Вынести на общее обсуждение', enabled: !_busy),
          const SizedBox(height: 8),
          Text(
            'Обсуждение увидят все сотрудники. Приватная переписка не публикуется. Автора спросят, '
            'показывать ли его имя, — без согласия будет указано только подразделение.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('discussion-text'),
            controller: _text,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Публичная формулировка', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('discussion-deadline'),
            onPressed: _busy ? null : _pickDate,
            icon: const Icon(Icons.event),
            label: Text('Голосование до ${formatDate(deadlineFromDate(_date))}, 18:00'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('discussion-publish'),
            onPressed: canSubmit ? _submit : null,
            child: Text(_busy ? 'Публикуем…' : 'Вынести на обсуждение'),
          ),
        ]),
      ),
    );
  }
}
