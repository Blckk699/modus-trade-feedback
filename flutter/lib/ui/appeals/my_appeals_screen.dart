import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../format.dart';
import 'appeal_screen.dart';
import 'badges.dart';
import 'rows.dart';
import 'new_appeal_screen.dart';
import '../home/role_switch.dart';

/// «Мои обращения»: `GET /appeals?scope=mine&sort=created_desc`, по 20 на страницу.
class MyAppealsScreen extends StatefulWidget {
  const MyAppealsScreen({super.key});

  static const pageSize = 20;

  @override
  State<MyAppealsScreen> createState() => _MyAppealsScreenState();
}

class _MyAppealsScreenState extends State<MyAppealsScreen> {
  final List<AppealListItem> _items = [];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<AppealPage> _fetch(int page) async {
    try {
      final result = await SessionScope.read(context).api.appeals.listAppeals(
            scope: AppealScope.mine,
            sort: 'created_desc',
            page: page,
            pageSize: MyAppealsScreen.pageSize,
          );
      if (result == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      return result;
    } catch (e) {
      throw AppError.from(e);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _page = 1;
      });
    } on AppError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final page = await _fetch(_page + 1);
      if (!mounted) return;
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

  Future<void> _openNew() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewAppealScreen()),
    );
    if (created == true) _reload();
  }

  Future<void> _open(AppealListItem item) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AppealScreen(appealId: item.id)));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои обращения'), actions: const [RoleSwitchAction()]),
      floatingActionButton: FloatingActionButton(
        key: const Key('new-appeal'),
        tooltip: 'Подать обращение',
        onPressed: _openNew,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: RefreshIndicator(onRefresh: _reload, child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) {
      return _Centered(children: [
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _reload, child: const Text('Повторить')),
      ]);
    }
    if (_items.isEmpty) {
      return const _Centered(children: [
        Text('Вы ещё не подавали обращений.', textAlign: TextAlign.center),
        SizedBox(height: 8),
        Text(
          'Расскажите о проблеме, предложите улучшение или отметьте то, что работает хорошо.',
          textAlign: TextAlign.center,
        ),
      ]);
    }
    final hasMore = _items.length < _total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        RowsCard(children: [
          for (final item in _items) AppealRow(item: item, onTap: () => _open(item)),
        ]),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(_loadingMore ? 'Загружаем…' : 'Показать ещё'),
              ),
              if (_moreError != null) Text(_moreError!, style: TextStyle(color: theme.colorScheme.error)),
            ]),
          ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});

  final List<Widget> children;

  // ListView, чтобы работал pull-to-refresh и на пустом экране.
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
        children: children,
      );
}

/// Строка списка обращений как в вебе: значок типа, суть, «номер · тип · дата», статус и срок.
class AppealRow extends StatelessWidget {
  const AppealRow({super.key, required this.item, required this.onTap});

  final AppealListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return KeyedSubtree(
      key: Key('appeal-${item.id}'),
      child: WebRow(
        type: item.type,
        title: item.summary ?? 'Без краткой сути',
        meta: [
          item.number,
          session.typeLabel(item.type),
          formatDate(item.createdAt),
          if (item.mergedInto != null) 'присоединено к ${item.mergedInto!.number}',
        ].join(' · '),
        unread: item.hasUnread,
        unreadKey: Key('unread-${item.id}'),
        onTap: onTap,
        badges: [
          StatusBadge(item.status),
          if (item.status != AppealStatus.closed) DueBadge(state: item.dueState, dueAt: item.firstResponseDueAt),
        ],
      ),
    );
  }
}
