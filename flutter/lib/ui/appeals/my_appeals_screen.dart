import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../format.dart';
import 'appeal_screen.dart';
import 'badges.dart';
import '../web/web_ui.dart';
import '../../theme/modus_theme.dart';
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
      body: Stack(children: [
        WebScrollPage(
          title: 'Мои обращения',
          tools: const [RoleSwitchAction()],
          onRefresh: _reload,
          children: _children(context),
        ),
        // В body с extendBody нижний отступ MediaQuery равен высоте панели.
        Positioned(
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: WebFab(key: const Key('new-appeal'), onTap: _openNew),
        ),
      ]),
    );
  }

  List<Widget> _children(BuildContext context) {
    final c = ModusColors.of(context);
    if (_loading) {
      return const [Padding(padding: EdgeInsets.only(top: 64), child: Center(child: CircularProgressIndicator.adaptive()))];
    }
    if (_error != null && _items.isEmpty) {
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
            const SizedBox(height: 8),
            Text('Вы ещё не подавали обращений',
                textAlign: TextAlign.center, style: TextStyle(color: c.heading, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Расскажите о проблеме, предложите улучшение или отметьте то, что работает хорошо.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
            const SizedBox(height: 16),
            WebButton(kind: WebButtonKind.accent, label: 'Подать обращение', onPressed: _openNew),
          ]),
        ),
      ];
    }
    final hasMore = _items.length < _total;
    return [
      RowsCard(children: [
        for (final item in _items) AppealRow(item: item, onTap: () => _open(item)),
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
          // Срок — только когда он важен: просрочен или вот-вот истечёт.
          if (item.status != AppealStatus.closed &&
              (item.dueState == DueState.overdue || item.dueState == DueState.dueSoon))
            Text(
              item.dueState == DueState.overdue ? 'ответ задерживается' : 'ответ скоро',
              key: Key('due-${item.id}'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: item.dueState == DueState.overdue ? ModusColors.of(context).danger : ModusColors.of(context).warn,
              ),
            ),
        ],
      ),
    );
  }
}
