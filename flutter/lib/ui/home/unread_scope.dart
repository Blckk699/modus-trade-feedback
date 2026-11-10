import 'package:flutter/widgets.dart';

import '../../app.dart';
import '../../session/session_controller.dart';
import '../../session/unread_controller.dart';

/// Счётчик непрочитанного для экранов внутри главного экрана.
class UnreadScope extends InheritedNotifier<UnreadController> {
  const UnreadScope({super.key, required UnreadController controller, required super.child})
      : super(notifier: controller);

  static UnreadController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UnreadScope>()!.notifier!;

  /// Без подписки; null вне главного экрана (например, в тестах отдельных экранов).
  static UnreadController? maybeRead(BuildContext context) =>
      context.getInheritedWidgetOfExactType<UnreadScope>()?.notifier;
}

/// Держит счётчик, пока пользователь вошёл: создаётся при входе, закрывается при выходе.
/// Стоит в `MaterialApp.builder`, поэтому виден и на экранах, открытых поверх главного.
class UnreadHost extends StatefulWidget {
  const UnreadHost({super.key, required this.child});

  final Widget child;

  @override
  State<UnreadHost> createState() => _UnreadHostState();
}

class _UnreadHostState extends State<UnreadHost> {
  UnreadController? _controller;
  int? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    final userId = session.status == SessionStatus.signedIn ? session.me.id : null;
    if (userId == _userId) return;
    _userId = userId;
    _controller?.dispose();
    _controller = userId == null ? null : (UnreadController(session.api)..start());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return controller == null ? widget.child : UnreadScope(controller: controller, child: widget.child);
  }
}
