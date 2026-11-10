import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/api/app_error.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';

import 'fixtures.dart';

const base = 'http://mock.test';

SessionController controller(FakeServer server, MemorySessionStore store) => SessionController(
      api: ApiService(baseUrl: base, httpClient: server.client),
      store: store,
    );

void main() {
  late MemorySessionStore store;

  setUp(() => store = MemorySessionStore(serverUrl: base));

  test('вход по коду: POST /api/v1/auth/code, токен сохраняется, пользователь из сессии', () async {
    final server = FakeServer({
      'POST /api/v1/auth/code': (_) => json(sessionJson()),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
    });
    final session = controller(server, store);
    await session.restore();
    expect(session.status, SessionStatus.signedOut);

    await session.loginWithCode('482913');

    final request = server.last('POST', '/api/v1/auth/code');
    expect(jsonDecode(request.body), {'code': '482913'});
    expect(request.headers['authorization'], isNull);
    expect(session.status, SessionStatus.signedIn);
    expect(session.me.fullName, 'Айгерим Нурланова');
    expect(store.token, 'eyJhbGciOiJIUzI1NiJ9.mock.session');
    expect(session.roleLabel(session.me.role), 'Сотрудник');
  });

  test('неверный код — ошибка с текстом сервера, сессии нет', () async {
    const message = 'Код неверный или истёк. Запросите новый код в боте.';
    final server = FakeServer({
      'POST /api/v1/auth/code': (_) => json(errorJson('invalid_login_code', message), 401),
    });
    final session = controller(server, store);
    await session.restore();

    await expectLater(
      session.loginWithCode('000000'),
      throwsA(isA<AppError>()
          .having((e) => e.code, 'code', 'invalid_login_code')
          .having((e) => e.message, 'message', message)),
    );
    expect(session.status, SessionStatus.signedOut);
    expect(store.token, isNull);
  });

  test('сессия восстанавливается при запуске: GET /me с Bearer-токеном', () async {
    store.token = 'saved-token';
    final server = FakeServer({
      'GET /api/v1/me': (_) => json(meJson()),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
    });
    final session = controller(server, store);

    await session.restore();

    expect(server.last('GET', '/api/v1/me').headers['authorization'], 'Bearer saved-token');
    expect(session.status, SessionStatus.signedIn);
  });

  test('истёкший токен при запуске — экран входа, токен удалён', () async {
    store.token = 'expired';
    final server = FakeServer({
      'GET /api/v1/me': (_) => json(errorJson('unauthorized', 'Требуется вход.'), 401),
    });
    final session = controller(server, store);

    await session.restore();

    expect(session.status, SessionStatus.signedOut);
    expect(store.token, isNull);
  });

  test('нет сети при запуске — экран повтора, токен сохранён', () async {
    store.token = 'saved-token';
    final server = FakeServer({
      'GET /api/v1/me': (_) => throw http.ClientException('Connection refused'),
    });
    final session = controller(server, store);

    await session.restore();

    expect(session.status, SessionStatus.offline);
    expect(session.offlineError?.code, AppError.network);
    expect(store.token, 'saved-token');
  });

  test('dev-вход: список пользователей и вход под выбранным', () async {
    final server = FakeServer({
      'GET /api/v1/auth/dev/users': (_) => json([
            {'id': 1, 'full_name': 'Ержан Касымов', 'role': 'owner', 'department': null},
          ]),
      'POST /api/v1/auth/dev/login': (_) => json(sessionJson(meJson(id: 1, role: 'owner'))),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
    });
    final session = controller(server, store);
    await session.restore();

    final users = await session.devUsers();
    expect(users!.single.fullName, 'Ержан Касымов');

    await session.devLogin(1);
    expect(jsonDecode(server.last('POST', '/api/v1/auth/dev/login').body), {'user_id': 1});
    expect(session.me.id, 1);
  });

  test('dev-вход выключен на сервере — список null', () async {
    final server = FakeServer({
      'GET /api/v1/auth/dev/users': (_) => json(errorJson('dev_login_disabled', 'Dev-вход выключен.'), 403),
    });
    final session = controller(server, store);
    await session.restore();

    expect(await session.devUsers(), isNull);
  });

  test('выход: POST /auth/logout, токен удалён, даже если сервер ответил ошибкой', () async {
    store.token = 'saved-token';
    final server = FakeServer({
      'GET /api/v1/me': (_) => json(meJson()),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
      'POST /api/v1/auth/logout': (_) => json(errorJson('unauthorized', 'Требуется вход.'), 401),
    });
    final session = controller(server, store);
    await session.restore();

    await session.logout();

    expect(server.last('POST', '/api/v1/auth/logout').headers['authorization'], 'Bearer saved-token');
    expect(session.status, SessionStatus.signedOut);
    expect(store.token, isNull);
  });

  test('смена сервера закрывает сессию и запоминает адрес', () async {
    store.token = 'saved-token';
    final server = FakeServer({
      'GET /api/v1/me': (_) => json(meJson()),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
      'POST /api/v1/auth/logout': (_) => http.Response('', 204),
    });
    final session = controller(server, store);
    await session.restore();

    await session.changeServer('https://other.test');

    expect(session.status, SessionStatus.signedOut);
    expect(session.serverUrl, 'https://other.test');
    expect(store.serverUrl, 'https://other.test');
    expect(store.token, isNull);
  });
}
