import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/appeals/appeal_screen.dart';

import 'fixtures.dart';

/// 1×1 PNG.
final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

Future<FakeServer> openCard(WidgetTester tester, Map<String, dynamic> appeal, {Map<String, dynamic>? me, Map<String, http.Response Function(http.Request)> routes = const {}}) async {
  final server = FakeServer({
    'GET /api/v1/me': (_) => json(me ?? meJson()),
    'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
    'GET /api/v1/appeals/21': (_) => json(appeal),
    'GET /api/v1/appeals/21/history': (_) => json([]),
    'GET /api/v1/appeals/21/messages': (_) => json([]),
    'GET /api/v1/appeals/21/similar': (_) => json([]),
    'GET /api/v1/notifications/unread-count': (_) => json({'count': 0}),
    'POST /api/v1/notifications/read': (_) => json({'count': 0}),
    ...routes,
  });
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 't', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  await tester.pumpWidget(SessionScope(controller: session, child: const MaterialApp(home: AppealScreen(appealId: 21))));
  await tester.pumpAndSettle();
  return server;
}

final list = find.byType(Scrollable).first;

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  testWidgets('тип чипом рядом со статусом; переписка видна автору', (tester) async {
    await openCard(tester, appealJson());
    expect(find.byKey(const Key('type-chip')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('type-chip')), matching: find.text('Проблема')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Переписка'), 200, scrollable: list);
    expect(find.text('Переписка'), findsOneWidget);
  });

  testWidgets('администратору переписка не видна и не запрашивается', (tester) async {
    final server = await openCard(
      tester,
      appealJson(viewerRelations: const ['admin']),
      me: meJson(id: 2, role: 'admin', permissions: adminPermissions),
    );
    await tester.scrollUntilVisible(find.byKey(const Key('history-toggle')), 200, scrollable: list);
    expect(find.text('Переписка'), findsNothing);
    expect(server.requests.where((r) => r.url.path.endsWith('/messages')), isEmpty);
  });

  testWidgets('без ответственного: блок назначения в карточке вместо «Переназначить»', (tester) async {
    final server = await openCard(
      tester,
      appealJson(assigneeJson: null, allowedActions: const ['reassign'], viewerRelations: const ['admin']),
      me: meJson(id: 2, role: 'admin', permissions: adminPermissions),
      routes: {
        'GET /api/v1/users': (_) => json([
              {
                'id': 3,
                'telegram_id': 3,
                'email': null,
                'full_name': 'Марат Сейткали',
                'position': null,
                'role': 'head',
                'department': {'id': 1, 'name': 'Закупки'},
                'is_absent': false,
                'is_disabled': false,
                'has_password': false,
                'telegram_linked': true,
              },
            ]),
        'POST /api/v1/appeals/21/reassign': (_) => json(appealJson(viewerRelations: const ['admin'], allowedActions: const [])),
      },
    );
    expect(find.byKey(const Key('assign-section')), findsOneWidget);
    expect(find.byKey(const Key('action-reassign')), findsNothing);

    await tester.tap(find.byKey(const Key('assign-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Выберите ответственного.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assign-user-true')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Марат Сейткали').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('assign-reason')), 'Категория без ответственного');
    await tester.tap(find.byKey(const Key('assign-submit')));
    await tester.pumpAndSettle();

    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/reassign').body), {'assignee_id': 3, 'reason': 'Категория без ответственного'});
    expect(find.byKey(const Key('assign-section')), findsNothing, reason: 'ответственный назначен');
  });

  testWidgets('картинки — галереей превью, документы — строками', (tester) async {
    Map<String, dynamic> att(int id, String name, String type) => {
          'id': id,
          'appeal_id': 21,
          'filename': name,
          'content_type': type,
          'size_bytes': 1024,
          'download_url': '/api/v1/attachments/$id',
          'uploaded_by': author,
          'created_at': '2026-11-10T10:20:00+05:00',
        };
    await openCard(
      tester,
      appealJson(attachments: [att(7, 'фото.png', 'image/png'), att(8, 'заявка.pdf', 'application/pdf')]),
      routes: {'GET /api/v1/attachments/7': (_) => http.Response.bytes(png, 200, headers: {'content-type': 'image/png'})},
    );
    await tester.scrollUntilVisible(find.byKey(const Key('attachment-gallery')), 200, scrollable: list);
    expect(find.text('Вложения · 2'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('attachment-gallery')), matching: find.byKey(const Key('attachment-7'))), findsOneWidget);
    expect(find.text('заявка.pdf'), findsOneWidget);
  });
}
