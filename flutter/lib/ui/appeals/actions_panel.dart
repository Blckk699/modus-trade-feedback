import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';

import '../web/web_ui.dart';
import 'card_parts.dart' show needsAssignee;

import '../../api/api_service.dart';
import '../../api/app_error.dart';
import '../../app.dart';
import '../discussions/publish_discussion_form.dart';
import '../../theme/modus_theme.dart';
import '../sheet_header.dart';

/// Действия обработки в карточке. Набор кнопок — ровно `allowed_actions` от бэкенда
/// (как `ActionsPanel` в вебе).
const processingActions = [
  AppealAction.take,
  AppealAction.requestInfo,
  AppealAction.startWork,
  AppealAction.reject,
  AppealAction.implement,
  AppealAction.acceptFeedback,
  AppealAction.reassign,
  AppealAction.publishDiscussion,
];

class ActionsPanel extends StatelessWidget {
  const ActionsPanel({super.key, required this.appeal, required this.onUpdated, this.chat});

  final Appeal appeal;

  /// Вход в переписку — встаёт в ряд со второстепенным действием.
  final Widget? chat;
  final ValueChanged<Appeal> onUpdated;

  Future<void> _open(BuildContext context, AppealAction action) async {
    final updated = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: _formFor(action),
      ),
    );
    if (updated is Appeal) onUpdated(updated);
    // Вынос возвращает обсуждение — подставляем ссылку на него в обращение, как в вебе.
    if (updated is Discussion) {
      onUpdated(appeal..discussion = DiscussionRef(id: updated.id, status: updated.status).toJson());
    }
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
      AppealAction.publishDiscussion => PublishDiscussionForm(appeal: appeal),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _more(BuildContext context, List<AppealAction> actions) async {
    final picked = await showModalBottomSheet<AppealAction>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => _MoreSheet(actions: actions),
    );
    if (picked != null && context.mounted) await _open(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    // Уже вынесенное обращение второй раз не выносим: ссылка на обсуждение — в карточке.
    final actions = processingActions
        .where(appeal.allowedActions.contains)
        .where((a) => !(a == AppealAction.publishDiscussion && appeal.discussion != null))
        // Без ответственного назначают блоком в карточке, переназначать пока некого.
        .where((a) => !(a == AppealAction.reassign && needsAssignee(appeal)))
        .toList();
    // Главное действие — одна тёмная кнопка во всю ширину. Под ней ряд из двух равных кнопок:
    // «Переписка» и второстепенное действие (если оно одно) или «Ещё» со списком в листе.
    const primaryOrder = [
      AppealAction.take,
      AppealAction.startWork,
      AppealAction.implement,
      AppealAction.acceptFeedback,
      AppealAction.requestInfo,
    ];
    final primary = primaryOrder.where(actions.contains).firstOrNull;
    // «Отклонить» — последним, чтобы в листе он стоял внизу отдельно.
    final secondary = [
      ...actions.where((a) => a != AppealAction.reject && a != primary),
      if (actions.contains(AppealAction.reject)) AppealAction.reject,
    ];
    final Widget? second = switch (secondary.length) {
      0 => null,
      1 => WebButton(
          key: Key('action-${secondary.single.toJson()}'),
          kind: secondary.single == AppealAction.reject ? WebButtonKind.ghostDanger : WebButtonKind.soft,
          label: session.actionLabel(secondary.single),
          onPressed: () => _open(context, secondary.single),
        ),
      _ => WebButton(
          key: const Key('actions-more'),
          kind: WebButtonKind.soft,
          icon: const Icon(LucideIcons.ellipsis),
          label: 'Ещё',
          onPressed: () => _more(context, secondary),
        ),
    };
    final row = [?chat, ?second];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (primary != null)
        WebButton(
          key: Key('action-${primary.toJson()}'),
          label: session.actionLabel(primary),
          onPressed: () => _open(context, primary),
        ),
      if (primary != null && row.isNotEmpty) const SizedBox(height: 8),
      if (row.isNotEmpty)
        Row(children: [
          for (var i = 0; i < row.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: row[i])],
        ]),
    ]);
  }
}

IconData actionIcon(AppealAction a) => switch (a) {
      AppealAction.take => LucideIcons.hand,
      AppealAction.requestInfo => LucideIcons.messageCircleQuestion,
      AppealAction.startWork => LucideIcons.play,
      AppealAction.implement => LucideIcons.circleCheck,
      AppealAction.acceptFeedback => LucideIcons.check,
      AppealAction.reassign => LucideIcons.userPen,
      AppealAction.publishDiscussion => LucideIcons.messagesSquare,
      AppealAction.reject => LucideIcons.ban,
      _ => LucideIcons.chevronRight,
    };

/// Лист «Ещё»: второстепенные действия группой строк, «Отклонить» — отдельной красной строкой.
class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.actions});

  final List<AppealAction> actions;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final c = ModusColors.of(context);
    final normal = actions.where((a) => a != AppealAction.reject).toList();
    Widget group(List<AppealAction> items, {bool danger = false}) => ClipRRect(
          borderRadius: BorderRadius.circular(Web.rTile),
          child: ColoredBox(
            color: c.surface2,
            child: Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 52, color: c.palette.border),
                InkWell(
                  key: Key('action-${items[i].toJson()}'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(items[i]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    child: Row(children: [
                      Icon(actionIcon(items[i]), size: 20, color: danger ? c.danger : c.muted),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          session.actionLabel(items[i]),
                          style: TextStyle(
                            color: danger ? c.danger : c.heading,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (normal.isNotEmpty) group(normal),
          if (actions.contains(AppealAction.reject)) ...[
            if (normal.isNotEmpty) const SizedBox(height: 12),
            group(const [AppealAction.reject], danger: true),
          ],
        ]),
      ),
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
          SheetHeader(widget.title, enabled: !_busy),
          const SizedBox(height: 16),
          ...widget.children,
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, key: const Key('action-error'), style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 16),
          if (widget.danger)
            OutlinedButton(
              key: const Key('action-submit'),
              style: dangerButtonStyle(context),
              onPressed: _busy || !widget.canSubmit ? null : _submit,
              child: Text(_busy ? 'Сохраняем…' : widget.submitLabel),
            )
          else
            FilledButton(
              key: const Key('action-submit'),
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
