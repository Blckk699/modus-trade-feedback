import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modus_api/api.dart';

import '../../api/api_service.dart';
import '../../app.dart';
import '../../appeals/queue_scopes.dart';
import '../../navigation/sections.dart';
import '../../theme/modus_theme.dart';
import '../appeals/appeal_screen.dart';
import '../appeals/badges.dart';
import '../appeals/duplicates_bitrix.dart' show plural;
import '../appeals/rows.dart';
import '../discussions/discussion_screen.dart';
import 'role_switch.dart';

/// Данные «Сегодня» одним заходом, как `loadHome` в вебе. Необязательные куски при сбое не показываются.
class TodayData {
  TodayData({
    required this.queue,
    required this.assignedOpen,
    required this.assignedOverdue,
    required this.awaitingMe,
    required this.unassigned,
    required this.unassignedTotal,
    required this.accessRequests,
    required this.summary,
    required this.discussions,
    required this.discussionsTotal,
    required this.loadedAt,
  });

  final List<AppealListItem> queue;
  final int? assignedOpen;
  final int assignedOverdue;
  final List<AppealListItem> awaitingMe;
  final List<AppealListItem> unassigned;
  final int? unassignedTotal;
  final int? accessRequests;
  final AnalyticsSummary? summary;
  final List<Discussion> discussions;
  final int discussionsTotal;
  final DateTime loadedAt;
}

Future<T?> _soft<T>(Future<T?> call) => call.then<T?>((v) => v).catchError((Object _) => null);

Future<TodayData> loadToday(ApiService api, Me me) async {
  final p = me.permissions;
  final scope = defaultQueueScope(me);
  // Администратор стартует с нераспределённых; для общего списка берём все обращения, если видит их.
  final listScope = scope == AppealScope.unassigned && p.canViewAllAppeals ? AppealScope.all : scope;
  final results = await Future.wait<Object?>([
    if (listScope != null)
      _soft(api.appeals.listAppeals(scope: listScope, status: openStatuses, sort: 'due_asc', pageSize: 30))
    else
      Future.value(null),
    p.canProcessAppeals
        ? _soft(api.appeals.listAppeals(scope: AppealScope.assigned, status: openStatuses, sort: 'due_asc', pageSize: 50))
        : Future.value(null),
    p.canCreateAppeal
        ? _soft(api.appeals.listAppeals(scope: AppealScope.mine, status: const [AppealStatus.awaitingInfo], pageSize: 5))
        : Future.value(null),
    p.canViewUnassigned
        ? _soft(api.appeals.listAppeals(scope: AppealScope.unassigned, status: openStatuses, sort: 'due_asc', pageSize: 5))
        : Future.value(null),
    p.canManageAccess
        ? _soft(api.access.listAccessRequests(status: AccessRequestStatus.pending, pageSize: 1))
        : Future.value(null),
    p.analyticsScope != PermissionsAnalyticsScopeEnum.none ? _soft(api.analytics.getAnalyticsSummary()) : Future.value(null),
    _soft(api.discussions.listDiscussions(status: DiscussionStatus.open, pageSize: 4)),
  ]);
  final queue = results[0] as AppealPage?;
  final assigned = results[1] as AppealPage?;
  final awaiting = results[2] as AppealPage?;
  final unassigned = results[3] as AppealPage?;
  final requests = results[4] as AccessRequestPage?;
  final discussions = results[6] as DiscussionPage?;
  return TodayData(
    queue: queue?.items ?? const [],
    assignedOpen: assigned?.total,
    assignedOverdue: assigned?.items.where((a) => a.dueState == DueState.overdue).length ?? 0,
    awaitingMe: awaiting?.items ?? const [],
    unassigned: unassigned?.items ?? const [],
    unassignedTotal: unassigned?.total,
    accessRequests: requests?.total,
    summary: results[5] as AnalyticsSummary?,
    discussions: discussions?.items ?? const [],
    discussionsTotal: discussions?.total ?? 0,
    loadedAt: DateTime.now(),
  );
}

String _appeals(int n) => plural(n, ('обращение', 'обращения', 'обращений'));

/// «Главное на сейчас» — две-три фразы из настоящих чисел, как `buildBrief` в вебе.
List<String> buildBrief(TodayData d) {
  final out = <String>[];
  final open = d.assignedOpen;
  if (open != null && open > 0) {
    final overdue = d.assignedOverdue > 0
        ? ', ${d.assignedOverdue} ${plural(d.assignedOverdue, ('просрочено', 'просрочены', 'просрочено'))}'
        : '';
    out.add('У вас $open ${_appeals(open)} в работе$overdue.');
  }
  final awaiting = d.awaitingMe.length;
  if (awaiting > 0) {
    out.add(awaiting == 1 ? 'Вас ждёт вопрос по обращению.' : 'Вас ждут вопросы по $awaiting обращениям.');
  }
  final un = d.unassignedTotal;
  if (un != null && un > 0) {
    out.add('$un ${plural(un, ('обращение ждёт', 'обращения ждут', 'обращений ждут'))} ответственного.');
  }
  final req = d.accessRequests;
  if (req != null && req > 0) {
    out.add('$req ${plural(req, ('заявка на доступ ждёт', 'заявки на доступ ждут', 'заявок на доступ ждут'))} решения.');
  }
  final s = d.summary;
  if (s != null && (s.newLast24h.isNotEmpty || s.overdue.isNotEmpty)) {
    final where = s.scope == AnalyticsSummaryScopeEnum.company ? 'В компании' : 'В подразделении';
    final parts = [
      if (s.newLast24h.isNotEmpty) '${s.newLast24h.length} ${plural(s.newLast24h.length, ('новое', 'новых', 'новых'))} за сутки',
      if (s.overdue.isNotEmpty) '${s.overdue.length} ${plural(s.overdue.length, ('просрочено', 'просрочены', 'просрочено'))}',
    ];
    out.add('$where: ${parts.join(', ')}.');
  }
  if (out.length < 3 && d.discussionsTotal > 0) {
    final n = d.discussionsTotal;
    out.add('${plural(n, ('Идёт', 'Идут', 'Идёт'))} $n ${plural(n, ('обсуждение', 'обсуждения', 'обсуждений'))}, можно проголосовать.');
  }
  if (out.isEmpty) {
    out.addAll(['Срочного нет.', 'Что-то мешает работать или есть идея? Напишите, ответственный ответит в срок.']);
  }
  return out.take(3).toList();
}

/// Приветствие по времени суток (UTC+5), имя — первое слово.
String greeting(String fullName, DateTime now) {
  final h = now.toUtc().add(const Duration(hours: 5)).hour;
  final hello = h < 5
      ? 'Доброй ночи'
      : h < 12
          ? 'Доброе утро'
          : h < 18
              ? 'Добрый день'
              : 'Добрый вечер';
  final name = fullName.trim().split(RegExp(r'\s+')).first;
  return name.isEmpty ? hello : '$hello, $name';
}

/// «Сегодня» — стартовый экран всех ролей, как `HomePage` в вебе.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.onOpenSection});

  final ValueChanged<Section> onOpenSection;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<TodayData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<TodayData> _load() {
    final s = SessionScope.read(context);
    return loadToday(s.api, s.me);
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  Future<void> _openAppeal(int id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: id)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).me;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final day = DateFormat('EEEE, d MMMM', 'ru').format(now.toUtc().add(const Duration(hours: 5)));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 92,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(day[0].toUpperCase() + day.substring(1), style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(greeting(me.fullName, now), key: const Key('today-greeting')),
        ]),
        actions: const [RoleSwitchAction(), SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<TodayData>(
          future: _data,
          builder: (context, s) {
            final d = s.data;
            if (d == null) {
              if (s.hasError) {
                return ListView(padding: const EdgeInsets.all(32), children: [
                  Text('Не удалось загрузить. Потяните вниз, чтобы повторить.', textAlign: TextAlign.center),
                ]);
              }
              return const _Skeleton();
            }
            return _TodayView(
              data: d,
              onOpenAppeal: _openAppeal,
              onOpenSection: widget.onOpenSection,
              onReload: _reload,
            );
          },
        ),
      ),
    );
  }
}

class _TodayView extends StatelessWidget {
  const _TodayView({required this.data, required this.onOpenAppeal, required this.onOpenSection, required this.onReload});

  final TodayData data;
  final ValueChanged<int> onOpenAppeal;
  final ValueChanged<Section> onOpenSection;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final theme = Theme.of(context);
    final me = SessionScope.of(context).me;
    final sections = sectionsFor(me);
    final now = DateTime.now();
    final waiting = [...d.awaitingMe, ...d.unassigned];
    final chips = <(String, Section)>[
      if ((d.unassignedTotal ?? 0) > 0 && sections.contains(Section.processing)) ('Без ответственного', Section.processing),
      if (sections.contains(Section.myAppeals)) ('Мои обращения', Section.myAppeals),
      if (d.discussionsTotal > 0) ('Обсуждения', Section.feed),
      if (sections.contains(Section.analytics)) ('Сводка', Section.analytics),
    ];
    return ListView(
      key: const Key('today'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        _Block(
          title: 'Главное на сейчас',
          subtitle: 'Данные на ${DateFormat('HH:mm').format(d.loadedAt)}',
          action: OutlinedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Обновить'),
          ),
          children: [
            Text(
              buildBrief(d).join(' '),
              key: const Key('today-brief'),
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w500, height: 1.35),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (label, section) in chips)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                    onPressed: () => onOpenSection(section),
                    child: Text(label),
                  ),
              ]),
            ],
          ],
        ),
        if (waiting.isNotEmpty)
          _Block(
            title: 'Ждёт вас',
            count: waiting.length,
            children: [
              for (final a in waiting.take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _WaitingCard(item: a, onOpen: () => onOpenAppeal(a.id)),
                ),
            ],
          ),
        if (d.queue.isNotEmpty) ...[
          _SectionTitle(
            title: 'Входящие',
            subtitle: 'Сначала те, где ждут первого ответа',
            onAll: sections.contains(Section.processing) ? () => onOpenSection(Section.processing) : null,
          ),
          RowsCard(children: [
            for (final a in d.queue.take(5))
              WebRow(
                type: a.type,
                title: a.summary ?? 'Без краткой сути',
                meta: [a.number, if (a.category != null) a.category!.name, a.assignee?.fullName ?? 'без ответственного'].join(' · '),
                unread: a.hasUnread,
                overdue: a.dueState == DueState.overdue,
                onTap: () => onOpenAppeal(a.id),
                badges: [
                  StatusBadge(a.status),
                  if (a.firstResponseDueAt != null && a.dueState != DueState.answered && a.dueState != DueState.noDeadline)
                    Text(
                      timeLeftLabel(a.firstResponseDueAt!, now),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: a.dueState == DueState.overdue ? ModusColors.of(context).danger : ModusColors.of(context).muted,
                      ),
                    ),
                ],
              ),
          ]),
        ],
        if (d.discussions.isNotEmpty) ...[
          _SectionTitle(
            title: 'Обсуждения',
            subtitle: 'Идеи, по которым собирают мнения',
            onAll: () => onOpenSection(Section.feed),
          ),
          RowsCard(children: [
            for (final disc in d.discussions)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: Text(disc.publicText, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                subtitle: Text('за ${disc.votesFor} · против ${disc.votesAgainst}', style: theme.textTheme.bodySmall),
                trailing: disc.canVote ? const Icon(Icons.how_to_vote_outlined) : const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => DiscussionScreen(discussionId: disc.id)),
                ),
              ),
          ]),
        ],
      ],
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.item, required this.onOpen});

  final AppealListItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    final unassigned = item.assignee == null;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebLook.tileRadius)),
      child: InkWell(
        borderRadius: BorderRadius.circular(WebLook.tileRadius),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TypeIcon(item.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.summary ?? 'Без краткой сути', style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    [item.number, SessionScope.of(context).typeLabel(item.type), if (item.author != null) item.author!.fullName].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(WebLook.controlRadius)),
              child: Text(
                unassigned ? 'Ответственного нет: выберите, кто ответит.' : 'Ответственный задал вопрос — ответьте в карточке.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: onOpen, child: Text(unassigned ? 'Назначить' : 'Ответить')),
          ]),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, this.subtitle, this.count, this.action, required this.children});

  final String title;
  final String? subtitle;
  final int? count;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebLook.cardRadius)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (count != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          color: c.status('in_progress').bg,
                          borderRadius: BorderRadius.circular(ModusRadius.pill),
                        ),
                        child: Text('$count', style: TextStyle(color: c.status('in_progress').fg, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ]),
                  if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
                ]),
              ),
              ?action,
            ]),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle, this.onAll});

  final String title;
  final String subtitle;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleMedium),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ]),
        ),
        if (onAll != null) OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)), onPressed: onAll, child: const Text('Все')),
      ]),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    Widget block(double h) => Container(
          height: h,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(WebLook.cardRadius)),
        );
    return ListView(
      key: const Key('today-skeleton'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [block(200), block(220), block(160)],
    );
  }
}
