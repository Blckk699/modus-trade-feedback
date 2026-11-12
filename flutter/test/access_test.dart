import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/settings/access_tab.dart';
import 'package:modus_feedback/ui/settings/settings_screen.dart';

import 'fixtures.dart';

Map<String, dynamic> requestJson({int id = 9, String status = 'pending'}) => {
      'id': id,
      'status': status,
      'full_name': 'Сергей Ким',
      'email': 's.kim@modus.example',
      'telegram_username': null,
      'department': {'id': 3, 'name': 'Продажи'},
      'comment': 'Менеджер по продажам',
      'created_at': '2026-11-12T10:00:00+05:00',
      'updated_at': '2026-11-12T10:00:00+05:00',
      'assigned_role': status == 'approved' ? 'head' : null,
      'assigned_department': status == 'approved' ? {'id': 3, 'name': 'Продажи'} : null,
      'decided_by': status == 'pending' ? null : {'id': 1, 'full_name': 'Ержан Касымов', 'role': 'owner', 'department': null},
      'decided_at': status == 'pending' ? null : '2026-11-12T11:00:00+05:00',
      'reject_reason': null,
      'user_id': status == 'approved' ? 21 : null,
    };

Map<String, dynamic> inviteJson({int id = 4, String state = 'active'}) => {
      'id': id,
      'state': state,
      'role': 'employee',
      'department': {'id': 1, 'name': 'Закупки'},
      'full_name': null,
      'created_by': {'id': 1, 'full_name': 'Ержан Касымов', 'role': 'owner', 'department': null},
      'created_at': '2026-11-12T10:00:00+05:00',
      'expires_at': '2026-11-19T10:00:00+05:00',
      'max_uses': 1,
      'used_count': 0,
      'revoked_at': null,
    };

const departments = [
  {'id': 1, 'name': 'Закупки', 'head': null},
  {'id': 3, 'name': 'Продажи', 'head': null},
];

Future<FakeServer> openAccess(WidgetTester tester, Map<String, dynamic> Function(FakeServer s) routesExtra) async {
  late FakeServer server;
  server = FakeServer({
    'GET /api/v1/me': (_) => json(meJson(id: 1, role: 'owner', fullName: 'Ержан Касымов', permissions: ownerPermissions)),
    'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
    'GET /api/v1/departments': (_) => json(departments),
  });
  server.routes.addAll(routesExtra(server).cast());
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 't', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  await tester.pumpWidget(SessionScope(controller: session, child: const MaterialApp(home: SettingsScreen())));
  await tester.pumpAndSettle();
  return server;
}

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('проверка формы приглашения: срок 1–30 дней, использований 1–100', () {
    expect(inviteFormError('7', '1'), isNull);
    expect(inviteFormError('0', '1'), 'Срок действия: от 1 до 30 дней.');
    expect(inviteFormError('31', '1'), 'Срок действия: от 1 до 30 дней.');
    expect(inviteFormError('7', '101'), 'Число использований: от 1 до 100.');
  });

  testWidgets('собственник видит только вкладку «Доступ»; одобрение заявки с ролью и подразделением', (tester) async {
    var decided = false;
    final server = await openAccess(tester, (s) => {
          'GET /api/v1/admin/access-requests': (_) => json({
                'items': decided ? [] : [requestJson()],
                'total': decided ? 0 : 1,
                'page': 1,
                'page_size': 50,
              }),
          'POST /api/v1/admin/access-requests/9/approve': (_) {
            decided = true;
            return json(requestJson(status: 'approved'));
          },
        });

    expect(find.byKey(const Key('settings-access')), findsOneWidget);
    expect(find.byKey(const Key('settings-users')), findsNothing, reason: 'остальные вкладки — только администратору');
    expect(find.text('Сергей Ким'), findsOneWidget);
    expect(server.last('GET', '/api/v1/admin/access-requests').url.queryParameters['status'], 'pending');

    await tester.tap(find.byKey(const Key('request-tune-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-role-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Руководитель подразделения').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-approve-9')));
    await tester.pumpAndSettle();

    expect(jsonDecode(server.last('POST', '/api/v1/admin/access-requests/9/approve').body),
        {'role': 'head', 'department_id': 3, 'full_name': null, 'position': null});
    expect(find.text('Сергей Ким'), findsNothing, reason: 'решённая заявка ушла из «На рассмотрении»');
  });

  testWidgets('приглашение: проверка полей, создание, ссылки один раз; отзыв', (tester) async {
    var invites = [inviteJson(id: 3)];
    final server = await openAccess(tester, (s) => {
          'GET /api/v1/admin/access-requests': (_) => json({'items': [], 'total': 0, 'page': 1, 'page_size': 50}),
          'GET /api/v1/admin/invites': (_) => json(invites),
          'POST /api/v1/admin/invites': (_) {
            invites = [inviteJson(id: 5), ...invites];
            return json({
              ...inviteJson(id: 5),
              'token': 'tok',
              'bot_link': 'https://t.me/modus_fb_bot?start=inv_tok',
              'web_link': 'https://modus.systm.kz/invite/tok',
            }, 201);
          },
          'POST /api/v1/admin/invites/3/revoke': (_) {
            invites = [inviteJson(id: 3, state: 'revoked')];
            return json(invites.first);
          },
        });
    await tester.tap(find.byKey(const Key('access-invites')));
    await tester.pumpAndSettle();
    expect(find.text('Действует'), findsOneWidget);

    await tester.tap(find.byKey(const Key('invite-create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('invite-days')), '45');
    await tester.tap(find.byKey(const Key('invite-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Срок действия: от 1 до 30 дней.'), findsOneWidget);
    expect(server.requests.where((r) => r.method == 'POST'), isEmpty);

    await tester.enterText(find.byKey(const Key('invite-days')), '7');
    await tester.tap(find.byKey(const Key('invite-submit')));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/admin/invites').body),
        {'role': 'employee', 'department_id': null, 'full_name': null, 'expires_in_days': 7, 'max_uses': 1});
    expect(find.text('Приглашение создано'), findsOneWidget);
    expect(find.text('https://t.me/modus_fb_bot?start=inv_tok'), findsOneWidget);
    expect(find.text('https://modus.systm.kz/invite/tok'), findsOneWidget);

    await tester.tap(find.byKey(const Key('invite-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invite-5')), findsOneWidget);

    await tester.tap(find.byKey(const Key('invite-revoke-3')));
    await tester.pumpAndSettle();
    expect(server.last('POST', '/api/v1/admin/invites/3/revoke'), isNotNull);
    expect(find.text('Отозвано'), findsOneWidget);
  });
}
