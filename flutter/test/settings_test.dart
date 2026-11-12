import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/navigation/sections.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/settings/settings_screen.dart';

import 'fixtures.dart';

const departmentsJson = [
  {'id': 1, 'name': 'Закупки', 'head': assignee},
  {'id': 2, 'name': 'Бухгалтерия', 'head': null},
];

Future<SessionController> signedIn(FakeServer server) async {
  server.routes['GET /api/v1/me'] = (_) => json(meJson(id: 2, role: 'admin', permissions: adminPermissions));
  server.routes['GET /api/v1/dictionaries'] = (_) => json(dictionariesJson);
  server.routes['GET /api/v1/users'] ??= (_) => json(usersJson);
  server.routes['GET /api/v1/departments'] ??= (_) => json(departmentsJson);
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 'token', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  return session;
}

Future<void> pumpSettings(WidgetTester tester, SessionController session, [String? tab]) async {
  await tester.pumpWidget(SessionScope(controller: session, child: const MaterialApp(home: SettingsScreen())));
  await tester.pumpAndSettle();
  if (tab != null) {
    await tester.tap(find.byKey(Key('settings-$tab')));
    await tester.pumpAndSettle();
  }
}

Map<String, dynamic> body(FakeServer s, String method, String path) =>
    jsonDecode(s.last(method, path).body) as Map<String, dynamic>;

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('раздел «Настройки» только у администратора', () {
    expect(sectionsFor(Me.fromJson(meJson(id: 2, role: 'admin', permissions: adminPermissions))!), contains(Section.settings));
    expect(sectionsFor(Me.fromJson(meJson(id: 1, role: 'owner', permissions: ownerPermissions))!),
        isNot(contains(Section.settings)));
  });

  testWidgets('сотрудник: изменение отправляет только изменённые поля; отсутствие и отключение', (tester) async {
    final server = FakeServer({
      'PATCH /api/v1/admin/users/5': (r) => json({...usersJson[1], ...(jsonDecode(r.body) as Map)}),
    });
    final session = await signedIn(server);
    await pumpSettings(tester, session);

    expect(server.last('GET', '/api/v1/users').url.queryParameters['include_disabled'], 'true');
    expect(find.textContaining('Отсутствует'), findsOneWidget);
    await tester.tap(find.byKey(const Key('user-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('user-disabled')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(body(server, 'PATCH', '/api/v1/admin/users/5'), {'is_disabled': true});
    expect(find.textContaining('Доступ отключён'), findsWidgets);
  });

  testWidgets('новый сотрудник: Telegram ID обязателен и числовой; POST с ролью и подразделением', (tester) async {
    final server = FakeServer({
      'POST /api/v1/admin/users': (r) => json({
            'id': 20, 'telegram_id': 555, 'full_name': 'Новый Сотрудник', 'position': null, 'role': 'employee',
            'department': {'id': 2, 'name': 'Бухгалтерия'}, 'is_absent': false, 'is_disabled': false,
          }, 201),
    });
    final session = await signedIn(server);
    await pumpSettings(tester, session);
    await tester.tap(find.byKey(const Key('user-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('user-telegram')), 'abc');
    await tester.enterText(find.byKey(const Key('user-name')), 'Новый Сотрудник');
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Числовой Telegram ID, например 123456789.'), findsOneWidget);
    expect(server.requests.any((r) => r.method == 'POST'), isFalse);

    await tester.enterText(find.byKey(const Key('user-telegram')), '555');
    await tester.tap(find.byKey(const Key('user-department')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бухгалтерия').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(body(server, 'POST', '/api/v1/admin/users'), {
      'telegram_id': 555,
      'email': null,
      'full_name': 'Новый Сотрудник',
      'position': null,
      'role': 'employee',
      'department_id': 2,
    });
    expect(find.text('Новый Сотрудник'), findsOneWidget);
  });

  testWidgets('подразделение: руководитель меняется PATCH только head_id', (tester) async {
    final server = FakeServer({
      'PATCH /api/v1/admin/departments/2': (r) => json({
            'id': 2,
            'name': 'Бухгалтерия',
            'head': {'id': 5, 'full_name': 'Ольга Петрова', 'role': 'employee', 'department': {'id': 2, 'name': 'Бухгалтерия'}},
          }),
    });
    final session = await signedIn(server);
    await pumpSettings(tester, session, 'departments');
    expect(find.text('Руководитель не назначен'), findsOneWidget);
    await tester.tap(find.byKey(const Key('department-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('department-head')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Анна Ли'), findsNothing, reason: 'администратор не назначается');
    await tester.tap(find.text('Ольга Петрова — Бухгалтерия').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(body(server, 'PATCH', '/api/v1/admin/departments/2'), {'head_id': 5});
    expect(find.text('Руководитель: Ольга Петрова'), findsOneWidget);
  });

  testWidgets('категория: заместитель не может совпадать с ответственным; снятие с использования', (tester) async {
    final server = FakeServer({
      'GET /api/v1/categories': (_) => json(categoriesJson),
      'PATCH /api/v1/admin/categories/1': (r) => json({...categoriesJson[0], ...(jsonDecode(r.body) as Map)}),
    });
    final session = await signedIn(server);
    await pumpSettings(tester, session, 'categories');
    expect(server.last('GET', '/api/v1/categories').url.queryParameters['include_inactive'], 'true');
    expect(find.textContaining('Архивная · не используется'), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-deputy')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Марат Сейткали — Закупки').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Заместитель должен отличаться от ответственного.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-deputy')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Нет').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('category-active')));
    await tester.tap(find.byKey(const Key('category-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(body(server, 'PATCH', '/api/v1/admin/categories/1'), {'is_active': false});
  });

  testWidgets('сроки: от 1 до 30 рабочих дней, PUT всех правил', (tester) async {
    final server = FakeServer({
      'GET /api/v1/admin/deadline-rules': (_) => json([
            {'priority': 'high', 'business_days': 1},
            {'priority': 'medium', 'business_days': 3},
            {'priority': 'low', 'business_days': 5},
          ]),
      'GET /api/v1/admin/settings': (_) => json({'digest_time': '09:00', 'timezone': '+05:00'}),
      'PUT /api/v1/admin/deadline-rules': (r) => json(jsonDecode(r.body)),
    });
    final session = await signedIn(server);
    await pumpSettings(tester, session, 'deadlines');
    expect(find.text('09:00'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('deadline-medium')), '40');
    await tester.tap(find.byKey(const Key('deadlines-save')));
    await tester.pumpAndSettle();
    expect(find.text('Срок — целое число рабочих дней от 1 до 30.'), findsOneWidget);
    expect(server.requests.any((r) => r.method == 'PUT'), isFalse);

    await tester.enterText(find.byKey(const Key('deadline-medium')), '2');
    await tester.tap(find.byKey(const Key('deadlines-save')));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('PUT', '/api/v1/admin/deadline-rules').body), [
      {'priority': 'high', 'business_days': 1},
      {'priority': 'medium', 'business_days': 2},
      {'priority': 'low', 'business_days': 5},
    ]);
    expect(find.byKey(const Key('deadlines-saved')), findsOneWidget);
    expect(server.requests.any((r) => r.method == 'PATCH'), isFalse, reason: 'время сводки не менялось');
  });

  testWidgets('нераспределённые: назначение ответственного убирает обращение из очереди', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals': (_) => json({
            'items': [appealJson(id: 7, number: 'A-007', assigneeJson: null)],
            'total': 1,
            'page': 1,
            'page_size': 100,
          }),
      'POST /api/v1/appeals/7/reassign': (_) => json(appealJson(id: 7, number: 'A-007')),
    });
    final session = await signedIn(server);
    await pumpSettings(tester, session, 'unassigned');
    final q = server.last('GET', '/api/v1/appeals').url.queryParameters;
    expect(q['scope'], 'unassigned');
    expect(q['sort'], 'created_asc');
    expect(find.textContaining('Категория: Межотдельное взаимодействие — без ответственного'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assign-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Выберите ответственного.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('assign-user')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Марат Сейткали — Закупки').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(body(server, 'POST', '/api/v1/appeals/7/reassign'),
        {'assignee_id': 3, 'reason': 'Распределено администратором'});
    expect(find.text('Нераспределённых обращений нет.'), findsOneWidget);
  });
}
