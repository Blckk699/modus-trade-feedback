import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import 'unread_scope.dart';
import '../web/web_ui.dart';
import '../appeals/new_appeal_screen.dart';
import '../../api/app_error.dart';

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
    this.assigned = const [],
    this.mine = const [],
    this.mineTotal = 0,
    this.implemented = const [],
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

  /// Назначенные мне открытые — для «Ждёт вас».
  final List<AppealListItem> assigned;

  /// Последние мои обращения.
  final List<AppealListItem> mine;
  final int mineTotal;

  /// Лента реализованного.
  final List<FeedItem> implemented;
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
    p.canManageAccess ? _soft(api.access.listAccessRequests(status: AccessRequestStatus.pending, pageSize: 1)) : Future.value(null),
    p.analyticsScope != PermissionsAnalyticsScopeEnum.none ? _soft(api.analytics.getAnalyticsSummary()) : Future.value(null),
    _soft(api.discussions.listDiscussions(status: DiscussionStatus.open, pageSize: 4)),
    p.canCreateAppeal ? _soft(api.appeals.listAppeals(scope: AppealScope.mine, sort: 'created_desc', pageSize: 5)) : Future.value(null),
    _soft(api.feed.listImplementedFeed(pageSize: 3)),
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
    assigned: assigned?.items ?? const [],
    mine: (results[7] as AppealPage?)?.items ?? const [],
    mineTotal: (results[7] as AppealPage?)?.total ?? 0,
    implemented: (results[8] as FeedPage?)?.items ?? const [],
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
    setState(() {
      _data = next;
    });
    await next;
  }

  Future<void> _openAppeal(int id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: id)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final me = session.me;
    final now = DateTime.now();
    final day = DateFormat('EEEE, d MMMM', 'ru').format(now.toUtc().add(const Duration(hours: 5)));
    final unread = UnreadScope.of(context).count;
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<TodayData>(
            future: _data,
            builder: (context, s) {
              final d = s.data;
              return WebScrollPage(
                key: const Key('today'),
                titleKey: const Key('today-greeting'),
                over: day[0].toUpperCase() + day.substring(1),
                title: greeting(me.fullName, now),
                onRefresh: _reload,
                tools: [
                  ToolButton(
                    icon: LucideIcons.bell,
                    tooltip: 'Уведомления',
                    badge: unread,
                    onTap: () => widget.onOpenSection(Section.myAppeals),
                  ),
                  const RoleSwitchAction(),
                ],
                children: [
                  if (d == null && s.hasError)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Не удалось загрузить. Потяните вниз, чтобы повторить.', textAlign: TextAlign.center),
                    )
                  else if (d == null)
                    const _Skeleton()
                  else
                    ..._blocks(context, d, me),
                ],
              );
            },
          ),
          if (me.permissions.canCreateAppeal)
            // Над панелью разделов: `bottom: calc(var(--tabbar-h) + 16px)`, справа 16 — как `.fab` в вебе.
            // В body с extendBody нижний отступ MediaQuery равен высоте панели.
            Positioned(
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: WebFab(
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NewAppealScreen()));
                  if (mounted) _reload();
                },
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _blocks(BuildContext context, TodayData d, Me me) {
    final sections = sectionsFor(me);
    final now = d.loadedAt;
    void open(int id) => _openAppeal(id);
    final blocks = <Widget>[
      _BriefCard(data: d, me: me, onOpenSection: widget.onOpenSection, onReload: _reload),
      _FocusCard(data: d, me: me, onOpen: open, onReload: _reload, onOpenSection: widget.onOpenSection),
      if (d.discussions.isNotEmpty || d.discussionsTotal == 0) _DiscussionsCard(data: d, onOpenSection: widget.onOpenSection),
      if (d.queue.isNotEmpty && sections.contains(Section.processing))
        WebCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebCardHead(
                title: 'Входящие',
                sub: 'Сначала те, где ждут первого ответа',
                action: WebChip(label: 'Все', onTap: () => widget.onOpenSection(Section.processing)),
              ),
              for (var i = 0; i < d.queue.take(5).length; i++) ...[
                if (i > 0) Divider(height: 1, color: ModusColors.of(context).palette.border),
                WebRow(
                  plain: true,
                  type: d.queue[i].type,
                  title: d.queue[i].summary ?? 'Без краткой сути',
                  meta: [
                    d.queue[i].number,
                    SessionScope.of(context).typeLabel(d.queue[i].type),
                    if (d.queue[i].category != null) d.queue[i].category!.name,
                    d.queue[i].assignee?.fullName ?? 'без ответственного',
                  ].join(' · '),
                  unread: d.queue[i].hasUnread,
                  onTap: () => open(d.queue[i].id),
                  badges: [
                    if (_waiting(d.queue[i])) _TimeLeft(item: d.queue[i], now: now),
                    StatusBadge(d.queue[i].status),
                  ],
                ),
              ],
            ],
          ),
        ),
      if (d.mine.isNotEmpty || (me.permissions.canCreateAppeal && d.queue.isEmpty))
        WebCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebCardHead(
                title: 'Мои обращения',
                sub: d.mineTotal > 0 ? 'Последние поданные' : null,
                action: WebChip(label: 'Все', onTap: () => widget.onOpenSection(Section.myAppeals)),
              ),
              if (d.mine.isEmpty)
                const _Quiet(
                  title: 'Вы ещё ничего не подавали',
                  text: 'Расскажите о проблеме, предложите улучшение или отметьте хорошую работу.',
                ),
              for (var i = 0; i < d.mine.length; i++) ...[
                if (i > 0) Divider(height: 1, color: ModusColors.of(context).palette.border),
                WebRow(
                  plain: true,
                  type: d.mine[i].type,
                  title: d.mine[i].summary ?? 'Без краткой сути',
                  meta: [
                    d.mine[i].number,
                    SessionScope.of(context).typeLabel(d.mine[i].type),
                    DateFormat('d MMM', 'ru').format(d.mine[i].createdAt.toUtc().add(const Duration(hours: 5))),
                    if (d.mine[i].mergedInto != null) 'присоединено к ${d.mine[i].mergedInto!.number}',
                  ].join(' · '),
                  unread: d.mine[i].hasUnread,
                  onTap: () => open(d.mine[i].id),
                  badges: [
                    if (_waiting(d.mine[i])) _TimeLeft(item: d.mine[i], now: now),
                    StatusBadge(d.mine[i].status),
                  ],
                ),
              ],
            ],
          ),
        ),
      if (d.implemented.isNotEmpty) _DoneCard(items: d.implemented, onOpenSection: widget.onOpenSection),
    ];
    return [
      for (var i = 0; i < blocks.length; i++) ...[
        if (i > 0) const SizedBox(height: Web.gap),
        // Блоки появляются по очереди — мягкий подъём, как анимация карточек в вебе.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + 60 * i),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
          ),
          child: blocks[i],
        ),
      ],
    ];
  }
}

bool _waiting(AppealListItem a) =>
    a.firstResponseDueAt != null && a.dueState != DueState.answered && a.dueState != DueState.noDeadline && a.status != AppealStatus.closed;

/// `.row__due`: «осталось 2 д 3 ч» — --muted, скоро — --warn, просрочено — --danger.
class _TimeLeft extends StatelessWidget {
  const _TimeLeft({required this.item, required this.now});

  final AppealListItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final color = switch (item.dueState) {
      DueState.overdue => c.danger,
      DueState.dueSoon => c.warn,
      _ => c.muted,
    };
    return Text(
      timeLeftLabel(item.firstResponseDueAt!, now),
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

class _BriefCard extends StatelessWidget {
  const _BriefCard({required this.data, required this.me, required this.onOpenSection, required this.onReload});

  final TodayData data;
  final Me me;
  final ValueChanged<Section> onOpenSection;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final d = data;
    final s = d.summary;
    final sections = sectionsFor(me);
    final scope = s != null
        ? (s.scope == AnalyticsSummaryScopeEnum.company
              ? 'Вся компания'
              : 'Подразделение «${s.department?.name ?? me.department?.name ?? ''}»')
        : (d.assignedOpen != null ? 'Ваши обращения в работе' : 'Ваши обращения');
    final chips = <(String, Section)>[
      if (d.assignedOverdue > 0 && sections.contains(Section.processing)) ('Просроченные', Section.processing),
      if ((d.unassignedTotal ?? 0) > 0 && sections.contains(Section.processing)) ('Без ответственного', Section.processing),
      if ((d.accessRequests ?? 0) > 0 && sections.contains(Section.settings)) ('Заявки на доступ', Section.settings),
      if (sections.contains(Section.myAppeals)) ('Мои обращения', Section.myAppeals),
      ('Обсуждения', Section.feed),
    ];
    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Главное на сейчас',
                      style: TextStyle(color: c.heading, fontSize: 17, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.25),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$scope · данные на ${DateFormat('HH:mm').format(d.loadedAt)}',
                      style: TextStyle(color: c.muted, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              WebChip(label: 'Обновить', icon: LucideIcons.refreshCw, onTap: onReload),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            buildBrief(d).join(' '),
            key: const Key('today-brief'),
            style: TextStyle(color: c.heading, fontSize: 19, fontWeight: FontWeight.w500, height: 1.34, letterSpacing: -0.42),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final (label, section) in chips) WebChip(label: label, onTap: () => onOpenSection(section))],
          ),
          if (s != null || sections.contains(Section.processing)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: s != null
                  ? WebMoreLink(label: 'Вся сводка', onTap: () => onOpenSection(Section.analytics))
                  : WebMoreLink(label: 'Все входящие', onTap: () => onOpenSection(Section.processing)),
            ),
          ],
        ],
      ),
    );
  }
}

/// «Ждёт вас»: одно самое срочное дело и действие по нему (FocusCard в вебе).
class _FocusCard extends StatefulWidget {
  const _FocusCard({required this.data, required this.me, required this.onOpen, required this.onReload, required this.onOpenSection});

  final TodayData data;
  final Me me;
  final ValueChanged<int> onOpen;
  final Future<void> Function() onReload;
  final ValueChanged<Section> onOpenSection;

  @override
  State<_FocusCard> createState() => _FocusCardState();
}

class _FocusCardState extends State<_FocusCard> {
  bool _busy = false;

  Future<void> _take(AppealListItem top) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await SessionScope.read(context).api.appealActions.takeAppeal(top.id);
      messenger.showSnackBar(SnackBar(content: Text('${top.number} взято на рассмотрение')));
      HapticFeedback.mediumImpact();
      await widget.onReload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(AppError.from(e).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final session = SessionScope.of(context);
    final d = widget.data;
    final pool = [...d.assigned.where((a) => a.status != AppealStatus.awaitingInfo), ...d.awaitingMe, ...d.unassigned];
    final seen = <int>{};
    final items = [
      for (final a in pool)
        if (seen.add(a.id)) a,
    ];
    if (items.isEmpty) {
      final requests = d.accessRequests ?? 0;
      return WebCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WebCardHead(title: 'Ждёт вас'),
            if (requests > 0)
              _FocusItem(
                children: [
                  Text(
                    '$requests ${plural(requests, ('заявка', 'заявки', 'заявок'))} на доступ',
                    style: TextStyle(color: c.heading, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  Text('Люди не могут войти, пока вы не решите.', style: TextStyle(color: c.muted, fontSize: 13)),
                  WebButton(label: 'Открыть заявки', onPressed: () => widget.onOpenSection(Section.settings)),
                ],
              )
            else
              const _Quiet(title: 'Всё разобрано', text: 'Новые дела появятся здесь.'),
          ],
        ),
      );
    }
    final top = items.first;
    final asAuthor = d.awaitingMe.any((a) => a.id == top.id) && !d.assigned.any((a) => a.id == top.id);
    final noAssignee = top.assignee == null;
    final canTake = top.status == AppealStatus.new_ && top.assignee?.id == widget.me.id;
    final hint = asAuthor
        ? 'Ответственный задал вопрос. Пока нет ответа, работа стоит.'
        : noAssignee
        ? 'Ответственного нет: выберите, кто ответит.'
        : _waiting(top)
        ? 'Первый ответ: ${timeLeftLabel(top.firstResponseDueAt!, d.loadedAt)}'
        : session.statusLabel(top.status);
    final danger = top.dueState == DueState.overdue && !asAuthor;
    final all = asAuthor ? Section.myAppeals : Section.processing;
    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebCardHead(
            title: 'Ждёт вас',
            count: items.length,
            action: WebChip(label: 'Все', onTap: () => widget.onOpenSection(all)),
          ),
          _FocusItem(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TypeIcon(top.type, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          top.summary ?? 'Без краткой сути',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.heading, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, letterSpacing: -0.16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [top.number, session.typeLabel(top.type), if (top.author != null && !asAuthor) top.author!.fullName].join(' · '),
                          style: TextStyle(color: c.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: danger ? c.dangerBg : c.surface2, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  hint,
                  style: TextStyle(
                    color: danger ? c.danger : Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canTake)
                Row(
                  children: [
                    Expanded(
                      child: WebButton(label: _busy ? 'Берём…' : 'Взять в работу', busy: _busy, onPressed: () => _take(top)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: WebButton(kind: WebButtonKind.soft, label: 'Открыть', onPressed: () => widget.onOpen(top.id)),
                    ),
                  ],
                )
              else
                WebButton(
                  label: asAuthor
                      ? 'Ответить'
                      : noAssignee
                      ? 'Назначить'
                      : 'Открыть',
                  onPressed: () => widget.onOpen(top.id),
                ),
            ],
          ),
          if (items.length > 1)
            GestureDetector(
              onTap: () => widget.onOpenSection(all),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ещё ${items.length - 1}: ${items.skip(1).take(3).map((a) => a.number).join(', ')}',
                        style: TextStyle(color: c.muted, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(LucideIcons.arrowRight, size: 16, color: c.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.focus__item`: поверхность, радиус 18, отступ 16, промежутки 12.
class _FocusItem extends StatelessWidget {
  const _FocusItem({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: ModusColors.of(context).surface, borderRadius: BorderRadius.circular(Web.rTile)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 12), children[i]],
      ],
    ),
  );
}

/// `.quiet`: значок-галочка в круге, заголовок и пояснение.
class _Quiet extends StatelessWidget {
  const _Quiet({required this.title, this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.successBg, shape: BoxShape.circle),
            child: Icon(LucideIcons.check, size: 18, color: c.success),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: c.heading, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (text != null) Text(text!, style: TextStyle(color: c.muted, fontSize: 13.5, height: 1.45)),
        ],
      ),
    );
  }
}

class _DiscussionsCard extends StatelessWidget {
  const _DiscussionsCard({required this.data, required this.onOpenSection});

  final TodayData data;
  final ValueChanged<Section> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final d = data;
    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebCardHead(
            title: 'Обсуждения',
            sub: d.discussionsTotal > 0 ? 'Идеи, по которым собирают мнения' : null,
            count: d.discussionsTotal,
            action: WebChip(label: 'Все', onTap: () => onOpenSection(Section.feed)),
          ),
          if (d.discussions.isEmpty)
            const _Quiet(title: 'Открытых обсуждений нет', text: 'Когда идею вынесут на общее обсуждение, она появится здесь.'),
          for (var i = 0; i < d.discussions.take(3).length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.palette.border),
            InkWell(
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DiscussionScreen(discussionId: d.discussions[i].id))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.discussions[i].publicText,
                      style: TextStyle(color: c.heading, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'за ${d.discussions[i].votesFor} · против ${d.discussions[i].votesAgainst} · до ${DateFormat('d MMM., HH:mm', 'ru').format(d.discussions[i].deadline.toUtc().add(const Duration(hours: 5)))}',
                      style: TextStyle(color: c.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _PillAction(
                      primary: d.discussions[i].canVote && d.discussions[i].myVote == null,
                      label: d.discussions[i].canVote && d.discussions[i].myVote == null ? 'Голосовать' : 'Открыть',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.pill-action`: маленькая пилюля 13 / 600 на --surface-3 или --primary.
class _PillAction extends StatelessWidget {
  const _PillAction({required this.label, this.primary = false});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: primary ? scheme.primary : c.extra.surface3, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: TextStyle(color: primary ? scheme.onPrimary : c.heading, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
      ),
    );
  }
}

/// «Сделано»: что предложили и что сделали (ImplementedCard в вебе).
class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.items, required this.onOpenSection});

  final List<FeedItem> items;
  final ValueChanged<Section> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebCardHead(
            title: 'Сделано',
            sub: 'По предложениям сотрудников',
            action: WebChip(label: 'Вся лента', onTap: () => onOpenSection(Section.feed)),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Web.rTile)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[i].publicSummary,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.heading, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(LucideIcons.check, size: 16, color: c.success),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items[i].result,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.5, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: Web.gap),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(Web.rCard)),
    );
    return Column(key: const Key('today-skeleton'), children: [block(240), block(260), block(180)]);
  }
}
