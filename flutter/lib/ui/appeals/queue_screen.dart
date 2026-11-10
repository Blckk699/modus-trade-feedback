import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/queue_scopes.dart';
import 'appeal_screen.dart';
import 'badges.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обработка'),
        actions: [
          IconButton(
            key: const Key('queue-filters'),
            tooltip: 'Фильтры',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: active > 0,
              label: Text('$active'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
        bottom: scopes.length > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(children: [
                    for (final s in scopes)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: Key('scope-${s.toJson()}'),
                          label: Text(scopeLabel(s)),
                          selected: _filters.scope == s,
                          onSelected: (_) => _apply(_filters.copyWith(scope: s)),
                        ),
                      ),
                  ]),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(onRefresh: _reload, child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(padding: const EdgeInsets.fromLTRB(32, 96, 32, 32), children: [
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _reload, child: const Text('Повторить'))),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(padding: const EdgeInsets.fromLTRB(32, 96, 32, 32), children: const [
        Text('Обращений нет.', textAlign: TextAlign.center),
      ]);
    }
    final hasMore = _items.length < _total;
    return ListView.separated(
      itemCount: _items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(_loadingMore ? 'Загружаем…' : 'Показать ещё'),
              ),
              if (_moreError != null) Text(_moreError!, style: TextStyle(color: theme.colorScheme.error)),
            ]),
          );
        }
        final item = _items[index];
        return QueueRow(item: item, now: _now, onTap: () => _open(item));
      },
    );
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
    final scheme = theme.colorScheme;
    final overdue = item.dueState == DueState.overdue;
    final due = item.firstResponseDueAt;
    final waitingAnswer = due != null && item.dueState != DueState.answered && item.dueState != DueState.noDeadline;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Material(
      color: overdue ? scheme.errorContainer.withValues(alpha: 0.35) : Colors.transparent,
      child: InkWell(
        key: Key('queue-${item.id}'),
        onTap: onTap,
        child: Container(
          decoration: overdue ? BoxDecoration(border: Border(left: BorderSide(color: scheme.error, width: 4))) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(item.number, style: theme.textTheme.titleSmall),
              if (item.hasUnread) ...[const SizedBox(width: 6), const Badge(smallSize: 8)],
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${session.typeLabel(item.type)} · ${session.priorityLabel(item.priority)}',
                  style: muted,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (waitingAnswer)
                Text(
                  timeLeftLabel(due, now),
                  key: Key('time-left-${item.id}'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: overdue ? scheme.error : scheme.onSurfaceVariant,
                    fontWeight: overdue ? FontWeight.w600 : null,
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            Text(item.summary ?? 'Без краткой сути', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              StatusBadge(item.status),
              if (item.status != AppealStatus.closed) DueBadge(state: item.dueState, dueAt: due),
              if (item.participantsCount > 1) Text('Сообщили: ${item.participantsCount}', style: muted),
              if (item.assignee != null) Text(item.assignee!.fullName, style: muted),
            ]),
          ]),
        ),
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
          Text('Фильтры', style: Theme.of(context).textTheme.titleLarge),
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
