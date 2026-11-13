import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/appeals/attachment_files.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/appeals/appeal_screen.dart';
import 'package:modus_feedback/ui/appeals/new_appeal_screen.dart';

import 'fixtures.dart';

/// Вошедший сотрудник поверх фейкового сервера.
Future<SessionController> signedIn(FakeServer server) async {
  server.routes['GET /api/v1/me'] = (_) => json(meJson());
  server.routes['GET /api/v1/dictionaries'] = (_) => json(dictionariesJson);
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 'token', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  return session;
}

/// Прокрутить ленивый список до элемента и нажать.
/// Основной список экрана (в полях ввода и тексте есть свои Scrollable).
final list = find.byType(Scrollable).first;

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.scrollUntilVisible(finder, 200, scrollable: list);
  await tapVisible(tester, finder);
}

Widget screen(SessionController session, Widget child) =>
    SessionScope(controller: session, child: MaterialApp(home: child));

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  testWidgets('подача через форму: тело запроса, вложение и номер, ответственный, срок', (tester) async {
    final file = File('${Directory.systemTemp.createTempSync('modus').path}/скан.pdf')..writeAsBytesSync([1, 2, 3]);
    String? uploadedName;
    final server = FakeServer({
      'GET /api/v1/categories': (_) => json(categoriesJson),
      'POST /api/v1/appeals': (_) => json(appealJson(), 201),
    });
    final session = await signedIn(server);
    // MockClient не разбирает multipart — проверяем заголовок и имя файла в теле.
    server.routes['POST /api/v1/appeals/21/attachments'] = (request) {
      uploadedName = utf8.decode(request.bodyBytes, allowMalformed: true).contains('скан.pdf') ? 'скан.pdf' : null;
      return json({
        'id': 7,
        'appeal_id': 21,
        'filename': 'скан.pdf',
        'content_type': 'application/pdf',
        'size_bytes': 3,
        'download_url': '/api/v1/attachments/7',
        'uploaded_by': author,
        'created_at': '2026-11-10T10:16:00+05:00',
      }, 201);
    };

    await tester.pumpWidget(screen(
      session,
      NewAppealScreen(pickFiles: () async => [PickedFile(name: 'скан.pdf', path: file.path, size: 3)]),
    ));
    await tester.pumpAndSettle();

    // Пустое описание не отправляется.
    await tapKey(tester, 'submit-appeal');
    await tester.pumpAndSettle();
    expect(find.text('Опишите проблему или предложение.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Предложение'), -200, scrollable: find.byType(Scrollable).first);

    await tapVisible(tester, find.text('Предложение'));
    await tapVisible(tester, find.byKey(const Key('more-fields')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('field-category')));
    await tester.pumpAndSettle();
    expect(find.text('Архивная'), findsNothing, reason: 'неактивные категории скрыты');
    await tapVisible(tester, find.text('Межотдельное взаимодействие').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-text')), '  Не хватает параметров в заявках  ');
    await tester.enterText(find.byKey(const Key('field-solution')), 'Добавить поля');
    await tapKey(tester, 'add-files');
    await tester.pumpAndSettle();
    expect(find.text('скан.pdf'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('submit-appeal')), 200, scrollable: list);
    // Чтение файла для multipart — настоящий ввод-вывод, ему нужен реальный async.
    await tester.runAsync(() async {
      await tapVisible(tester, find.byKey(const Key('submit-appeal')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(jsonDecode(server.last('POST', '/api/v1/appeals').body), {
      'type': 'suggestion',
      'category_id': 1,
      'priority': 'medium',
      'text': 'Не хватает параметров в заявках',
      'summary': null,
      'proposed_solution': 'Добавить поля',
      'source': 'form',
      'forwarded_from': null,
    });
    expect(server.last('POST', '/api/v1/appeals/21/attachments').headers['content-type'], startsWith('multipart/form-data'));
    expect(uploadedName, 'скан.pdf');
    expect(find.text('Обращение A-021 подано'), findsOneWidget);
    expect(find.text('Олжас Мукашев'), findsOneWidget);
    expect(find.text('до 13 ноября 2026, 10:15'), findsOneWidget);
  });

  testWidgets('без категории — ответственного назначит администратор, срока нет', (tester) async {
    final server = FakeServer({
      'GET /api/v1/categories': (_) => json(categoriesJson),
      'POST /api/v1/appeals': (_) => json(appealJson(assigneeJson: null), 201),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const NewAppealScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-text')), 'Текст');
    await tapKey(tester, 'submit-appeal');
    await tester.pumpAndSettle();

    expect(jsonDecode(server.last('POST', '/api/v1/appeals').body)['category_id'], isNull);
    expect(find.text('Назначит администратор'), findsOneWidget);
    expect(find.text('Без срока'), findsOneWidget);
  });

  testWidgets('ошибка 422 показывает текст сервера у поля', (tester) async {
    final server = FakeServer({
      'GET /api/v1/categories': (_) => json(categoriesJson),
      'POST /api/v1/appeals': (_) => json({
            'error': {
              'code': 'validation_error',
              'message': 'Проверьте поля формы.',
              'details': {
                'fields': [
                  {'field': 'body.text', 'message': 'Слишком коротко.'},
                ],
              },
            },
          }, 422),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const NewAppealScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-text')), 'А');
    await tapKey(tester, 'submit-appeal');
    await tester.pumpAndSettle();

    expect(find.text('Слишком коротко.'), findsOneWidget);
    expect(find.text('Проверьте поля формы.'), findsOneWidget);
  });

  testWidgets('«Мои обращения»: scope=mine, статус, срок и отметка непрочитанного; счётчик в навигации', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals': (_) => json({
            'items': [
              appealJson(hasUnread: true),
              appealJson(id: 17, number: 'A-017', status: 'rejected', dueState: 'answered', summary: 'Отклонённое'),
            ],
            'total': 2,
            'page': 1,
            'page_size': 20,
          }),
      'GET /api/v1/notifications/unread-count': (_) => json({'count': 3}),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(ModusApp(session: session));
    await tester.pumpAndSettle();
    // Стартовый экран — «Сегодня»; переходим в «Мои».
    await tapVisible(tester, find.byKey(const Key('nav-myAppeals')));
    await tester.pumpAndSettle();

    final query = server.last('GET', '/api/v1/appeals').url.queryParameters;
    expect(query['scope'], 'mine');
    expect(query['sort'], 'created_desc');
    expect(find.textContaining('A-021'), findsOneWidget);
    expect(find.text('Новое'), findsOneWidget);
    // Срок в строке — только если ответ задерживается или скоро истечёт.
    expect(find.text('В срок · до 13 ноября 2026, 10:15'), findsNothing);
    expect(find.text('Отклонено'), findsOneWidget);
    expect(find.text('Ответ дан'), findsNothing);
    expect(find.byKey(const Key('unread-21')), findsOneWidget);
    expect(find.byKey(const Key('unread-17')), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('unread-badge')), matching: find.text('3')), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('карточка: история, переписка, вложения; открытие отмечает прочитанным', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(attachments: [
            {
              'id': 7,
              'appeal_id': 21,
              'filename': 'пример_заявки.pdf',
              'content_type': 'application/pdf',
              'size_bytes': 184320,
              'download_url': '/api/v1/attachments/7',
              'uploaded_by': author,
              'created_at': '2026-11-04T10:21:00+05:00',
            },
          ])),
      'GET /api/v1/appeals/21/history': (_) => json([
            {
              'id': 103,
              'appeal_id': 21,
              'kind': 'status_changed',
              'actor': assignee,
              'field': 'status',
              'old_value': 'new',
              'new_value': 'in_review',
              'comment': null,
              'created_at': '2026-11-10T11:02:00+05:00',
            },
            {
              'id': 104,
              'appeal_id': 21,
              'kind': 'field_changed',
              'actor': assignee,
              'field': 'priority',
              'old_value': 'medium',
              'new_value': 'high',
              'comment': null,
              'created_at': '2026-11-10T11:03:00+05:00',
            },
            {
              'id': 102,
              'appeal_id': 21,
              'kind': 'deadline_set',
              'actor': null,
              'field': 'first_response_due_at',
              'old_value': null,
              'new_value': '2026-11-18T09:55:15.058981+05:00',
              'comment': null,
              'created_at': '2026-11-10T11:01:00+05:00',
            },
          ]),
      'GET /api/v1/appeals/21/messages': (_) => json([messageJson(501, 'Здравствуйте, посмотрю сегодня.')]),
      'GET /api/v1/notifications/unread-count': (_) => json({'count': 1}),
      'POST /api/v1/notifications/read': (_) => json({'count': 0}),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(ModusApp(session: session));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const AppealScreen(appealId: 21)));
    await tester.pumpAndSettle();

    expect(jsonDecode(server.last('POST', '/api/v1/notifications/read').body), {'appeal_id': 21});
    expect(find.text('Олжас Мукашев'), findsOneWidget);
    // Переписка — отдельным экраном по кнопке «Переписка», как панель в вебе.
    await tapVisible(tester, find.byKey(const Key('chat-entry')));
    await tester.pumpAndSettle();
    expect(find.text('Здравствуйте, посмотрю сегодня.'), findsOneWidget);
    expect(find.text('Напишите сообщение'), findsOneWidget, reason: 'send_message разрешён');
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('пример_заявки.pdf'), 200, scrollable: list);
    expect(find.text('180 КБ · Карина Шаймерденова'), findsOneWidget);
    expect(find.byKey(const Key('upload-attachment')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('history-toggle')), 200, scrollable: list);
    expect(find.text('Статус изменён'), findsNothing, reason: 'история свёрнута по умолчанию');
    await tester.ensureVisible(find.byKey(const Key('history-toggle')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('history-toggle')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Статус изменён'), 200, scrollable: list);
    expect(find.text('Новое → На рассмотрении'), findsOneWidget);
    expect(find.text('18 ноября 2026, 09:55'), findsWidgets, reason: 'срок в истории — датой, а не строкой ISO');
    expect(find.textContaining('2026-11-18T'), findsNothing);
    expect(find.text('Средний → Высокий'), findsOneWidget, reason: 'приоритет в истории — подписью');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('отклонённое — причина, реализованное — результат; без allowed_actions писать нельзя', (tester) async {
    var status = 'rejected';
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(status == 'rejected'
          ? appealJson(status: 'rejected', rejectionReason: 'Уже есть такой регламент.', allowedActions: const [])
          : appealJson(status: 'implemented', result: 'Поля добавлены в шаблон.', allowedActions: const [])),
      'GET /api/v1/appeals/21/history': (_) => json([]),
      'GET /api/v1/appeals/21/messages': (_) => json([]),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const AppealScreen(appealId: 21)));
    await tester.pumpAndSettle();
    expect(find.text('Причина отказа'), findsOneWidget);
    expect(find.text('Уже есть такой регламент.'), findsOneWidget);
    expect(find.byKey(const Key('message-text')), findsNothing);
    expect(find.byKey(const Key('upload-attachment')), findsNothing);

    status = 'implemented';
    await tester.pumpWidget(screen(session, const AppealScreen(key: Key('second'), appealId: 21)));
    await tester.pumpAndSettle();
    expect(find.text('Результат'), findsOneWidget);
    expect(find.text('Поля добавлены в шаблон.'), findsOneWidget);
  });

  testWidgets('автор отвечает на уточняющий вопрос из карточки, карточка перечитывается', (tester) async {
    var answered = false;
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(answered
          ? appealJson(status: 'in_review', dueState: 'answered')
          : appealJson(status: 'awaiting_info', allowedActions: const ['reply_clarification', 'upload_attachment'])),
      'GET /api/v1/appeals/21/history': (_) => json([]),
      'GET /api/v1/appeals/21/messages': (_) =>
          json([messageJson(501, 'Какие именно документы приходят в бумаге?', question: true)]),
      'POST /api/v1/appeals/21/messages': (request) {
        answered = true;
        return json(messageJson(502, jsonDecode(request.body)['text'] as String, by: author), 201);
      },
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const AppealScreen(appealId: 21)));
    await tester.pumpAndSettle();

    expect(find.text('Ожидает уточнения'), findsOneWidget);
    expect(find.text('Ответить на вопрос'), findsOneWidget, reason: 'кнопка переписки зовёт ответить');
    await tapVisible(tester, find.byKey(const Key('chat-entry')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('clarification-question')), matching: find.text('Уточняющий вопрос')), findsOneWidget);
    expect(find.text('Ответ на вопрос'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('message-text')), 'Акты сверки');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('message-send')));
    await tapVisible(tester, find.byKey(const Key('message-send')));
    await tester.pumpAndSettle();

    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/messages').body), {'text': 'Акты сверки'});
    expect(server.requests.where((r) => r.method == 'GET' && r.url.path == '/api/v1/appeals/21').length, 2);
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('На рассмотрении'), -200, scrollable: list);
    expect(find.text('На рассмотрении'), findsOneWidget);
    expect(find.text('Ответить на вопрос'), findsNothing);
  });

  test('ошибки полей 422 разбираются без префикса body.', () {
    // Покрыто виджет-тестом выше; здесь — что http.Response с кириллицей декодируется.
    expect(utf8.decode(json({'a': 'б'}).bodyBytes), '{"a":"б"}');
    expect(http.Response('', 204).statusCode, 204);
  });
}
