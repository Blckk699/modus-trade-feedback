import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../format.dart';
import '../appeals/appeal_screen.dart';
import '../../theme/modus_theme.dart';
import '../web/web_ui.dart';

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
    final back = ToolButton(icon: LucideIcons.arrowLeft, tooltip: 'Назад', onTap: () => Navigator.of(context).maybePop());
    return Scaffold(
      body: WebScrollPage(
        over: 'Обсуждение',
        title: d?.appeal.number ?? 'Обсуждение',
        leading: back,
        onRefresh: d == null ? null : _load,
        bottomPadding: 48,
        children: d == null
            ? [
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: _error == null
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : Text(_error!.status == 404 ? 'Обсуждение не найдено.' : _error!.message,
                          textAlign: TextAlign.center),
                ),
              ]
            : [
                WebCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _Header(discussion: d),
                    if (d.canSetNameConsent) _NameConsent(discussion: d, onUpdated: _set),
                    if (d.status == DiscussionStatus.closed && d.outcome != null) _Outcome(discussion: d),
                    _Votes(discussion: d, onUpdated: _set),
                    if (d.canClose && d.status == DiscussionStatus.open) _CloseForm(discussion: d, onUpdated: _set),
                  ]),
                ),
                const SizedBox(height: Web.gap),
                WebCard(child: _Comments(key: ValueKey('comments-${d.id}'), discussion: d)),
              ],
      ),
    );
  }
}

/// Плашка внутри карточки: подложка `--surface-2`, скругление плитки.
class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: color ?? ModusColors.of(context).surface2,
          borderRadius: BorderRadius.circular(Web.rTile),
        ),
        child: child,
      );
}

/// Заголовок раздела внутри карточки (`.section h3`).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(color: ModusColors.of(context).heading, fontSize: 16, fontWeight: FontWeight.w600),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.discussion});

  final Discussion discussion;

  @override
  Widget build(BuildContext context) {
    final d = discussion;
    final c = ModusColors.of(context);
    final session = SessionScope.of(context);
    final open = d.status == DiscussionStatus.open;
    final meta = TextStyle(color: c.muted, fontSize: 13.5, height: 1.4);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: ShapeDecoration(shape: const StadiumBorder(), color: open ? c.infoBg : c.surface2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(open ? LucideIcons.messagesSquare : LucideIcons.circleCheck, size: 14, color: open ? c.info : c.muted),
          const SizedBox(width: 6),
          Text(
            open ? 'Идёт обсуждение' : 'Обсуждение завершено',
            style: TextStyle(color: open ? c.info : c.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Text(d.publicText, style: TextStyle(color: c.heading, fontSize: 21, fontWeight: FontWeight.w500, height: 1.3)),
      const SizedBox(height: 8),
      Text('${session.typeLabel(d.appeal.type)} · ${d.authorDisplay}', style: meta),
      const SizedBox(height: 2),
      Text('${open ? 'Голосование до' : 'Срок был'} ${formatDateTime(d.deadline)}', style: meta),
      // Решать про имя может только автор — значит, это его обращение.
      if (d.canSetNameConsent) ...[
        const SizedBox(height: 12),
        WebChip(
          key: const Key('own-appeal'),
          icon: LucideIcons.fileText,
          label: 'Ваше обращение ${d.appeal.number}',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: d.appeal.id))),
        ),
      ],
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
    final colors = ModusColors.of(context);
    final text = switch (c) {
      NameConsent.pending => 'Ваше обращение вынесли на общее обсуждение. Показывать ваше имя? '
          'Пока вы не ответили, указано только подразделение.',
      NameConsent.shown => 'Ваше имя показано в обсуждении.',
      _ => 'Ваше имя скрыто, в обсуждении указано только подразделение.',
    };
    return _Tile(
      key: const Key('name-consent'),
      color: c == NameConsent.pending ? colors.warnBg : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(text, style: TextStyle(color: c == NameConsent.pending ? colors.warn : colors.heading, height: 1.45)),
        const SizedBox(height: 12),
        Row(children: [
          if (c != NameConsent.shown)
            Expanded(
              child: WebButton(
                key: const Key('consent-show'),
                label: 'Показать имя',
                busy: _busy,
                onPressed: () => _answer(true),
              ),
            ),
          if (c == NameConsent.pending) const SizedBox(width: 8),
          if (c != NameConsent.hidden)
            Expanded(
              child: WebButton(
                key: const Key('consent-hide'),
                kind: WebButtonKind.soft,
                tint: colors.surface,
                label: c == NameConsent.pending ? 'Не показывать' : 'Скрыть имя',
                onPressed: _busy ? null : () => _answer(false),
              ),
            ),
        ]),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_error!, style: TextStyle(color: colors.danger)),
        ),
      ]),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.discussion});

  final Discussion discussion;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final d = discussion;
    return _Tile(
      key: const Key('discussion-outcome'),
      color: c.successBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.circleCheck, size: 16, color: c.success),
          const SizedBox(width: 8),
          Text('Итог', style: TextStyle(color: c.success, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Text(d.outcome!, style: TextStyle(color: c.heading, fontSize: 15, height: 1.5)),
        if (d.closedAt != null) ...[
          const SizedBox(height: 6),
          Text('Зафиксирован ${formatDateTime(d.closedAt!)}', style: TextStyle(color: c.muted, fontSize: 12.5)),
        ],
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
    final c = ModusColors.of(context);
    final total = d.votesFor + d.votesAgainst;
    final share = total == 0 ? 0.0 : d.votesFor / total;
    final muted = TextStyle(color: c.muted, fontSize: 12.5, height: 1.4);
    Widget button(VoteValue v, String label, IconData icon) {
      final mine = d.myVote == v;
      return WebButton(
        key: Key('vote-${v.toJson()}'),
        kind: mine ? WebButtonKind.primary : WebButtonKind.soft,
        tint: mine ? null : c.surface,
        icon: Icon(icon),
        label: label,
        onPressed: _busy ? null : () => _vote(v),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _SectionTitle('Голосование'),
        const SizedBox(height: 12),
        Row(children: [
          Text('За ${d.votesFor}',
              key: const Key('votes-for'), style: TextStyle(color: c.success, fontWeight: FontWeight.w600, fontSize: 13.5)),
          const Spacer(),
          Text('Против ${d.votesAgainst}',
              key: const Key('votes-against'), style: TextStyle(color: c.danger, fontWeight: FontWeight.w600, fontSize: 13.5)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: share),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (total == 0)
                  Expanded(child: ColoredBox(color: c.surface2))
                else ...[
                  Expanded(flex: (v * 1000).round(), child: ColoredBox(color: c.success)),
                  if (v > 0 && v < 1) const SizedBox(width: 3),
                  Expanded(flex: ((1 - v) * 1000).round(), child: ColoredBox(color: c.danger)),
                ],
              ]),
            ),
          ),
        ),
        if (d.canVote) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(Web.rTile + 4)),
            child: Row(children: [
              Expanded(child: button(VoteValue.for_, 'За', LucideIcons.thumbsUp)),
              const SizedBox(width: 6),
              Expanded(child: button(VoteValue.against, 'Против', LucideIcons.thumbsDown)),
            ]),
          ),
          if (d.myVote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Нажмите на свой голос ещё раз, чтобы отозвать.', style: muted),
            ),
        ] else if (d.status == DiscussionStatus.open) ...[
          const SizedBox(height: 10),
          Text('Голосование для вас недоступно.', style: muted),
        ],
        const SizedBox(height: 6),
        Text('Голосование совещательное: итог фиксирует руководитель.', style: muted),
        if (_error != null) Text(_error!, style: TextStyle(color: c.danger)),
      ]),
    );
  }
}

/// «Зафиксировать итог»: кнопка в карточке, сам итог пишется в листе.
class _CloseForm extends StatelessWidget {
  const _CloseForm({required this.discussion, required this.onUpdated});

  final Discussion discussion;
  final ValueChanged<Discussion> onUpdated;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: WebButton(
          key: const Key('close-open'),
          icon: const Icon(LucideIcons.flagTriangleRight),
          label: 'Зафиксировать итог',
          onPressed: () async {
            final d = await showModalBottomSheet<Discussion>(
              context: context,
              isScrollControlled: true,
              builder: (sheet) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
                child: _CloseSheet(discussion: discussion),
              ),
            );
            if (d != null) onUpdated(d);
          },
        ),
      );
}

class _CloseSheet extends StatefulWidget {
  const _CloseSheet({required this.discussion});

  final Discussion discussion;

  @override
  State<_CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<_CloseSheet> {
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
      if (d != null && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(d);
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Итог обсуждения', style: TextStyle(color: c.heading, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Его увидят все, обсуждение закроется.', style: TextStyle(color: c.muted, fontSize: 13.5)),
          const SizedBox(height: 16),
          WebInput(
            fieldKey: const Key('close-outcome'),
            controller: _outcome,
            hint: 'Что решили и что будет дальше',
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            error: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          WebButton(
            key: const Key('close-submit'),
            label: 'Зафиксировать итог',
            busy: _busy,
            onPressed: _outcome.text.trim().isEmpty ? null : _submit,
          ),
        ]),
      ),
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
    final c = ModusColors.of(context);
    final theme = Theme.of(context);
    final items = _items;
    final canSend = !_busy && _text.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const _SectionTitle('Комментарии'),
        if (items != null && items.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text('${items.length}', style: TextStyle(color: c.muted, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ]),
      const SizedBox(height: 8),
      if (items == null && _loadError == null)
        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator.adaptive())),
      if (_loadError != null) Text(_loadError!, style: TextStyle(color: c.danger)),
      if (items != null && items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Комментариев пока нет — начните первым.', style: TextStyle(color: c.muted)),
        ),
      for (var i = 0; i < (items ?? const <DiscussionComment>[]).length; i++)
        _CommentRow(key: Key('comment-${items![i].id}'), comment: items[i], divider: i > 0),
      if (widget.discussion.status == DiscussionStatus.open) ...[
        const SizedBox(height: 12),
        // Поле как в переписке: плашка со скруглением 24 и круглой кнопкой отправки.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 2, 6, 6),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(24)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                key: const Key('comment-text'),
                controller: _text,
                enabled: !_busy,
                minLines: 1,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15.5, height: 1.45),
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Поделитесь опытом или мнением',
                  hintStyle: TextStyle(color: c.muted, fontSize: 15.5),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: canSend ? 1 : 0.35,
              child: Material(
                color: theme.colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('comment-send'),
                  customBorder: const CircleBorder(),
                  onTap: canSend
                      ? () {
                          HapticFeedback.lightImpact();
                          _send();
                        }
                      : null,
                  child: SizedBox.square(
                    dimension: 38,
                    child: _busy
                        ? Padding(
                            padding: const EdgeInsets.all(11),
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                          )
                        : Icon(LucideIcons.arrowUp, size: 18, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ),
            ),
          ]),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Text(_error!, style: TextStyle(color: c.danger, fontSize: 12.5)),
          ),
      ],
    ]);
  }
}

/// Комментарий: инициалы в круге, имя и подразделение, время, текст.
class _CommentRow extends StatelessWidget {
  const _CommentRow({super.key, required this.comment, required this.divider});

  final DiscussionComment comment;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final a = comment.author;
    final parts = a.fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: divider ? BoxDecoration(border: Border(top: BorderSide(color: c.palette.border))) : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
          child: Text(initials, style: TextStyle(color: c.heading, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: a.fullName, style: TextStyle(color: c.heading, fontWeight: FontWeight.w600)),
                if (a.department != null) TextSpan(text: ' · ${a.department!.name}', style: TextStyle(color: c.muted)),
              ]),
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 1),
            Text(formatDateTime(comment.createdAt), style: TextStyle(color: c.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(comment.text, style: TextStyle(color: c.heading, fontSize: 15, height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}
