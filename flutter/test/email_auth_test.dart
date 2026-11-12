import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';

import 'fixtures.dart';

http.Response loginError(String code, String message, int status, [Map<String, dynamic>? details]) =>
    json({'error': {'code': code, 'message': message, 'details': details}}, status);

Future<(FakeServer, MemorySessionStore)> openLogin(WidgetTester tester, Map<String, http.Response Function(http.Request)> routes) async {
  final server = FakeServer({
    'GET /api/v1/auth/dev/users': (_) => json(errorJson('dev_login_disabled', 'Dev-вход выключен.'), 403),
    'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
    ...routes,
  });
  final store = MemorySessionStore(serverUrl: 'http://mock.test');
  final session = SessionController(api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client), store: store);
  await session.restore();
  await tester.pumpWidget(ModusApp(session: session));
  await tester.pumpAndSettle();
  return (server, store);
}

Future<void> fill(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.tap(find.byKey(const Key('login-email-submit')));
  await tester.pumpAndSettle();
}

Map<String, dynamic> body(FakeServer s, String path) => jsonDecode(s.last('POST', path).body) as Map<String, dynamic>;

void main() {
  testWidgets('вход по почте: проверка полей, неверный пароль, успешный вход', (tester) async {
    var attempt = 0;
    final (server, store) = await openLogin(tester, {
      'POST /api/v1/auth/login': (_) => attempt++ == 0
          ? loginError('invalid_credentials', 'Неверная почта или пароль.', 401)
          : json(sessionJson(meJson())),
      'GET /api/v1/appeals': (_) => json({'items': [], 'total': 0, 'page': 1, 'per_page': 20}),
      'GET /api/v1/notifications/unread-count': (_) => json({'count': 0}),
    });

    await fill(tester, 'не почта', '');
    expect(find.text('Проверьте адрес: в нём должны быть @ и домен.'), findsOneWidget);
    expect(find.text('Введите пароль.'), findsOneWidget);
    expect(server.requests.where((r) => r.url.path == '/api/v1/auth/login'), isEmpty);

    await fill(tester, ' a.nurlanova@modus.example ', 'wrong-pass');
    expect(find.text('Неверная почта или пароль.'), findsOneWidget);
    expect(body(server, '/api/v1/auth/login'), {'email': 'a.nurlanova@modus.example', 'password': 'wrong-pass', 'new_password': null});

    await fill(tester, 'a.nurlanova@modus.example', 'korova-2026');
    expect(find.text('Мои обращения'), findsWidgets);
    expect(store.token, isNotNull);
  });

  testWidgets('вход по почте: заявка на рассмотрении, отклонена с причиной, блокировка', (tester) async {
    final answers = [
      loginError('access_request_pending', 'Заявка на рассмотрении.', 403),
      loginError('access_request_rejected', 'Заявка отклонена.', 403, {'reason': 'Не сотрудник компании'}),
      loginError('too_many_requests', 'Слишком много попыток.', 429, {'retry_after_seconds': 252}),
    ];
    var i = 0;
    await openLogin(tester, {'POST /api/v1/auth/login': (_) => answers[i++]});

    await fill(tester, 's.kim@modus.example', 'korova-2026');
    expect(find.byKey(const Key('login-problem-pending')), findsOneWidget);
    expect(find.text('Заявка на рассмотрении'), findsOneWidget);

    await fill(tester, 's.kim@modus.example', 'korova-2026');
    expect(find.text('Заявка отклонена'), findsOneWidget);
    expect(find.text('Причина: Не сотрудник компании'), findsOneWidget);

    await fill(tester, 's.kim@modus.example', 'korova-2026');
    expect(find.text('Слишком много попыток'), findsOneWidget);
    expect(find.textContaining('через 4 мин 12 с'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('временный пароль: шаг «Новый пароль», повтор входа с new_password', (tester) async {
    final (server, _) = await openLogin(tester, {
      'POST /api/v1/auth/login': (r) => (jsonDecode(r.body) as Map)['new_password'] == null
          ? loginError('password_change_required', 'Задайте новый пароль.', 403)
          : json(sessionJson(meJson())),
      'GET /api/v1/appeals': (_) => json({'items': [], 'total': 0, 'page': 1, 'per_page': 20}),
      'GET /api/v1/notifications/unread-count': (_) => json({'count': 0}),
    });

    await fill(tester, 'a.nurlanova@modus.example', 'Tmp-7kQ2-xZ9p');
    expect(find.text('Новый пароль'), findsWidgets);

    await tester.enterText(find.byKey(const Key('new-password')), 'Tmp-7kQ2-xZ9p');
    await tester.enterText(find.byKey(const Key('new-password-repeat')), 'другой');
    await tester.tap(find.byKey(const Key('new-password-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Новый пароль должен отличаться от временного.'), findsOneWidget);
    expect(find.text('Пароли не совпадают.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('new-password')), 'novyi-parol-2026');
    await tester.enterText(find.byKey(const Key('new-password-repeat')), 'novyi-parol-2026');
    await tester.tap(find.byKey(const Key('new-password-submit')));
    await tester.pumpAndSettle();
    expect(body(server, '/api/v1/auth/login'),
        {'email': 'a.nurlanova@modus.example', 'password': 'Tmp-7kQ2-xZ9p', 'new_password': 'novyi-parol-2026'});
    expect(find.text('Мои обращения'), findsWidgets);
  });

  testWidgets('регистрация: проверка полей, заявка с подразделением, экран «на рассмотрении»', (tester) async {
    final (server, _) = await openLogin(tester, {
      'GET /api/v1/access-requests/departments': (_) => json([
            {'id': 1, 'name': 'Закупки'},
            {'id': 3, 'name': 'Продажи'},
          ]),
      'POST /api/v1/auth/register': (_) => json({
            'status': 'pending',
            'request': {
              'id': 9,
              'status': 'pending',
              'full_name': 'Сергей Ким',
              'email': 's.kim@modus.example',
              'telegram_username': null,
              'department': {'id': 3, 'name': 'Продажи'},
              'comment': 'Менеджер по продажам',
              'created_at': '2026-11-12T10:00:00+05:00',
              'updated_at': '2026-11-12T10:00:00+05:00',
              'assigned_role': null,
              'assigned_department': null,
              'decided_at': null,
              'decided_by': null,
              'reject_reason': null,
              'user_id': null,
            },
            'session': null,
          }, 201),
    });
    await tester.tap(find.byKey(const Key('open-register')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Укажите имя и фамилию.'), findsOneWidget);
    expect(find.text('Придумайте пароль.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register-name')), 'Сергей Ким');
    await tester.enterText(find.byKey(const Key('register-email')), 's.kim@modus.example');
    await tester.enterText(find.byKey(const Key('register-password')), 'korova-2026');
    await tester.tap(find.byKey(const Key('register-department-true')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продажи').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('register-comment')), 'Менеджер по продажам');
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

    expect(body(server, '/api/v1/auth/register'), {
      'full_name': 'Сергей Ким',
      'email': 's.kim@modus.example',
      'password': 'korova-2026',
      'department_id': 3,
      'comment': 'Менеджер по продажам',
      'invite_token': null,
    });
    expect(find.byKey(const Key('register-pending')), findsOneWidget);
    expect(find.text('Заявка на рассмотрении'), findsOneWidget);
  });
}
