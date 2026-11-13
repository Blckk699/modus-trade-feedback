import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';

import 'fixtures.dart';

void main() {
  testWidgets('вход по коду ведёт на стартовый экран роли, выход — обратно', (tester) async {
    final server = FakeServer({
      'GET /api/v1/auth/dev/users': (_) => json(errorJson('dev_login_disabled', 'Dev-вход выключен.'), 403),
      'POST /api/v1/auth/code': (_) => json(sessionJson(meJson(id: 1, role: 'owner', permissions: ownerPermissions))),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
      'POST /api/v1/auth/logout': (_) => json(const {}, 200),
    });
    final store = MemorySessionStore(serverUrl: 'http://mock.test');
    final session = SessionController(
      api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
      store: store,
    );
    await session.restore();
    await tester.pumpWidget(ModusApp(session: session));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('server-settings')), findsNothing, reason: 'сервер задаётся сборкой, на входе его не выбирают');

    expect(find.byKey(const Key('login-email')), findsOneWidget, reason: 'основной способ — почта');
    expect(find.byKey(const Key('dev-login')), findsNothing, reason: 'dev-вход выключен на сервере');

    await tester.ensureVisible(find.byKey(const Key('login-code-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-code-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login-code')), '482913');
    await tester.pump();
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    // Все начинают с «Сегодня»; у собственника разделов больше пяти — четыре на панели и «Ещё».
    expect(find.byKey(const Key('today-greeting')), findsOneWidget);
    expect(find.byKey(const Key('nav-more')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Собственник'), findsWidgets);

    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(store.token, isNull);
  });
}
