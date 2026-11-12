import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../theme/modus_theme.dart';
import '../../format.dart';
import 'discussion_screen.dart';
import '../web/web_ui.dart';
import '../home/role_switch.dart';

/// Общая лента для всех: открытые обсуждения, реализованные улучшения, завершённые обсуждения
/// (истории 20–22). Вкладки как в вебе.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Лента'),
          actions: const [RoleSwitchAction()],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              height: 42,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: ModusColors.of(context).extra.surface3, borderRadius: BorderRadius.circular(99)),
              child: const TabBar(
                labelPadding: EdgeInsets.zero,
                tabs: [
                  Tab(key: Key('tab-open'), text: 'Обсуждения'),
                  Tab(key: Key('tab-implemented'), text: 'Реализовано'),
                  Tab(key: Key('tab-closed'), text: 'Завершённые'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(children: [
          DiscussionList(status: DiscussionStatus.open),
          ImplementedList(),
          DiscussionList(status: DiscussionStatus.closed),
        ]),
      ),
    );
  }
}

/// Загрузка списка с обновлением свайпом и экраном ошибки.
class _Loader<T> extends StatefulWidget {
  const _Loader({super.key, required this.load, required this.empty, required this.builder});

  final Future<List<T>> Function(BuildContext context) load;
  final String empty;
  final Widget Function(BuildContext context, List<T> items, Future<void> Function() reload) builder;

  @override
  State<_Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<_Loader<T>> with AutomaticKeepAliveClientMixin {
  List<T>? _items;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final items = await widget.load(context);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _items;
    if (items == null && _error == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _reload,
      child: _error != null && items == null
          ? ListView(padding: const EdgeInsets.all(32), children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ])
          : items!.isEmpty
              ? ListView(padding: const EdgeInsets.all(32), children: [Text(widget.empty, textAlign: TextAlign.center)])
              : widget.builder(context, items, _reload),
    );
  }
}

class DiscussionList extends StatelessWidget {
  const DiscussionList({super.key, required this.status});

  final DiscussionStatus status;

  @override
  Widget build(BuildContext context) {
    return _Loader<Discussion>(
      key: ValueKey('discussions-${status.toJson()}'),
      load: (context) async {
        final page = await SessionScope.read(context).api.discussions.listDiscussions(status: status, pageSize: 50);
        return page?.items ?? const [];
      },
      empty: status == DiscussionStatus.open ? 'Сейчас нет открытых обсуждений.' : 'Завершённых обсуждений пока нет.',
      builder: (context, items, reload) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => DiscussionRow(
          discussion: items[i],
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => DiscussionScreen(discussionId: items[i].id)));
            reload();
          },
        ),
      ),
    );
  }
}

class DiscussionRow extends StatelessWidget {
  const DiscussionRow({super.key, required this.discussion, required this.onTap});

  final Discussion discussion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = discussion;
    final session = SessionScope.of(context);
    final c = ModusColors.of(context);
    final open = d.status == DiscussionStatus.open;
    final muted = TextStyle(color: c.muted, fontSize: 13);
    final waitsVote = open && d.canVote && d.myVote == null;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(Web.rCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('discussion-${d.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  d.publicText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.heading, fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.typeLabel(d.appeal.type)} · ${d.authorDisplay} · '
                  '${open ? 'до ${formatDateTime(d.deadline)}' : 'завершено ${d.closedAt != null ? formatDate(d.closedAt!) : ''}'}',
                  style: muted,
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 14, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (waitsVote)
                    Text('Ждёт вашего голоса',
                        style: TextStyle(color: c.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                  _Count(icon: LucideIcons.thumbsUp, value: d.votesFor, label: 'За'),
                  _Count(icon: LucideIcons.thumbsDown, value: d.votesAgainst, label: 'Против'),
                  _Count(icon: LucideIcons.messageCircle, value: d.commentsCount, label: 'Комментарии'),
                  if (d.myVote != null)
                    Text('ваш голос: ${d.myVote == VoteValue.for_ ? 'за' : 'против'}', style: muted),
                ]),
                if (!open && d.outcome != null) ...[
                  const SizedBox(height: 8),
                  Text('Итог: ${d.outcome}', style: TextStyle(color: c.heading, fontSize: 13.5)),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 18, color: c.faint),
          ]),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value, required this.label});

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $value',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: ModusColors.of(context).muted),
          const SizedBox(width: 4),
          Text('$value', style: TextStyle(color: ModusColors.of(context).heading, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// Лента реализованного: что предложили и что сделали (история 20).
class ImplementedList extends StatelessWidget {
  const ImplementedList({super.key});

  @override
  Widget build(BuildContext context) {
    return _Loader<FeedItem>(
      load: (context) async {
        final page = await SessionScope.read(context).api.feed.listImplementedFeed(pageSize: 50);
        return page?.items ?? const [];
      },
      empty: 'Реализованных улучшений пока нет.',
      builder: (context, items, _) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => FeedRow(item: items[i]),
      ),
    );
  }
}

class FeedRow extends StatelessWidget {
  const FeedRow({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final f = item;
    final session = SessionScope.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final label = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary);
    return Container(
      key: Key('feed-${f.appealId}'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: ModusColors.of(context).card, borderRadius: BorderRadius.circular(Web.rCard)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              [session.typeLabel(f.type), if (f.category != null) f.category!.name].join(' · '),
              style: muted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(formatDate(f.implementedAt), style: muted),
        ]),
        const SizedBox(height: 8),
        Text('Что предложили', style: label),
        Text(f.publicSummary),
        const SizedBox(height: 8),
        Text('Что сделали', style: label),
        Text(f.result),
        const SizedBox(height: 8),
        Row(children: [
          Text(f.authorDisplay, style: muted),
          if (f.discussionId != null) ...[
            Text(' · ', style: muted),
            InkWell(
              key: Key('feed-discussion-${f.appealId}'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => DiscussionScreen(discussionId: f.discussionId!))),
              child: Text('обсуждение',
                  style: muted?.copyWith(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
            ),
          ],
        ]),
      ]),
    );
  }
}
