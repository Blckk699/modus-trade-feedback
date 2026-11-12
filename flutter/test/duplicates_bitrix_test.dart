import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/appeals/appeal_screen.dart';
import 'package:modus_feedback/ui/appeals/duplicates_bitrix.dart';

import 'fixtures.dart';

Future<SessionController> signedIn(FakeServer server) async {
  server.routes['GET /api/v1/me'] = (_) => json(meJson(id: 3, role: 'head', permissions: headPermissions));
  server.routes['GET /api/v1/dictionaries'] = (_) => json(dictionariesJson);
  server.routes['GET /api/v1/appeals/21/history'] = (_) => json([]);
  server.routes['GET /api/v1/appeals/21/messages'] = (_) => json([]);
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 'token', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  return session;
}

Future<void> pumpCard(WidgetTester tester, SessionController session) async {
  await tester.pumpWidget(SessionScope(
    controller: session,
    child: const MaterialApp(home: AppealScreen(appealId: 21)),
  ));
  await tester.pumpAndSettle();
}

final list = find.byType(Scrollable).first;

Map<String, dynamic> suggestion({bool canMerge = true}) => {
      'id': 41,
      'appeal_id': 21,
      'similar_appeal': {
        'id': 1,
        'number': 'A-001',
        'summary': 'В заявках не хватает параметров',
        'status': 'in_review',
        'type': 'problem',
      },
      'explanation': 'Обе про обязательные поля в заявке на оборудование.',
      'can_merge': canMerge,
      'created_at': '2026-11-10T10:16:00+05:00',
    };

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('склонение «человек»', () {
    String p(int n) => plural(n, ('человек', 'человека', 'человек'));
    expect([p(1), p(2), p(5), p(11), p(12), p(21), p(22), p(25)],
        ['человек', 'человека', 'человек', 'человек', 'человек', 'человек', 'человека', 'человек']);
  });

  testWidgets('подсказка: номер и объяснение; «Присоединить» склеивает и перечитывает карточку', (tester) async {
    var merged = false;
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(merged
          ? appealJson(
              status: 'closed',
              closedReason: 'merged',
              allowedActions: const [],
              mergedInto: {'id': 1, 'number': 'A-001', 'summary': 'В заявках не хватает параметров', 'status': 'in_review', 'type': 'problem'},
            )
          : appealJson(allowedActions: const ['take', 'merge'])),
      'GET /api/v1/appeals/21/similar': (_) => json(merged ? [] : [suggestion()]),
      'POST /api/v1/appeals/21/merge': (_) {
        merged = true;
        return json(appealJson(id: 1, number: 'A-001', participantsCount: 2));
      },
    });
    final session = await signedIn(server);
    await pumpCard(tester, session);

    await tester.scrollUntilVisible(find.byKey(const Key('merge-41')), 200, scrollable: list);
    expect(find.text('Похожие обращения'), findsOneWidget);
    expect(find.text('Обе про обязательные поля в заявке на оборудование.'), findsOneWidget);
    expect(find.text('Присоединить'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('merge-41')));
    await tester.pumpAndSettle();

    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/merge').body), {'main_appeal_id': 1});
    await tester.scrollUntilVisible(find.byKey(const Key('merged-into')), -200, scrollable: list);
    expect(find.text('Присоединено к другому обращению'), findsOneWidget);
    expect(find.text('A-001 · В заявках не хватает параметров'), findsOneWidget);
    expect(find.text('На рассмотрении'), findsOneWidget, reason: 'статус основного');
    expect(find.byKey(const Key('duplicates')), findsNothing);
  });

  testWidgets('«Это другое» убирает подсказку; без merge в allowed_actions кнопки присоединения нет', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(allowedActions: const ['take'])),
      'GET /api/v1/appeals/21/similar': (_) => json([suggestion()]),
      'POST /api/v1/duplicate-suggestions/41/dismiss': (_) => http204(),
    });
    final session = await signedIn(server);
    await pumpCard(tester, session);

    await tester.scrollUntilVisible(find.byKey(const Key('dismiss-41')), 200, scrollable: list);
    expect(find.byKey(const Key('merge-41')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('dismiss-41')));
    await tester.pumpAndSettle();
    expect(server.requests.any((r) => r.url.path == '/api/v1/duplicate-suggestions/41/dismiss'), isTrue);
    expect(find.byKey(const Key('duplicates')), findsNothing);
  });

  testWidgets('основное обращение: «Об этом сказали 3 человека»; автору подсказок нет', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(participantsCount: 3, allowedActions: const [])),
      'GET /api/v1/appeals/21/similar': (_) => json([]),
    });
    final session = await signedIn(server);
    await pumpCard(tester, session);
    expect(find.text('Об этом сказали 3 человека'), findsOneWidget);
    expect(find.byKey(const Key('duplicates')), findsNothing);
  });

  testWidgets('Битрикс24: кнопка по allowed_actions создаёт задачу и меняется на ссылку', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(status: 'in_review', allowedActions: const ['create_bitrix_task'])),
      'GET /api/v1/appeals/21/similar': (_) => json([]),
      'POST /api/v1/appeals/21/bitrix-task': (_) => json({
            'task_id': '1842',
            'url': 'https://modus.bitrix24.kz/company/personal/user/0/tasks/task/view/1842/',
            'created_at': '2026-11-10T12:00:00+05:00',
          }, 201),
    });
    final session = await signedIn(server);
    await pumpCard(tester, session);

    // Задача в Битрикс24 — второстепенное действие карточки.
    await tapAction(tester, 'bitrix-create');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bitrix-create')), findsNothing);
    expect(find.text('Задача №1842 в Битрикс24'), findsOneWidget);
  });

  testWidgets('Битрикс24: уже созданная задача — ссылка; без права и задачи — раздела нет', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(allowedActions: const [], bitrixTask: {
            'task_id': '77',
            'url': 'https://example.test/77',
            'created_at': '2026-11-10T12:00:00+05:00',
          })),
      'GET /api/v1/appeals/21/similar': (_) => json([]),
    });
    final session = await signedIn(server);
    await pumpCard(tester, session);
    await tester.scrollUntilVisible(find.text('Задача №77 в Битрикс24'), 200, scrollable: list);

    server.routes['GET /api/v1/appeals/21'] = (_) => json(appealJson(allowedActions: const []));
    await tester.pumpWidget(SessionScope(
      controller: session,
      child: const MaterialApp(home: AppealScreen(key: Key('other'), appealId: 21)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Битрикс24'), findsNothing);
  });

  testWidgets('ошибка Битрикс24 видна у кнопки', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(allowedActions: const ['create_bitrix_task'])),
      'GET /api/v1/appeals/21/similar': (_) => json([]),
      'POST /api/v1/appeals/21/bitrix-task': (_) =>
          json(errorJson('bitrix_unavailable', 'Битрикс24 не отвечает. Попробуйте позже.'), 502),
    });
    final session = await signedIn(server);
    await pumpCard(tester, session);
    // Задача в Битрикс24 — второстепенное действие карточки.
    await tapAction(tester, 'bitrix-create');
    await tester.pumpAndSettle();
    expect(find.text('Битрикс24 не отвечает. Попробуйте позже.'), findsOneWidget);
  });
}
