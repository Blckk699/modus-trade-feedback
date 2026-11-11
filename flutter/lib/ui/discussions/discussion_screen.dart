import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../format.dart';
import '../appeals/appeal_screen.dart';
import '../../theme/modus_theme.dart';

/// Обсуждение: формулировка, срок, запрос автору на показ имени, голосование,
/// итог (фиксирует руководитель) и комментарии. Права — по `can_vote`, `can_close`,
/// `can_set_name_consent` от бэкенда.
class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key, required this.discussionId});

  final int discussionId;

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  Discussion? _d;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await SessionScope.read(context).api.discussions.getDiscussion(widget.discussionId);
      if (d == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e));
    }
  }

  void _set(Discussion d) => setState(() => _d = d);

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('Обсуждение')),
      body: d == null
          ? (_error == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_error!.status == 404 ? 'Обсуждение не найдено.' : _error!.message,
                        textAlign: TextAlign.center),
                  ),
                ))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _Header(discussion: d),
                  if (d.canSetNameConsent) _NameConsent(discussion: d, onUpdated: _set),
                  if (d.status == DiscussionStatus.closed && d.outcome != null) _Outcome(discussion: d),
                  _Votes(discussion: d, onUpdated: _set),
                  if (d.canClose && d.status == DiscussionStatus.open) _CloseForm(discussion: d, onUpdated: _set),
                  _Comments(key: ValueKey('comments-${d.id}'), discussion: d),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.discussion});

  final Discussion discussion;

  @override
  Widget build(BuildContext context) {
    final d = discussion;
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    final open = d.status == DiscussionStatus.open;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(d.publicText, style: theme.textTheme.titleLarge),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: open ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ModusRadius.md),
          ),
          child: Text(open ? 'Идёт обсуждение' : 'Обсуждение завершено', style: theme.textTheme.labelMedium),
        ),
        Text('${session.typeLabel(d.appeal.type)} · ${d.authorDisplay}', style: muted),
      ]),
      const SizedBox(height: 4),
      Text('${open ? 'Голосование до' : 'Срок был'} ${formatDateTime(d.deadline)}', style: muted),
      // Решать про имя может только автор — значит, это его обращение.
      if (d.canSetNameConsent)
        TextButton(
          key: const Key('own-appeal'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: d.appeal.id))),
          child: Text('Ваше обращение ${d.appeal.number}'),
        ),
    ]);
  }
}

/// Запрос автору на показ имени (история 18). Решение можно изменить.
class _NameConsent extends StatefulWidget {
  const _NameConsent({required this.discussion, required this.onUpdated});

  final Discussion discussion;
  final ValueChanged<Discussion> onUpdated;

  @override
  State<_NameConsent> createState() => _NameConsentState();
}

class _NameConsentState extends State<_NameConsent> {
  bool _busy = false;
  String? _error;

  Future<void> _answer(bool show) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await SessionScope.read(context)
          .api
          .discussions
          .setNameConsent(widget.discussion.id, SetNameConsentRequest(showName: show));
      if (d != null) widget.onUpdated(d);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.discussion.authorNameConsent;
    final scheme = Theme.of(context).colorScheme;
    final text = switch (c) {
      NameConsent.pending => 'Ваше обращение вынесли на общее обсуждение. Показывать ваше имя? '
          'Пока вы не ответили, указано только подразделение.',
      NameConsent.shown => 'Ваше имя показано в обсуждении.',
      _ => 'Ваше имя скрыто, в обсуждении указано только подразделение.',
    };
    return Container(
      key: const Key('name-consent'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c == NameConsent.pending ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ModusRadius.lg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (c != NameConsent.shown)
            FilledButton(
              key: const Key('consent-show'),
              onPressed: _busy ? null : () => _answer(true),
              child: const Text('Показать имя'),
            ),
          if (c != NameConsent.hidden)
            OutlinedButton(
              key: const Key('consent-hide'),
              onPressed: _busy ? null : () => _answer(false),
              child: Text(c == NameConsent.pending ? 'Не показывать' : 'Скрыть имя'),
            ),
        ]),
        if (_error != null) Text(_error!, style: TextStyle(color: scheme.error)),
      ]),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.discussion});

  final Discussion discussion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = discussion;
    return Container(
      key: const Key('discussion-outcome'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(ModusRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Итог', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onPrimaryContainer)),
        const SizedBox(height: 4),
        Text(d.outcome!, style: TextStyle(color: scheme.onPrimaryContainer)),
        if (d.closedAt != null)
          Text('Зафиксирован ${formatDateTime(d.closedAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer)),
      ]),
    );
  }
}

/// Счёт голосов и голосование. Повторное нажатие на свой голос — отозвать.
class _Votes extends StatefulWidget {
  const _Votes({required this.discussion, required this.onUpdated});

  final Discussion discussion;
  final ValueChanged<Discussion> onUpdated;

  @override
  State<_Votes> createState() => _VotesState();
}

class _VotesState extends State<_Votes> {
  bool _busy = false;
  String? _error;

  Future<void> _vote(VoteValue v) async {
    final d = widget.discussion;
    final api = SessionScope.read(context).api.discussions;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = d.myVote == v ? await api.unvote(d.id) : await api.vote(d.id, VoteRequest(value: v));
      if (next != null) widget.onUpdated(next);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.discussion;
    final theme = Theme.of(context);
    final total = d.votesFor + d.votesAgainst;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget button(VoteValue v, String label, IconData icon) {
      final mine = d.myVote == v;
      final child = Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)]);
      final onPressed = _busy ? null : () => _vote(v);
      final key = Key('vote-${v.toJson()}');
      return mine
          ? FilledButton(key: key, onPressed: onPressed, child: child)
          : OutlinedButton(key: key, onPressed: onPressed, child: child);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Голосование', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(children: [
          Text('За ${d.votesFor}', key: const Key('votes-for')),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ModusRadius.sm),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : d.votesFor / total,
                minHeight: 8,
                backgroundColor: total == 0 ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.errorContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('Против ${d.votesAgainst}', key: const Key('votes-against')),
        ]),
        const SizedBox(height: 12),
        if (d.canVote) ...[
          Wrap(spacing: 8, children: [
            button(VoteValue.for_, 'За', Icons.thumb_up_alt_outlined),
            button(VoteValue.against, 'Против', Icons.thumb_down_alt_outlined),
          ]),
          if (d.myVote != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Нажмите на свой голос ещё раз, чтобы отозвать.', style: muted),
            ),
        ] else if (d.status == DiscussionStatus.open)
          Text('Голосование для вас недоступно.', style: muted),
        const SizedBox(height: 4),
        Text('Голосование совещательное: итог фиксирует руководитель.', style: muted),
        if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
      ]),
    );
  }
}

class _CloseForm extends StatefulWidget {
  const _CloseForm({required this.discussion, required this.onUpdated});

  final Discussion discussion;
  final ValueChanged<Discussion> onUpdated;

  @override
  State<_CloseForm> createState() => _CloseFormState();
}

class _CloseFormState extends State<_CloseForm> {
  final _outcome = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _outcome.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await SessionScope.read(context)
          .api
          .discussions
          .closeDiscussion(widget.discussion.id, CloseDiscussionRequest(outcome: _outcome.text.trim()));
      if (d != null) widget.onUpdated(d);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Зафиксировать итог', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          key: const Key('close-outcome'),
          controller: _outcome,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Итог обсуждения — его увидят все', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const Key('close-submit'),
            onPressed: _busy || _outcome.text.trim().isEmpty ? null : _submit,
            child: Text(_busy ? 'Сохраняем…' : 'Зафиксировать итог'),
          ),
        ),
      ]),
    );
  }
}

class _Comments extends StatefulWidget {
  const _Comments({super.key, required this.discussion});

  final Discussion discussion;

  @override
  State<_Comments> createState() => _CommentsState();
}

class _CommentsState extends State<_Comments> {
  List<DiscussionComment>? _items;
  String? _loadError;
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await SessionScope.read(context).api.discussions.listDiscussionComments(widget.discussion.id);
      if (mounted) setState(() => _items = items ?? const []);
    } catch (e) {
      if (mounted) setState(() => _loadError = AppError.from(e).message);
    }
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = await SessionScope.read(context)
          .api
          .discussions
          .postDiscussionComment(widget.discussion.id, PostMessageRequest(text: _text.text.trim()));
      _text.clear();
      if (c != null && mounted) setState(() => _items = [...?_items, c]);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final items = _items;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Комментарии', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items == null && _loadError == null) const LinearProgressIndicator(),
        if (_loadError != null) Text(_loadError!, style: TextStyle(color: theme.colorScheme.error)),
        if (items != null && items.isEmpty) Text('Комментариев пока нет.', style: muted),
        for (final c in items ?? const <DiscussionComment>[])
          Container(
            key: Key('comment-${c.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(ModusRadius.lg),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                [c.author.fullName, if (c.author.department != null) c.author.department!.name, formatDateTime(c.createdAt)]
                    .join(' · '),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(c.text),
            ]),
          ),
        if (widget.discussion.status == DiscussionStatus.open) ...[
          const SizedBox(height: 8),
          TextField(
            key: const Key('comment-text'),
            controller: _text,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Поделитесь опытом или мнением',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('comment-send'),
              onPressed: _busy || _text.text.trim().isEmpty ? null : _send,
              child: Text(_busy ? 'Отправляем…' : 'Комментировать'),
            ),
          ),
        ],
      ]),
    );
  }
}
