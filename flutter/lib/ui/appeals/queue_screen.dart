import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/queue_scopes.dart';
import 'appeal_screen.dart';
import 'badges.dart';
import '../web/web_ui.dart';
import 'rows.dart';
import '../../theme/modus_theme.dart';
import '../home/role_switch.dart';
import '../sheet_header.dart';

/// Значение фильтра статуса: все открытые, любой или конкретный статус.
sealed class StatusFilter {
  const StatusFilter();
}

class OpenStatuses extends StatusFilter {
  const OpenStatuses();
}

class AnyStatus extends StatusFilter {
  const AnyStatus();
}

class OneStatus extends StatusFilter {
  const OneStatus(this.status);
  final AppealStatus status;

  @override
  bool operator ==(Object other) => other is OneStatus && other.status == status;

  @override
  int get hashCode => status.hashCode;
}

class QueueFilters {
  const QueueFilters({
    required this.scope,
    this.status = const OpenStatuses(),
    this.categoryId,
    this.departmentId,
    this.due,
  });

  final AppealScope scope;
  final StatusFilter status;
  final int? categoryId;
  final int? departmentId;
  final DueFilter? due;

  /// Сколько фильтров отличается от значений по умолчанию (для подписи кнопки).
  int get activeCount =>
      (status is OpenStatuses ? 0 : 1) +
      (categoryId == null ? 0 : 1) +
      (departmentId == null ? 0 : 1) +
      (due == null ? 0 : 1);

  QueueFilters copyWith({
    AppealScope? scope,
    StatusFilter? status,
    int? Function()? categoryId,
    int? Function()? departmentId,
    DueFilter? Function()? due,
  }) =>
      QueueFilters(
        scope: scope ?? this.scope,
        status: status ?? this.status,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        departmentId: departmentId != null ? departmentId() : this.departmentId,
        due: due != null ? due() : this.due,
      );
}

/// Очередь обработки: `GET /appeals?scope=…&sort=due_asc` с фильтрами, по 30 на страницу.
class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  static const pageSize = 30;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late QueueFilters _filters;
  final List<AppealListItem> _items = [];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  DateTime _now = DateTime.now();

  /// Номер запроса — ответы на устаревшие фильтры отбрасываем.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    final me = SessionScope.read(context).me;
    _filters = QueueFilters(scope: defaultQueueScope(me) ?? AppealScope.assigned);
    _reload();
  }

  Future<AppealPage> _fetch(int page) async {
    final f = _filters;
    try {
      final result = await SessionScope.read(context).api.appeals.listAppeals(
            scope: f.scope,
            sort: 'due_asc',
            status: switch (f.status) {
              OpenStatuses() => openStatuses,
              AnyStatus() => null,
              OneStatus(:final status) => [status],
            },
            categoryId: f.categoryId,
            departmentId: f.departmentId,
            due: f.due,
            page: page,
            pageSize: QueueScreen.pageSize,
          );
      if (result == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      return result;
    } catch (e) {
      throw AppError.from(e);
    }
  }

  Future<void> _reload() async {
    final request = ++_request;
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      if (!mounted || request != _request) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _page = 1;
        _now = DateTime.now();
      });
    } on AppError catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _error = e.message;
          _items.clear();
        });
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final request = _request;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final page = await _fetch(_page + 1);
      if (!mounted || request != _request) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _page += 1;
      });
    } on AppError catch (e) {
      if (mounted) setState(() => _moreError = e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _apply(QueueFilters filters) {
    setState(() {
      _filters = filters;
      _items.clear();
    });
    _reload();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<QueueFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FiltersSheet(initial: _filters),
    );
    if (result != null) _apply(result);
  }

  Future<void> _open(AppealListItem item) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: item.id)));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).me;
    final scopes = queueScopes(me);
    final active = _filters.activeCount;
    final c = ModusColors.of(context);
    return Scaffold(
      body: WebScrollPage(
        title: 'Входящие',
        onRefresh: _reload,
        tools: [
          ToolButton(
            key: const Key('queue-filters'),
            icon: LucideIcons.slidersHorizontal,
            tooltip: 'Фильтры',
            badge: active,
            onTap: _openFilters,
          ),
          const RoleSwitchAction(),
        ],
        children: [
          if (scopes.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: c.extra.surface3, borderRadius: BorderRadius.circular(99)),
                child: Row(children: [
                  for (final sc in scopes)
                    GestureDetector(
                      key: Key('scope-${sc.toJson()}'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _apply(_filters.copyWith(scope: sc));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _filters.scope == sc ? c.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: _filters.scope == sc ? c.extra.shadowRaised : null,
                        ),
                        child: Text(
                          scopeLabel(sc),
                          style: TextStyle(
                            color: _filters.scope == sc ? c.heading : c.muted,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: Web.gap),
          ],
          ..._children(context),
        ],
      ),
    );
  }

  List<Widget> _children(BuildContext context) {
    final c = ModusColors.of(context);
    if (_loading) {
      return const [Padding(padding: EdgeInsets.only(top: 64), child: Center(child: CircularProgressIndicator.adaptive()))];
    }
    if (_error != null) {
      return [
        const SizedBox(height: 48),
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.danger)),
        const SizedBox(height: 12),
        Center(child: WebButton(kind: WebButtonKind.soft, expand: false, label: 'Повторить', onPressed: _reload)),
      ];
    }
    if (_items.isEmpty) {
      return [
        WebCard(
          child: Column(children: [
            Icon(LucideIcons.inbox, size: 28, color: c.faint),
            const SizedBox(height: 8),
            Text('Обращений нет', style: TextStyle(color: c.heading, fontSize: 16, fontWeight: FontWeight.w600)),
            if (_filters.activeCount > 0) ...[
              const SizedBox(height: 4),
              Text('Попробуйте снять фильтры.', style: TextStyle(color: c.muted)),
            ],
          ]),
        ),
      ];
    }
    final hasMore = _items.length < _total;
    return [
      RowsCard(children: [
        for (final item in _items) QueueRow(item: item, now: _now, onTap: () => _open(item)),
      ]),
      if (hasMore)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            WebButton(
              kind: WebButtonKind.soft,
              label: _loadingMore ? 'Загружаем…' : 'Показать ещё',
              onPressed: _loadingMore ? null : _loadMore,
            ),
            if (_moreError != null) Text(_moreError!, style: TextStyle(color: c.danger)),
          ]),
        ),
    ];
  }
}

/// Строка очереди: номер, тип и приоритет, сколько осталось до срока, суть, статус, срок.
/// Просроченные выделены цветом.
class QueueRow extends StatelessWidget {
  const QueueRow({super.key, required this.item, required this.now, required this.onTap});

  final AppealListItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    final overdue = item.dueState == DueState.overdue && item.status != AppealStatus.closed;
    final due = item.firstResponseDueAt;
    // Правило 6: срок в строке — только когда он важен (просрочен или истекает).
    final waitingAnswer = due != null &&
        (item.dueState == DueState.overdue || item.dueState == DueState.dueSoon) &&
        item.status != AppealStatus.closed;
    return KeyedSubtree(
      key: Key('queue-${item.id}'),
      child: WebRow(
        type: item.type,
        title: item.summary ?? 'Без краткой сути',
        meta: [
          item.number,
          session.typeLabel(item.type),
          if (item.category != null) item.category!.name,
          item.assignee?.fullName ?? 'без ответственного',
        ].join(' · '),
        unread: item.hasUnread,
        overdue: overdue,
        onTap: onTap,
        badges: [
          StatusBadge(item.status),
          if (waitingAnswer)
            Text(
              timeLeftLabel(due, now),
              key: Key('time-left-${item.id}'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: overdue ? c.danger : item.dueState == DueState.dueSoon ? c.warn : c.muted,
              ),
            ),
          if (item.participantsCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: c.peopleBg, borderRadius: BorderRadius.circular(99)),
              child: Text('Сообщили: ${item.participantsCount}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.people)),
            ),
        ],
      ),
    );
  }
}

/// Фильтры очереди: статус, срок, категория, подразделение (только тем, кто видит все обращения).
class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final QueueFilters initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late QueueFilters _f = widget.initial;
  late Future<List<Category>> _categories;
  Future<List<Department>>? _departments;

  @override
  void initState() {
    super.initState();
    final session = SessionScope.read(context);
    _categories = session.api.dictionaries.listCategories().then((v) => v ?? const <Category>[]);
    if (session.me.permissions.canViewAllAppeals) {
      _departments = session.api.dictionaries.listDepartments().then((v) => v ?? const <Department>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final dict = session.dictionaries;
    final statusItems = <DropdownMenuItem<StatusFilter>>[
      const DropdownMenuItem(value: OpenStatuses(), child: Text('Все открытые')),
      for (final s in dict?.statuses ?? const <DictionariesStatusesInner>[])
        if (AppealStatus.fromJson(s.code) != null)
          DropdownMenuItem(value: OneStatus(AppealStatus.fromJson(s.code)!), child: Text(s.label)),
      const DropdownMenuItem(value: AnyStatus(), child: Text('Любой')),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SheetHeader('Фильтры'),
          const SizedBox(height: 16),
          DropdownButtonFormField<StatusFilter>(
            key: const Key('filter-status'),
            initialValue: _f.status,
            decoration: const InputDecoration(labelText: 'Статус', border: OutlineInputBorder()),
            items: statusItems,
            onChanged: (v) => setState(() => _f = _f.copyWith(status: v)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DueFilter?>(
            key: const Key('filter-due'),
            initialValue: _f.due,
            decoration: const InputDecoration(labelText: 'Срок', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<DueFilter?>(value: null, child: Text('Любой')),
              for (final d in dict?.dueFilters ?? const <LabeledCode>[])
                if (DueFilter.fromJson(d.code) != null)
                  DropdownMenuItem<DueFilter?>(value: DueFilter.fromJson(d.code), child: Text(d.label)),
            ],
            onChanged: (v) => setState(() => _f = _f.copyWith(due: () => v)),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Category>>(
            future: _categories,
            builder: (context, s) => DropdownButtonFormField<int?>(
              // Пока список грузится, выбранного пункта ещё нет — без значения, затем поле пересоздаётся.
              key: Key('filter-category-${s.hasData}'),
              initialValue: s.hasData ? _f.categoryId : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Все')),
                for (final c in s.data ?? const <Category>[])
                  DropdownMenuItem<int?>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _f = _f.copyWith(categoryId: () => v)),
            ),
          ),
          if (_departments != null) ...[
            const SizedBox(height: 12),
            FutureBuilder<List<Department>>(
              future: _departments,
              builder: (context, s) => DropdownButtonFormField<int?>(
                // Пока список грузится, выбранного пункта ещё нет — без значения, затем поле пересоздаётся.
                key: Key('filter-department-${s.hasData}'),
                initialValue: s.hasData ? _f.departmentId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Подразделение', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Все')),
                  for (final d in s.data ?? const <Department>[])
                    DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() => _f = _f.copyWith(departmentId: () => v)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            TextButton(
              key: const Key('filters-reset'),
              onPressed: () => Navigator.pop(context, QueueFilters(scope: _f.scope)),
              child: const Text('Сбросить'),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('filters-apply'),
              onPressed: () => Navigator.pop(context, _f),
              child: const Text('Показать'),
            ),
          ]),
        ]),
      ),
    );
  }
}
