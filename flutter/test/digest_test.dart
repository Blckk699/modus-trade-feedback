import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/analytics/digest_screen.dart';

import 'fixtures.dart';

Map<String, dynamic> ref(int id, String number, String status) =>
    {'id': id, 'number': number, 'summary': 'Суть $number', 'status': status, 'type': 'problem'};

Map<String, dynamic> summaryJson({Map<String, dynamic>? department, double? avg = 26.5}) => {
      'scope': department == null ? 'company' : 'department',
      'department': department,
      'generated_at': '2026-11-10T09:00:00+05:00',
      'total': 20,
      'closed_count': 6,
      'closed_share': 0.3,
      'avg_first_response_hours': avg,
      'by_type': [
        {'type': 'problem', 'count': 12},
        {'type': 'suggestion', 'count': 8},
      ],
      'by_category': [
        {'category': {'id': 1, 'name': 'Межотдельное взаимодействие'}, 'count': 9},
        {'category': null, 'count': 2},
      ],
      'by_status': [
        {'status': 'new', 'count': 5},
      ],
      'new_last_24h': [ref(20, 'A-020', 'new')],
      'stuck': [
        {'appeal': ref(1, 'A-001', 'new'), 'assignee': assignee, 'days_overdue': 3, 'escalation_level': 3},
      ],
      'closed_last_week': [ref(4, 'A-004', 'implemented')],
      'repeated_topics': [
        {'appeal': ref(3, 'A-003', 'in_progress'), 'participants_count': 3},
      ],
      'overdue': [
        {'appeal': ref(1, 'A-001', 'new'), 'assignee': assignee, 'days_overdue': 3, 'escalation_level': 3},
      ],
      'assignee_load': [
        {'assignee': assignee, 'open_count': 4, 'overdue_count': 1, 'avg_first_response_hours': null},
      ],
    };

Future<SessionController> signedIn(FakeServer server, Map<String, dynamic> me) async {
  server.routes['GET /api/v1/me'] = (_) => json(me);
  server.routes['GET /api/v1/dictionaries'] = (_) => json(dictionariesJson);
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 'token'),
  );
  await session.restore();
  return session;
}

final list = find.byType(Scrollable).first;

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('часы ответа как в вебе', () {
    expect(formatHours(5), '5 ч');
    expect(formatHours(26.5), '1,1 д');
    expect(formatHours(4.25), '4,3 ч');
    expect(formatHours(48), '2 д');
  });

  testWidgets('собственник: все блоки, плитки, переход к обращению, фильтр подразделения', (tester) async {
    final server = FakeServer({
      'GET /api/v1/analytics/summary': (r) => json(r.url.queryParameters['department_id'] == '2'
          ? summaryJson(department: {'id': 2, 'name': 'Бухгалтерия'})
          : summaryJson()),
      'GET /api/v1/departments': (_) => json([
            {'id': 1, 'name': 'Закупки', 'head': null},
            {'id': 2, 'name': 'Бухгалтерия', 'head': null},
          ]),
      'GET /api/v1/categories': (_) => json(categoriesJson),
      'GET /api/v1/appeals/1': (_) => json(appealJson(id: 1, number: 'A-001')),
      'GET /api/v1/appeals/1/history': (_) => json([]),
      'GET /api/v1/appeals/1/messages': (_) => json([]),
      'GET /api/v1/appeals/1/similar': (_) => json([]),
    });
    final session = await signedIn(server, meJson(id: 1, role: 'owner', permissions: ownerPermissions));
    await tester.pumpWidget(SessionScope(controller: session, child: const MaterialApp(home: DigestScreen())));
    await tester.pumpAndSettle();

    expect(find.text('Сводка по компании'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('6 из 20'), findsOneWidget);
    expect(find.text('1,1 д'), findsOneWidget);
    for (final key in ['block-new', 'block-stuck', 'block-closed', 'block-repeated', 'block-categories', 'block-overdue', 'block-load']) {
      await tester.scrollUntilVisible(find.byKey(Key(key)), 200, scrollable: list);
    }
    expect(find.text('Без категории'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('block-repeated')), -200, scrollable: list);
    expect(find.text('Сообщили: 3'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('block-stuck')), -200, scrollable: list);
    await tester.tap(find.descendant(of: find.byKey(const Key('block-stuck')), matching: find.byKey(const Key('digest-appeal-1'))));
    await tester.pumpAndSettle();
    expect(find.text('A-001'), findsOneWidget, reason: 'открылась карточка');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('digest-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('digest-department-true')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бухгалтерия').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('digest-apply')));
    await tester.pumpAndSettle();
    expect(server.last('GET', '/api/v1/analytics/summary').url.queryParameters['department_id'], '2');
    expect(find.text('Сводка · Бухгалтерия'), findsOneWidget);
  });

  testWidgets('руководитель: своё подразделение, без фильтра подразделения; нет ответов — «—»', (tester) async {
    final server = FakeServer({
      'GET /api/v1/analytics/summary': (_) => json(summaryJson(department: {'id': 1, 'name': 'Закупки'}, avg: null)),
      'GET /api/v1/categories': (_) => json(categoriesJson),
    });
    final session = await signedIn(server, meJson(id: 3, role: 'head', permissions: headPermissions));
    await tester.pumpWidget(SessionScope(controller: session, child: const MaterialApp(home: DigestScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Сводка · Закупки'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Ещё нет ответов'), findsOneWidget);
    await tester.tap(find.byKey(const Key('digest-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('digest-department-true')), findsNothing);
    expect(server.requests.any((r) => r.url.path == '/api/v1/departments'), isFalse);
  });
}
