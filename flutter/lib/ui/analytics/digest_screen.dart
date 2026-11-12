import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../format.dart';
import '../appeals/appeal_screen.dart';
import '../appeals/badges.dart';
import '../../theme/modus_theme.dart';
import '../home/role_switch.dart';
import '../sheet_header.dart';

/// «12 ч», «1,5 д» — как `formatHours` в вебе.
String formatHours(double h) {
  String num(double v) {
    final s = v.toStringAsFixed(1);
    return (s.endsWith('.0') ? s.substring(0, s.length - 2) : s).replaceAll('.', ',');
  }

  return h < 24 ? '${num(h)} ч' : '${num(h / 24)} д';
}

class DigestFilters {
  const DigestFilters({this.departmentId, this.categoryId, this.status, this.due});

  final int? departmentId;
  final int? categoryId;
  final AppealStatus? status;
  final DueFilter? due;

  int get activeCount => [departmentId, categoryId, status, due].where((v) => v != null).length;
}

/// Сводка (истории 53, 56–58, 61): собственник — по компании с фильтром подразделения,
/// руководитель — по своему подразделению (охват решает бэкенд по `analytics_scope`).
class DigestScreen extends StatefulWidget {
  const DigestScreen({super.key});

  @override
  State<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<DigestScreen> {
  DigestFilters _filters = const DigestFilters();
  AnalyticsSummary? _data;
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final f = _filters;
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await SessionScope.read(context).api.analytics.getAnalyticsSummary(
            departmentId: f.departmentId,
            categoryId: f.categoryId,
            status: f.status == null ? null : [f.status!],
            due: f.due,
          );
      if (data == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      if (mounted && request == _request) setState(() => _data = data);
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _openFilters() async {
    final company = SessionScope.read(context).me.permissions.analyticsScope == PermissionsAnalyticsScopeEnum.company;
    final result = await showModalBottomSheet<DigestFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FiltersSheet(initial: _filters, company: company),
    );
    if (result != null) {
      setState(() {
        _filters = result;
        _data = null;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final title = data?.department != null ? 'Сводка · ${data!.department!.name}' : 'Сводка по компании';
    final active = _filters.activeCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          const RoleSwitchAction(),
          IconButton(
            key: const Key('digest-filters'),
            tooltip: 'Фильтры',
            onPressed: _openFilters,
            icon: Badge(isLabelVisible: active > 0, label: Text('$active'), child: const Icon(Icons.filter_list)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: data == null
                  ? ListView(padding: const EdgeInsets.all(32), children: [
                      Text(_error ?? '', textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 12),
                      Center(child: OutlinedButton(onPressed: _load, child: const Text('Повторить'))),
                    ])
                  : _SummaryView(data: data),
            ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.data});

  final AnalyticsSummary data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final session = SessionScope.of(context);
    final theme = Theme.of(context);
    final avg = d.avgFirstResponseHours;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Обновлено ${formatDateTime(d.generatedAt)}', style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            _Tile(key: const Key('tile-total'), label: 'Всего обращений', value: '${d.total}'),
            _Tile(
              key: const Key('tile-closed'),
              label: 'Доля закрытых',
              value: '${(d.closedShare * 100).round()}%',
              hint: '${d.closedCount} из ${d.total}',
            ),
            _Tile(
              key: const Key('tile-avg'),
              label: 'Среднее время первого ответа',
              value: avg == null ? '—' : formatHours(avg),
              hint: avg == null ? 'Ещё нет ответов' : null,
            ),
            _Tile(
              key: const Key('tile-overdue'),
              label: 'Просрочено',
              value: '${d.overdue.length}',
              danger: d.overdue.isNotEmpty,
            ),
          ],
        ),
        _Block(
          key: const Key('block-new'),
          title: 'Новое за сутки',
          count: d.newLast24h.length,
          child: _RefList(items: d.newLast24h, empty: 'Новых обращений нет.'),
        ),
        _Block(
          key: const Key('block-stuck'),
          title: 'Зависло',
          count: d.stuck.length,
          danger: d.stuck.isNotEmpty,
          child: _StuckList(items: d.stuck, empty: 'Зависших обращений нет.'),
        ),
        _Block(
          key: const Key('block-closed'),
          title: 'Закрыто за неделю',
          count: d.closedLastWeek.length,
          child: _RefList(items: d.closedLastWeek, empty: 'За неделю ничего не закрыто.', showStatus: true),
        ),
        _Block(
          key: const Key('block-repeated'),
          title: 'Повторяющиеся темы',
          count: d.repeatedTopics.length,
          child: d.repeatedTopics.isEmpty
              ? const _Empty('Повторов нет.')
              : Column(children: [
                  for (final t in d.repeatedTopics)
                    _AppealTile(appeal: t.appeal, trailing: Text('Сообщили: ${t.participantsCount}')),
                ]),
        ),
        _Block(
          title: 'По типам',
          child: _Bars(rows: [for (final r in d.byType) (session.typeLabel(r.type), r.count)]),
        ),
        _Block(
          title: 'По статусам',
          child: _Bars(rows: [for (final r in d.byStatus) (session.statusLabel(r.status), r.count)]),
        ),
        _Block(
          key: const Key('block-categories'),
          title: 'По категориям',
          child: _Bars(rows: [for (final r in d.byCategory) (r.category?.name ?? 'Без категории', r.count)]),
        ),
        _Block(
          key: const Key('block-overdue'),
          title: 'Просроченные',
          count: d.overdue.length,
          danger: d.overdue.isNotEmpty,
          child: _StuckList(items: d.overdue, empty: 'Просроченных нет.'),
        ),
        if (d.assigneeLoad.isNotEmpty)
          _Block(
            key: const Key('block-load'),
            title: 'Нагрузка по ответственным',
            child: Column(children: [
              for (final r in d.assigneeLoad)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(r.assignee.fullName),
                  subtitle: Text([
                    if (r.assignee.department != null) r.assignee.department!.name,
                    'первый ответ ${r.avgFirstResponseHours == null ? '—' : formatHours(r.avgFirstResponseHours!)}',
                  ].join(' · ')),
                  trailing: Text.rich(TextSpan(children: [
                    TextSpan(text: 'открыто ${r.openCount}'),
                    if (r.overdueCount > 0)
                      TextSpan(
                        text: ' · просрочено ${r.overdueCount}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ])),
                ),
            ]),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.label, required this.value, this.hint, this.danger = false});

  final String label;
  final String value;
  final String? hint;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(ModusRadius.lg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        Text(value,
            style: theme.textTheme.headlineSmall?.copyWith(color: danger ? theme.colorScheme.error : null)),
        if (hint != null) Text(hint!, style: theme.textTheme.labelSmall),
      ]),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({super.key, required this.title, required this.child, this.count, this.danger = false});

  final String title;
  final int? count;
  final bool danger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: title),
          if (count != null)
            TextSpan(text: '  $count', style: TextStyle(color: danger ? theme.colorScheme.error : theme.colorScheme.outline)),
        ]), style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        child,
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

/// Строка-ссылка на обращение: из любого блока открывается карточка.
class _AppealTile extends StatelessWidget {
  const _AppealTile({required this.appeal, this.subtitle, this.trailing});

  final AppealRef appeal;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
        key: Key('digest-appeal-${appeal.id}'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text('${appeal.number} · ${appeal.summary ?? 'Без краткой сути'}', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle,
        trailing: trailing,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: appeal.id))),
      );
}

class _RefList extends StatelessWidget {
  const _RefList({required this.items, required this.empty, this.showStatus = false});

  final List<AppealRef> items;
  final String empty;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Empty(empty);
    return Column(children: [
      for (final a in items) _AppealTile(appeal: a, trailing: showStatus ? StatusBadge(a.status) : null),
    ]);
  }
}

class _StuckList extends StatelessWidget {
  const _StuckList({required this.items, required this.empty});

  final List<StuckAppeal> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Empty(empty);
    final error = Theme.of(context).colorScheme.error;
    return Column(children: [
      for (final s in items)
        _AppealTile(
          appeal: s.appeal,
          subtitle: Text.rich(TextSpan(children: [
            TextSpan(text: '${s.assignee?.fullName ?? 'без ответственного'} · '),
            TextSpan(text: 'просрочено ${s.daysOverdue} раб. дн.', style: TextStyle(color: error)),
          ])),
        ),
    ]);
  }
}

/// Горизонтальные полосы одной серии: длина — количество, подпись и число текстом.
class _Bars extends StatelessWidget {
  const _Bars({required this.rows});

  final List<(String, int)> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _Empty('Нет данных.');
    final theme = Theme.of(context);
    final max = rows.map((r) => r.$2).fold<int>(1, (a, b) => b > a ? b : a);
    return Column(children: [
      for (final (label, count) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodySmall, maxLines: 2)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ModusRadius.sm),
                child: LinearProgressIndicator(
                  value: count / max,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 32, child: Text('$count', textAlign: TextAlign.right)),
          ]),
        ),
    ]);
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial, required this.company});

  final DigestFilters initial;
  final bool company;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late int? _department = widget.initial.departmentId;
  late int? _category = widget.initial.categoryId;
  late AppealStatus? _status = widget.initial.status;
  late DueFilter? _due = widget.initial.due;
  late final Future<List<Category>> _categories;
  Future<List<Department>>? _departments;

  @override
  void initState() {
    super.initState();
    final api = SessionScope.read(context).api.dictionaries;
    _categories = api.listCategories().then((v) => v ?? const <Category>[]);
    if (widget.company) _departments = api.listDepartments().then((v) => v ?? const <Department>[]);
  }

  @override
  Widget build(BuildContext context) {
    final dict = SessionScope.of(context).dictionaries;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SheetHeader('Фильтры'),
          const SizedBox(height: 16),
          if (_departments != null) ...[
            FutureBuilder<List<Department>>(
              future: _departments,
              builder: (context, s) => DropdownButtonFormField<int?>(
                // Пока список грузится, выбранного пункта ещё нет — без значения, затем поле пересоздаётся.
                key: Key('digest-department-${s.hasData}'),
                initialValue: s.hasData ? _department : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Подразделение', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Вся компания')),
                  for (final d in s.data ?? const <Department>[]) DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setState(() => _department = v),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FutureBuilder<List<Category>>(
            future: _categories,
            builder: (context, s) => DropdownButtonFormField<int?>(
              // Пока список грузится, выбранного пункта ещё нет — без значения, затем поле пересоздаётся.
              key: Key('digest-category-${s.hasData}'),
              initialValue: s.hasData ? _category : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Все')),
                for (final c in s.data ?? const <Category>[])
                  DropdownMenuItem<int?>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppealStatus?>(
            key: const Key('digest-status'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Статус', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<AppealStatus?>(value: null, child: Text('Любой')),
              for (final s in dict?.statuses ?? const <DictionariesStatusesInner>[])
                if (AppealStatus.fromJson(s.code) != null)
                  DropdownMenuItem<AppealStatus?>(value: AppealStatus.fromJson(s.code), child: Text(s.label)),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DueFilter?>(
            key: const Key('digest-due'),
            initialValue: _due,
            decoration: const InputDecoration(labelText: 'Срок', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<DueFilter?>(value: null, child: Text('Любой')),
              for (final d in dict?.dueFilters ?? const <LabeledCode>[])
                if (DueFilter.fromJson(d.code) != null)
                  DropdownMenuItem<DueFilter?>(value: DueFilter.fromJson(d.code), child: Text(d.label)),
            ],
            onChanged: (v) => setState(() => _due = v),
          ),
          const SizedBox(height: 16),
          Row(children: [
            TextButton(
              onPressed: () => Navigator.pop(context, const DigestFilters()),
              child: const Text('Сбросить'),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('digest-apply'),
              onPressed: () => Navigator.pop(
                context,
                DigestFilters(departmentId: _department, categoryId: _category, status: _status, due: _due),
              ),
              child: const Text('Показать'),
            ),
          ]),
        ]),
      ),
    );
  }
}
