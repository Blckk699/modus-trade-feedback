import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/appeals/appeal_screen.dart';

import 'fixtures.dart';

const headBrief = {'id': 3, 'full_name': 'Олжас Мукашев', 'role': 'head', 'department': {'id': 1, 'name': 'Закупки'}};
const ownerBrief = {'id': 1, 'full_name': 'Андрей Вольф', 'role': 'owner', 'department': null};

Map<String, dynamic> withTargets(Map<String, dynamic> me, List<Map<String, dynamic>> targets) => {...me, 'switch_targets': targets};

Future<(FakeServer, SessionController)> start(WidgetTester tester, {required bool headSeesAppeal}) async {
  final employee = withTargets(meJson(), [headBrief, ownerBrief]);
  final head = withTargets(meJson(id: 3, role: 'head', fullName: 'Олжас Мукашев', permissions: headPermissions), [
    {'id': 4, 'full_name': 'Карина Шаймерденова', 'role': 'employee', 'department': {'id': 1, 'name': 'Закупки'}},
    ownerBrief,
  ]);
  var asHead = false;
  final server = FakeServer({
    'GET /api/v1/me': (_) => json(asHead ? head : employee),
    'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
    'POST /api/v1/auth/switch': (_) {
      asHead = true;
      return json({...sessionJson(head), 'access_token': 'head-token'});
    },
    'GET /api/v1/appeals': (_) => json({'items': [], 'total': 0, 'page': 1, 'per_page': 20}),
    'GET /api/v1/appeals/21': (r) => !asHead || headSeesAppeal
        ? json(appealJson())
        : json(errorJson('not_found', 'Обращение не найдено.'), 404),
    'GET /api/v1/appeals/21/history': (_) => json([]),
    'GET /api/v1/appeals/21/messages': (_) => json([]),
    'GET /api/v1/notifications/unread-count': (_) => json({'count': 0}),
    'POST /api/v1/notifications/read': (_) => json({'count': 0}),
  });
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 'employee-token', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  await tester.pumpWidget(ModusApp(session: session));
  await tester.pumpAndSettle();
  return (server, session);
}

Future<void> openCardAndSwitch(WidgetTester tester) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.push(MaterialPageRoute<void>(builder: (_) => const AppealScreen(appealId: 21)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('role-switch')).last);
  await tester.pumpAndSettle();
  expect(find.text('Демо: одно обращение под разными ролями'), findsOneWidget);
  expect(find.byKey(const Key('switch-to-4')), findsOneWidget, reason: 'текущий пользователь в списке');
  expect(find.byKey(const Key('switch-to-1')), findsOneWidget);
  await tester.tap(find.byKey(const Key('switch-to-3')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('без связанных пользователей переключателя нет', (tester) async {
    final server = FakeServer({
      'GET /api/v1/me': (_) => json(meJson()),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
      'GET /api/v1/appeals': (_) => json({'items': [], 'total': 0, 'page': 1, 'per_page': 20}),
      'GET /api/v1/notifications/unread-count': (_) => json({'count': 0}),
    });
    final session = SessionController(
      api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
      store: MemorySessionStore(serverUrl: 'http://mock.test', token: 't', tokenServer: 'http://mock.test'),
    );
    await session.restore();
    await tester.pumpWidget(ModusApp(session: session));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('role-switch')), findsNothing);
  });

  testWidgets('переключение из карточки: новая сессия, карточка остаётся, если видна новой роли', (tester) async {
    final (server, session) = await start(tester, headSeesAppeal: true);
    await openCardAndSwitch(tester);

    expect(jsonDecode(server.last('POST', '/api/v1/auth/switch').body), {'user_id': 3});
    expect(session.me.id, 3);
    expect(server.last('GET', '/api/v1/appeals/21').headers['authorization'], 'Bearer head-token');
    expect(find.byType(AppealScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('карточка не видна новой роли — стартовый экран роли и подсказка', (tester) async {
    final (_, session) = await start(tester, headSeesAppeal: false);
    await openCardAndSwitch(tester);

    expect(session.me.id, 3);
    expect(find.byType(AppealScreen), findsNothing);
    expect(find.textContaining('не видит это обращение'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
