import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'session/session_controller.dart';
import 'ui/home/home_shell.dart';
import 'ui/login/login_screen.dart';
import 'ui/offline_screen.dart';

/// Доступ к сессии из любого экрана: `SessionScope.of(context)`.
class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({super.key, required SessionController controller, required super.child})
      : super(notifier: controller);

  static SessionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  /// Без подписки на изменения — для обработчиков нажатий.
  static SessionController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}

class ModusApp extends StatelessWidget {
  const ModusApp({super.key, required this.session});

  final SessionController session;

  static const _seed = Color(0xFF1F5FA8);

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: session,
      child: MaterialApp(
        title: 'Модус Трейд',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.light),
        darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return switch (session.status) {
      SessionStatus.loading => const Scaffold(body: Center(child: CircularProgressIndicator())),
      SessionStatus.signedOut => const LoginScreen(),
      SessionStatus.offline => const OfflineScreen(),
      // Ключ по пользователю: после входа под другим пользователем навигация строится заново.
      SessionStatus.signedIn => HomeShell(key: ValueKey(session.me.id)),
    };
  }
}
