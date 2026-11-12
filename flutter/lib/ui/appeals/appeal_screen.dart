import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/attachment_files.dart';
import '../../appeals/labels.dart';
import '../../format.dart';
import '../home/unread_scope.dart';
import 'actions_panel.dart';
import 'badges.dart';
import 'duplicates_bitrix.dart';
import '../discussions/discussion_screen.dart';
import 'new_appeal_screen.dart' show FilesPicker, pickFilesFromDevice;
import '../../theme/modus_theme.dart';
import '../home/role_switch.dart';
import 'card_parts.dart';
import '../web/web_ui.dart';

/// Карточка обращения: итог, сведения, описание, переписка, вложения, история.
/// Действия показываются только из `allowed_actions`.
class AppealScreen extends StatefulWidget {
  const AppealScreen({super.key, required this.appealId, this.pickFiles = pickFilesFromDevice});

  final int appealId;
  final FilesPicker pickFiles;

  @override
  State<AppealScreen> createState() => _AppealScreenState();
}

class _AppealScreenState extends State<AppealScreen> {
  Appeal? _appeal;
  AppError? _error;
  bool _loading = true;

  /// Меняется при каждом обновлении карточки — по нему перечитываются история и переписка.
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
  }

  Future<void> _load({bool markRead = false}) async {
    setState(() => _error = null);
    try {
      final appeal = await SessionScope.read(context).api.appeals.getAppeal(widget.appealId);
      if (appeal == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (!mounted) return;
      setState(() {
        _appeal = appeal;
        _version++;
      });
      if (markRead) UnreadScope.maybeRead(context)?.markAppealRead(widget.appealId);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Действие вернуло обращение — показываем его и перечитываем историю и переписку.
  void _replace(Appeal appeal) => setState(() {
    _appeal = appeal;
    _version++;
  });

  @override
  Widget build(BuildContext context) {
    final appeal = _appeal;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const CardSkeleton()
            : appeal == null
            ? _ErrorView(error: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: _AppealBody(appeal: appeal, version: _version, onChanged: _load, onUpdated: _replace, pickFiles: widget.pickFiles),
              ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final AppError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final notFound = error.status == 404 || error.status == 403;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notFound ? 'Обращение не найдено или у вас нет к нему доступа.' : error.message, textAlign: TextAlign.center),
            if (!notFound) ...[const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Повторить'))],
          ],
        ),
      ),
    );
  }
}

class _AppealBody extends StatelessWidget {
  const _AppealBody({
    required this.appeal,
    required this.version,
    required this.onChanged,
    required this.onUpdated,
    required this.pickFiles,
  });

  final Appeal appeal;
  final int version;
  final Future<void> Function() onChanged;
  final ValueChanged<Appeal> onUpdated;
  final FilesPicker pickFiles;

  @override
  Widget build(BuildContext context) {
    final a = appeal;
    final session = SessionScope.of(context);
    final theme = Theme.of(context);
    final participant = a.access == AppealAccessEnum.participant;
    final due = a.firstResponseDueAt;
    final c = ModusColors.of(context);
    final facts = <(String, String)>[
      if (a.author != null && !a.viewerRelations.contains(ViewerRelation.author))
        ('Автор', [a.author!.fullName, if (a.author!.department != null) a.author!.department!.name].join(' · ')),
      ('Ответственный', a.assignee?.fullName ?? 'Назначит администратор'),
      ('Категория', a.category?.name ?? 'Не указана'),
      ('Срок первого ответа', due != null ? formatDateTime(due) : 'Без срока'),
      if (a.firstResponseAt != null) ('Первый ответ', formatDateTime(a.firstResponseAt!)),
      ('Подано', formatDateTime(a.createdAt)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
      children: [
        // Шапка страницы обращения: «Обращение» над номером, назад — круглой кнопкой.
        WebPageHead(
          over: 'Обращение',
          title: a.number,
          leading: ToolButton(icon: LucideIcons.arrowLeft, tooltip: 'Назад', onTap: () => Navigator.of(context).maybePop()),
          tools: [RoleSwitchAction(appealId: a.id)],
        ),
        WebCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  TypeBadge(a.type),
                  StatusBadge(a.status),
                  if (a.status != AppealStatus.closed) DueBadge(state: a.dueState, dueAt: due),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                a.summary ?? 'Без краткой сути',
                style: TextStyle(color: c.heading, fontSize: 21, fontWeight: FontWeight.w500, height: 1.2, letterSpacing: -0.6),
              ),
              const SizedBox(height: 6),
              Text(
                [a.number, a.category?.name ?? 'без категории', 'приоритет ${session.priorityLabel(a.priority).toLowerCase()}'].join(' · '),
                style: TextStyle(color: c.muted, fontSize: 13.5),
              ),
              if (participant) ...[
                const SizedBox(height: 12),
                const _Notice(
                  text:
                      'Вы видите это обращение, потому что ваше присоединили к нему как повтор. '
                      'Статусы и итог приходят вам, текст и автор основного обращения скрыты.',
                ),
              ],
              _Outcome(appeal: a, onOpen: (id) => _openAppeal(context, id)),
              if (a.participantsCount > 1 && !participant)
                _Notice(
                  key2: const Key('participants-count'),
                  text: 'Об этом сказали ${a.participantsCount} ${plural(a.participantsCount, ('человек', 'человека', 'человек'))}',
                  tone: _Tone.info,
                ),
              if (a.text != null) ...[
                const SizedBox(height: 18),
                SelectableText(a.text!, style: TextStyle(fontSize: 15.5, height: 1.55, color: theme.colorScheme.onSurface)),
                if (a.forwardedFrom != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Переслано из: ${a.forwardedFrom}', style: TextStyle(color: c.muted, fontSize: 13)),
                  ),
              ],
              if (a.proposedSolution != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Web.rTile)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Предлагаемое решение',
                        style: TextStyle(color: c.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(a.proposedSolution!, style: const TextStyle(fontSize: 15, height: 1.5)),
                    ],
                  ),
                ),
              ],
              if (needsAssignee(a)) AssignSection(appeal: a, onUpdated: onUpdated),
              if (DiscussionRef.fromJson(a.discussion) case final discussion?) _DiscussionLink(discussion: discussion),
              // Подвал действий (`.sheet__foot`): переписка и действия по обращению.
              Container(
                margin: const EdgeInsets.only(top: 18),
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.palette.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!participant && canReadMessages(a)) ...[
                      ChatEntry(key: ValueKey('chat-$version'), appeal: a, onAppealChanged: onChanged),
                      const SizedBox(height: 8),
                    ],
                    ActionsPanel(appeal: a, onUpdated: onUpdated),
                  ],
                ),
              ),
              CardBlock(children: [FactsTile(facts)]),
              if (!participant) ...[
                DuplicatesSection(
                  key: ValueKey('duplicates-$version'),
                  appeal: a,
                  onMerged: onChanged,
                  onOpen: (id) => _openAppeal(context, id),
                ),
                BitrixSection(appeal: a, onUpdated: onUpdated),
                AttachmentsSection(appeal: a, onChanged: onChanged, pickFiles: pickFiles),
                HistorySection(key: ValueKey('history-$version'), appealId: a.id),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Ссылка на обсуждение, если обращение вынесено (автор отсюда отвечает на запрос о показе имени).
class _DiscussionLink extends StatelessWidget {
  const _DiscussionLink({required this.discussion});

  final DiscussionRef discussion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final open = discussion.status == DiscussionStatus.open;
    return Padding(
      key: const Key('discussion-link'),
      padding: const EdgeInsets.only(top: 12),
      child: ListTile(
        tileColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModusRadius.lg)),
        leading: const Icon(Icons.forum_outlined),
        title: Text(open ? 'Вынесено на общее обсуждение' : 'Общее обсуждение завершено'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DiscussionScreen(discussionId: discussion.id))),
      ),
    );
  }
}

void _openAppeal(BuildContext context, int id) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => AppealScreen(key: ValueKey('appeal-$id'), appealId: id),
  ),
);

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.title, this.tone = _Tone.neutral, this.key2});

  final String? title;
  final String text;
  final _Tone tone;
  final Key? key2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      _Tone.success => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tone.danger => (scheme.errorContainer, scheme.onErrorContainer),
      _Tone.warn => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _Tone.neutral => (scheme.surfaceContainerHighest, scheme.onSurface),
      _Tone.info => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Container(
      key: key2,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(ModusRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(title!, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg)),
            ),
          Text(text, style: TextStyle(color: fg)),
        ],
      ),
    );
  }
}

enum _Tone { neutral, info, success, danger, warn }

/// Итог: причина отказа, результат, принятое решение, причина закрытия.
/// Автор повтора видит, к какому обращению его присоединили, и статус основного.
class _Outcome extends StatelessWidget {
  const _Outcome({required this.appeal, required this.onOpen});

  final Appeal appeal;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final a = appeal;
    if (a.status == AppealStatus.rejected && a.rejectionReason != null) {
      return _Notice(key2: const Key('rejection-reason'), title: 'Причина отказа', text: a.rejectionReason!, tone: _Tone.danger);
    }
    if (a.status == AppealStatus.implemented && a.result != null) {
      return _Notice(key2: const Key('result'), title: 'Результат', text: a.result!, tone: _Tone.success);
    }
    if (a.status == AppealStatus.inProgress && a.decision != null) {
      return _Notice(title: 'Принятое решение', text: a.decision!);
    }
    final main = a.mergedInto;
    if (a.status == AppealStatus.closed && main != null) {
      final theme = Theme.of(context);
      return Container(
        key: const Key('merged-into'),
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(ModusRadius.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(closedReasonLabel(a.closedReason ?? ClosedReason.merged), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            InkWell(
              key: const Key('open-main'),
              onTap: () => onOpen(main.id),
              child: Text(
                [main.number, if (main.summary != null) main.summary!].join(' · '),
                style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Статус основного: ', style: theme.textTheme.bodySmall),
                StatusBadge(main.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('Статусы основного обращения будут приходить вам.', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }
    if (a.status == AppealStatus.closed && a.closedReason != null) {
      return _Notice(text: closedReasonLabel(a.closedReason!));
    }
    return const SizedBox.shrink();
  }
}

/// Приватная переписка окном чата (#160): сообщения по дням, свои справа, имя над серией одного автора.
class MessagesSection extends StatefulWidget {
  const MessagesSection({super.key, required this.appeal, required this.onAppealChanged});

  final Appeal appeal;
  final Future<void> Function() onAppealChanged;

  @override
  State<MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<MessagesSection> {
  List<Message>? _messages;
  AppError? _loadError;
  final _text = TextEditingController();
  bool _busy = false;
  String? _sendError;

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
      final list = await SessionScope.read(context).api.messages.listMessages(widget.appeal.id);
      if (mounted) setState(() => _messages = list ?? const []);
    } catch (e) {
      if (mounted) setState(() => _loadError = AppError.from(e));
    }
  }

  bool get _replying => widget.appeal.allowedActions.contains(AppealAction.replyClarification);

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final replying = _replying;
    setState(() {
      _busy = true;
      _sendError = null;
    });
    try {
      final message = await SessionScope.read(context).api.messages.postMessage(widget.appeal.id, PostMessageRequest(text: text));
      _text.clear();
      if (message != null && mounted) setState(() => _messages = [...?_messages, message]);
      // Ответ на уточнение возвращает обращение в «На рассмотрении» — перечитываем карточку.
      if (replying) await widget.onAppealChanged();
    } catch (e) {
      if (mounted) setState(() => _sendError = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Нет доступа к переписке — раздела нет.
    if (_loadError?.status == 403) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final me = SessionScope.of(context).me;
    final replying = _replying;
    final canWrite = replying || widget.appeal.allowedActions.contains(AppealAction.sendMessage);
    final messages = _messages ?? const <Message>[];
    final lastQuestion = messages.reversed.where((m) => m.isClarificationQuestion).firstOrNull;
    final rows = <Widget>[];
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (i == 0 || dayKey(messages[i - 1].createdAt) != dayKey(m.createdAt)) {
        rows.add(_DaySeparator(formatDayTitle(m.createdAt)));
      }
      final startsRun = i == 0 || messages[i - 1].author.id != m.author.id || rows.last is _DaySeparator;
      rows.add(
        _MessageBubble(
          // Вопрос, на который ждут ответа, отмечен ключом: он в переписке один раз, без отдельной плашки.
          key: replying && identical(m, lastQuestion) ? const Key('clarification-question') : null,
          message: m,
          mine: m.author.id == me.id,
          showName: startsRun,
        ),
      );
    }
    final c = ModusColors.of(context);
    // Панель переписки как `.chat` в вебе: шапка, лента по дням снизу вверх, поле с кнопкой «Отправить».
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.palette.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
                child: Icon(LucideIcons.messageCircle, size: 20, color: c.heading),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Переписка',
                      style: TextStyle(color: c.heading, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    Text('${widget.appeal.number} · в общую ленту не попадает', style: TextStyle(color: c.muted, fontSize: 13)),
                  ],
                ),
              ),
              ToolButton(icon: LucideIcons.x, tooltip: 'Закрыть', onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
        Expanded(
          child: _messages == null && _loadError == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    if (_loadError != null) Text(_loadError!.message, style: TextStyle(color: theme.colorScheme.error)),
                    if (_messages != null && messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Сообщений пока нет.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.muted),
                        ),
                      ),
                    ...rows.reversed,
                  ],
                ),
        ),
        if (canWrite)
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 8),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), boxShadow: c.extra.shadowRaised),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('message-text'),
                    controller: _text,
                    enabled: !_busy,
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16, height: 1.45),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintText: replying ? 'Ответ на вопрос' : 'Напишите сообщение',
                      hintStyle: TextStyle(color: c.muted, fontSize: 16),
                      errorText: _sendError,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Row(
                    children: [
                      const Spacer(),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _busy || _text.text.trim().isEmpty ? 0.45 : 1,
                        child: Material(
                          color: theme.colorScheme.primary,
                          shape: const StadiumBorder(),
                          child: InkWell(
                            key: const Key('message-send'),
                            customBorder: const StadiumBorder(),
                            onTap: _busy || _text.text.trim().isEmpty
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _send();
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    replying ? 'Ответить' : 'Отправить',
                                    style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 6),
                                  _busy
                                      ? SizedBox.square(
                                          dimension: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                                        )
                                      : Icon(LucideIcons.arrowUp, size: 16, color: theme.colorScheme.onPrimary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Экран переписки — открывается из карточки кнопкой «Переписка» (в вебе — панель рядом с карточкой).
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.appeal, required this.onAppealChanged});

  final Appeal appeal;
  final Future<void> Function() onAppealChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ModusColors.of(context).card,
    body: SafeArea(
      bottom: false,
      child: MessagesSection(appeal: appeal, onAppealChanged: onAppealChanged),
    ),
  );
}

/// Кнопка «Переписка» в подвале карточки (`.chat-entry`): значок, подпись и, если ждут ответа, акцент.
class ChatEntry extends StatelessWidget {
  const ChatEntry({super.key, required this.appeal, required this.onAppealChanged});

  final Appeal appeal;
  final Future<void> Function() onAppealChanged;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final ask = appeal.allowedActions.contains(AppealAction.replyClarification);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: ask ? c.warnBg : c.extra.surface3,
        shape: const StadiumBorder(),
        child: InkWell(
          key: const Key('chat-entry'),
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(appeal: appeal, onAppealChanged: onAppealChanged),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.messageCircle, size: 18, color: ask ? c.warn : c.heading),
                const SizedBox(width: 10),
                Text(
                  ask ? 'Ответить на вопрос' : 'Переписка',
                  style: TextStyle(color: ask ? c.warn : c.heading, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(child: Text(text, style: Theme.of(context).textTheme.labelSmall)),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({super.key, required this.message, required this.mine, required this.showName});

  final Message message;
  final bool mine;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    final question = message.isClarificationQuestion;
    final bg = question
        ? c.warnBg
        : mine
        ? theme.colorScheme.primary
        : c.surface;
    final fg = question
        ? c.warn
        : mine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    const r = Radius.circular(18);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName && !mine)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, bottom: 2),
              child: Text(message.author.fullName, style: theme.textTheme.labelSmall),
            ),
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: r,
                topRight: r,
                bottomLeft: mine ? r : const Radius.circular(6),
                bottomRight: mine ? const Radius.circular(6) : r,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question)
                  Text(
                    'Уточняющий вопрос',
                    style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
                  ),
                SelectableText(message.text, style: TextStyle(color: fg)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(formatTime(message.createdAt), style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.7))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Вложения галереей (#191): картинки — плитками с превью, остальные файлы — строками.
/// Приложить файл — если в `allowed_actions` есть `upload_attachment`.
class AttachmentsSection extends StatefulWidget {
  const AttachmentsSection({super.key, required this.appeal, required this.onChanged, required this.pickFiles});

  final Appeal appeal;
  final Future<void> Function() onChanged;
  final FilesPicker pickFiles;

  @override
  State<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<AttachmentsSection> {
  bool _busy = false;

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _open(Attachment attachment) async {
    try {
      await openAttachment(SessionScope.read(context).api, attachment);
    } on AppError catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _upload() async {
    final api = SessionScope.read(context).api;
    final files = await widget.pickFiles();
    if (!mounted || files.isEmpty) return;
    setState(() => _busy = true);
    final errors = <String>[];
    for (final f in files) {
      if (f.size > maxAttachmentBytes) {
        errors.add('${f.name}: больше 20 МБ');
        continue;
      }
      try {
        await uploadAttachment(api, widget.appeal.id, f);
      } on AppError catch (e) {
        errors.add('${f.name}: ${e.message}');
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (errors.isNotEmpty) _snack('Не загрузились: ${errors.join('; ')}');
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.appeal.attachments;
    final canUpload = widget.appeal.allowedActions.contains(AppealAction.uploadAttachment);
    if (attachments.isEmpty && !canUpload) return const SizedBox.shrink();
    final images = attachments.where(isImage).toList();
    final files = attachments.where((a) => !isImage(a)).toList();
    return CardBlock(
      title: attachments.isEmpty ? 'Вложения' : 'Вложения · ${attachments.length}',
      children: [
        if (images.isNotEmpty)
          GridView.count(
            key: const Key('attachment-gallery'),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final a in images) AttachmentThumb(key: Key('attachment-${a.id}'), attachment: a, onTap: () => _open(a))],
          ),
        for (final a in files)
          ListTile(
            key: Key('attachment-${a.id}'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(a.filename, overflow: TextOverflow.ellipsis),
            subtitle: Text('${formatSize(a.sizeBytes)} · ${a.uploadedBy.fullName}'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _open(a),
          ),
        if (attachments.isEmpty) Text('Файлов нет.', style: Theme.of(context).textTheme.bodySmall),
        if (canUpload)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('upload-attachment'),
              onPressed: _busy ? null : _upload,
              icon: _busy
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.attach_file),
              label: const Text('Приложить файл'),
            ),
          ),
      ],
    );
  }
}

/// История раскрывающимся блоком (#195): события по дням, у события — время.
/// Свёрнута по умолчанию; выбор живёт, пока открыта карточка.
class HistorySection extends StatefulWidget {
  const HistorySection({super.key, required this.appealId});

  final int appealId;

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  List<HistoryEvent>? _events;
  AppError? _error;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final events = await SessionScope.read(context).api.appeals.getAppealHistory(widget.appealId);
      if (mounted) setState(() => _events = events ?? const []);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    String? value(String? v, String? field) => v == null ? null : historyValue(session.historyCodeLabel(field, v));
    final events = _events ?? const <HistoryEvent>[];
    final rows = <Widget>[];
    for (var i = 0; i < events.length; i++) {
      final ev = events[i];
      if (i == 0 || dayKey(events[i - 1].createdAt) != dayKey(ev.createdAt)) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(formatDayTitle(ev.createdAt), style: theme.textTheme.labelLarge),
          ),
        );
      }
      rows.add(
        Padding(
          key: Key('history-${ev.id}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 48, child: Text(formatTime(ev.createdAt), style: muted)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(historyKindLabel(ev.kind), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (ev.oldValue != null || ev.newValue != null)
                      Text([value(ev.oldValue, ev.field), value(ev.newValue, ev.field)].whereType<String>().join(' → ')),
                    if (ev.comment != null) Text(ev.comment!, style: muted),
                    Text(ev.actor?.fullName ?? 'Система', style: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return CardBlock(
      title: _events == null ? 'История' : 'История · ${events.length}',
      trailing: TextButton(
        key: const Key('history-toggle'),
        onPressed: () => setState(() => _open = !_open),
        child: Text(_open ? 'Свернуть' : 'Показать'),
      ),
      children: [
        if (_open) ...[
          if (_events == null && _error == null) const LinearProgressIndicator(),
          if (_error != null) Text(_error!.message, style: TextStyle(color: theme.colorScheme.error)),
          ...rows,
        ],
      ],
    );
  }
}

final _isoDateTime = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}');

/// Значение из истории: дата-время (например, новый срок) — в формате приложения, остальное как есть.
String? historyValue(String? v) {
  if (v == null || !_isoDateTime.hasMatch(v)) return v;
  final t = DateTime.tryParse(v);
  return t == null ? v : formatDateTime(t);
}
