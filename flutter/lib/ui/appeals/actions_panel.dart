import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/api_service.dart';
import '../../api/app_error.dart';
import '../../app.dart';

/// Действия обработки в карточке. Набор кнопок — ровно `allowed_actions` от бэкенда
/// (как `ActionsPanel` в вебе). Вынос на обсуждение добавит F-05.
const processingActions = [
  AppealAction.take,
  AppealAction.requestInfo,
  AppealAction.startWork,
  AppealAction.reject,
  AppealAction.implement,
  AppealAction.acceptFeedback,
  AppealAction.reassign,
];

class ActionsPanel extends StatelessWidget {
  const ActionsPanel({super.key, required this.appeal, required this.onUpdated});

  final Appeal appeal;
  final ValueChanged<Appeal> onUpdated;

  Future<void> _open(BuildContext context, AppealAction action) async {
    final updated = await showModalBottomSheet<Appeal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: _formFor(action),
      ),
    );
    if (updated != null) onUpdated(updated);
  }

  Widget _formFor(AppealAction action) {
    final id = appeal.id;
    return switch (action) {
      AppealAction.take => _TextAction(
          title: 'Взять на рассмотрение',
          fieldLabel: 'Первый ответ автору — необязательно',
          optional: true,
          submitLabel: 'Взять',
          run: (api, text) => api.appealActions
              .takeAppeal(id, takeAppealRequest: TakeAppealRequest(comment: text.isEmpty ? null : text)),
        ),
      AppealAction.requestInfo => _TextAction(
          title: 'Уточняющий вопрос автору',
          fieldLabel: 'Вопрос',
          submitLabel: 'Задать вопрос',
          run: (api, text) => api.appealActions.requestInfo(id, RequestInfoRequest(question: text)),
        ),
      AppealAction.startWork => _TextAction(
          title: 'Перевести в работу',
          fieldLabel: 'Принятое решение — что будет сделано',
          submitLabel: 'В работу',
          run: (api, text) => api.appealActions.startWork(id, StartWorkRequest(decision: text)),
        ),
      AppealAction.reject => _TextAction(
          title: 'Отклонить',
          fieldLabel: 'Причина отказа — её увидит автор',
          submitLabel: 'Отклонить',
          danger: true,
          run: (api, text) => api.appealActions.rejectAppeal(id, RejectAppealRequest(reason: text)),
        ),
      AppealAction.acceptFeedback => _TextAction(
          title: 'Принять отзыв',
          fieldLabel: 'Ответ автору — необязательно',
          optional: true,
          submitLabel: 'Принять',
          run: (api, text) => api.appealActions.acceptFeedback(id,
              acceptFeedbackRequest: AcceptFeedbackRequest(comment: text.isEmpty ? null : text)),
        ),
      AppealAction.implement => _ImplementForm(appeal: appeal),
      AppealAction.reassign => _ReassignForm(appeal: appeal),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final actions = processingActions.where(appeal.allowedActions.contains).toList();
    if (actions.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Действия', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in actions)
            a == AppealAction.reject
                ? OutlinedButton(
                    key: Key('action-${a.toJson()}'),
                    style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                    onPressed: () => _open(context, a),
                    child: Text(session.actionLabel(a)),
                  )
                : FilledButton.tonal(
                    key: Key('action-${a.toJson()}'),
                    onPressed: () => _open(context, a),
                    child: Text(session.actionLabel(a)),
                  ),
        ]),
      ]),
    );
  }
}

typedef _Run = Future<Appeal?> Function(ApiService api, String text);

/// Общая форма действия: заголовок, поля, кнопка, ошибка сервера. Закрывается с новым обращением.
class _ActionForm extends StatefulWidget {
  const _ActionForm({
    required this.title,
    required this.submitLabel,
    required this.canSubmit,
    required this.run,
    required this.children,
    this.danger = false,
  });

  final String title;
  final String submitLabel;
  final bool canSubmit;
  final bool danger;
  final Future<Appeal?> Function() run;
  final List<Widget> children;

  @override
  State<_ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<_ActionForm> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (!widget.canSubmit || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final appeal = await widget.run();
      if (appeal == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (mounted) Navigator.of(context).pop(appeal);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...widget.children,
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, key: const Key('action-error'), style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('action-submit'),
            style: widget.danger ? FilledButton.styleFrom(backgroundColor: scheme.error) : null,
            onPressed: _busy || !widget.canSubmit ? null : _submit,
            child: Text(_busy ? 'Сохраняем…' : widget.submitLabel),
          ),
        ]),
      ),
    );
  }
}

/// «Одно текстовое поле + кнопка». Обязательное поле нельзя отправить пустым.
class _TextAction extends StatefulWidget {
  const _TextAction({
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    required this.run,
    this.optional = false,
    this.danger = false,
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;
  final bool optional;
  final bool danger;
  final _Run run;

  @override
  State<_TextAction> createState() => _TextActionState();
}

class _TextActionState extends State<_TextAction> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = SessionScope.read(context).api;
    return _ActionForm(
      title: widget.title,
      submitLabel: widget.submitLabel,
      danger: widget.danger,
      canSubmit: widget.optional || _text.text.trim().isNotEmpty,
      run: () => widget.run(api, _text.text.trim()),
      children: [
        TextField(
          key: const Key('action-text'),
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: widget.fieldLabel, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

/// «Реализовано»: результат обязателен, публичные формулировки для ленты — нет.
class _ImplementForm extends StatefulWidget {
  const _ImplementForm({required this.appeal});

  final Appeal appeal;

  @override
  State<_ImplementForm> createState() => _ImplementFormState();
}

class _ImplementFormState extends State<_ImplementForm> {
  final _result = TextEditingController();
  late final _publicSummary = TextEditingController(text: widget.appeal.publicSummary ?? '');
  final _publicResult = TextEditingController();

  @override
  void dispose() {
    _result.dispose();
    _publicSummary.dispose();
    _publicResult.dispose();
    super.dispose();
  }

  String? _orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final api = SessionScope.read(context).api;
    return _ActionForm(
      title: 'Отметить реализованным',
      submitLabel: 'Реализовано',
      canSubmit: _result.text.trim().isNotEmpty,
      run: () => api.appealActions.implementAppeal(
        widget.appeal.id,
        ImplementAppealRequest(
          result: _result.text.trim(),
          publicSummary: _orNull(_publicSummary),
          publicResult: _orNull(_publicResult),
        ),
      ),
      children: [
        TextField(
          key: const Key('implement-result'),
          controller: _result,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Результат — что сделано', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          'Обращение попадёт в ленту реализованного, которую видят все. '
          'Без публичных формулировок в ленте покажутся краткая суть и результат.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('implement-public-summary'),
          controller: _publicSummary,
          decoration: const InputDecoration(
              labelText: 'Для ленты: что предложили', helperText: 'Необязательно', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('implement-public-result'),
          controller: _publicResult,
          decoration: const InputDecoration(
              labelText: 'Для ленты: что сделали', helperText: 'Необязательно', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

/// Переназначение: новый ответственный и причина (обе обязательны), срок отсчитается заново.
class _ReassignForm extends StatefulWidget {
  const _ReassignForm({required this.appeal});

  final Appeal appeal;

  @override
  State<_ReassignForm> createState() => _ReassignFormState();
}

class _ReassignFormState extends State<_ReassignForm> {
  late final Future<List<User>> _users;
  int? _assigneeId;
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _users = SessionScope.read(context).api.dictionaries.listUsers().then((users) => [
          for (final u in users ?? const <User>[])
            if (!u.isDisabled && u.role != Role.admin && u.id != widget.appeal.assignee?.id) u,
        ]);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = SessionScope.read(context).api;
    return _ActionForm(
      title: 'Переназначить ответственного',
      submitLabel: 'Переназначить',
      canSubmit: _assigneeId != null && _reason.text.trim().isNotEmpty,
      run: () => api.appealActions.reassignAppeal(
        widget.appeal.id,
        ReassignAppealRequest(assigneeId: _assigneeId!, reason: _reason.text.trim()),
      ),
      children: [
        FutureBuilder<List<User>>(
          future: _users,
          builder: (context, snapshot) => DropdownButtonFormField<int>(
            key: const Key('reassign-user'),
            initialValue: _assigneeId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Новый ответственный',
              border: const OutlineInputBorder(),
              errorText: snapshot.hasError ? AppError.from(snapshot.error!).message : null,
            ),
            items: [
              for (final u in snapshot.data ?? const <User>[])
                DropdownMenuItem(
                  value: u.id,
                  child: Text(
                    [
                      u.fullName,
                      if (u.department != null) '— ${u.department!.name}',
                      if (u.isAbsent) '(отсутствует)',
                    ].join(' '),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _assigneeId = v),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('reassign-reason'),
          controller: _reason,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Причина — попадёт в историю', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text('Срок первого ответа отсчитается заново.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
