import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/appeals/attachment_files.dart';
import 'package:modus_feedback/navigation/sections.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/meetings/meeting_screen.dart';
import 'package:modus_feedback/ui/meetings/meetings_screen.dart';

import 'package:modus_feedback/ui/web/web_ui.dart';
import 'fixtures.dart';

Map<String, dynamic> draftJson({int id = 1, String status = 'pending', Map<String, dynamic>? appeal, String summary = 'Документы теряются между отделами'}) => {
      'id': id,
      'meeting_id': 5,
      'status': status,
      'type': 'problem',
      'category': {'id': 1, 'name': 'Межотдельное взаимодействие'},
      'priority': 'medium',
      'summary': summary,
      'text': 'На планёрке говорили, что акты сверки теряются при передаче.',
      'proposed_solution': null,
      'quote': 'опять акты сверки потерялись между нами и бухгалтерией',
      'author': null,
      'appeal': appeal,
    };

Map<String, dynamic> meetingJson({String status = 'ready', List<Map<String, dynamic>>? drafts, String? error}) => {
      'id': 5,
      'title': 'Планёрка закупок',
      'status': status,
      'error': error,
      'transcript': status == 'ready' ? 'Расшифровка встречи…' : null,
      'uploaded_by': assignee,
      'drafts': drafts ?? (status == 'ready' ? [draftJson(), draftJson(id: 2)] : []),
      'created_at': '2026-11-10T10:00:00+05:00',
    };

Future<SessionController> signedIn(FakeServer server) async {
  server.routes['GET /api/v1/me'] = (_) => json(meJson(id: 1, role: 'owner', permissions: ownerPermissions));
  server.routes['GET /api/v1/dictionaries'] = (_) => json(dictionariesJson);
  server.routes['GET /api/v1/categories'] ??= (_) => json(categoriesJson);
  server.routes['GET /api/v1/users'] ??= (_) => json(usersJson);
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 'token', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  return session;
}

Widget screen(SessionController session, Widget child) =>
    SessionScope(controller: session, child: MaterialApp(home: child));

final list = find.byType(Scrollable).first;

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('раздел «Совещания» только с can_upload_meetings', () {
    expect(sectionsFor(Me.fromJson(meJson(id: 1, role: 'owner', permissions: ownerPermissions))!),
        contains(Section.meetings));
    expect(sectionsFor(Me.fromJson(meJson())!), isNot(contains(Section.meetings)));
    expect(sectionsFor(Me.fromJson(meJson(id: 3, role: 'head', permissions: headPermissions))!),
        isNot(contains(Section.meetings)), reason: 'у руководителя из фикстуры право выключено');
  });

  testWidgets('загрузка записи: multipart с названием, переход к совещанию, опрос до ready', (tester) async {
    final file = File('${Directory.systemTemp.createTempSync('modus').path}/plan.m4a')..writeAsBytesSync([1, 2, 3, 4]);
    var polls = 0;
    final server = FakeServer({
      'GET /api/v1/meetings': (_) => json([]),
      'POST /api/v1/meetings': (_) => json(meetingJson(status: 'processing'), 202),
      'GET /api/v1/meetings/5': (_) {
        polls++;
        if (polls == 2) throw Exception('сбой сети');
        return json(meetingJson(status: polls < 3 ? 'processing' : 'ready'));
      },
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(
      session,
      MeetingsScreen(pickAudio: () async => PickedFile(name: 'plan.m4a', path: file.path, size: 4)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Вы ещё не загружали записи.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('meeting-upload'))).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('meeting-title')), 'Планёрка закупок');
    await tester.tap(find.byKey(const Key('meeting-pick')));
    await tester.pumpAndSettle();
    expect(find.text('plan.m4a · 4 Б'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('meeting-upload')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final upload = server.last('POST', '/api/v1/meetings');
    expect(upload.headers['content-type'], startsWith('multipart/form-data'));
    final body = utf8.decode(upload.bodyBytes, allowMalformed: true);
    expect(body, contains('Планёрка закупок'));
    expect(body, contains('plan.m4a'));
    expect(find.byKey(const Key('meeting-processing')), findsOneWidget);

    // Опрос раз в 3 секунды; сбой второго опроса экран не ломает.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byKey(const Key('meeting-processing')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(polls, 3);
    expect(find.textContaining('Черновиков: 2. Ждут решения: 2.'), findsOneWidget);
  });

  testWidgets('черновик: тип, категория, суть и цитата; подтверждение создаёт обращение', (tester) async {
    final server = FakeServer({
      'GET /api/v1/meetings/5': (_) => json(meetingJson()),
      'POST /api/v1/meetings/5/drafts/1/confirm': (_) => json(appealJson(id: 30, number: 'A-030')),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const MeetingScreen(meetingId: 5)));
    await tester.pumpAndSettle();

    expect(find.text('Проблема · Межотдельное взаимодействие · Средний'), findsNWidgets(2));
    expect(find.text('«опять акты сверки потерялись между нами и бухгалтерией»'), findsNWidgets(2));
    expect(find.text('Автор: вы (загрузивший запись)'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('draft-confirm-1')));
    await tester.pumpAndSettle();
    final body = jsonDecode(server.last('POST', '/api/v1/meetings/5/drafts/1/confirm').body) as Map;
    expect(body['summary'], 'Документы теряются между отделами');
    expect(body['author_id'], isNull);
    expect(find.text('Создано обращение A-030'), findsOneWidget);
    expect(find.text('Подтверждён'), findsOneWidget);
    expect(find.textContaining('Ждут решения: 1'), findsOneWidget);
  });

  testWidgets('правка: автор из сотрудников, сохранение PATCH; без сути подтвердить нельзя', (tester) async {
    final server = FakeServer({
      'GET /api/v1/meetings/5': (_) => json(meetingJson(drafts: [draftJson()])),
      'PATCH /api/v1/meetings/5/drafts/1': (r) {
        final b = jsonDecode(r.body) as Map;
        return json({
          ...draftJson(),
          'summary': b['summary'],
          'author': {'id': 5, 'full_name': 'Ольга Петрова', 'role': 'employee', 'department': {'id': 2, 'name': 'Бухгалтерия'}},
        });
      },
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const MeetingScreen(meetingId: 5)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('draft-more-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('draft-edit-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('draft-summary')), '');
    await tester.pump();
    expect(tester.widget<WebButton>(find.byKey(const Key('draft-save-1'))).onPressed, isNull, reason: 'без сути не сохранить');

    await tester.enterText(find.byKey(const Key('draft-summary')), 'Акты сверки теряются');
    await tester.scrollUntilVisible(find.byKey(const Key('draft-author-true')), -100, scrollable: list);
    await tester.tap(find.byKey(const Key('draft-author-true')));
    await tester.pumpAndSettle();
    expect(find.text('Уволенный'), findsNothing, reason: 'отключённые скрыты');
    await tester.tap(find.text('Ольга Петрова — Бухгалтерия').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('draft-save-1')), 200, scrollable: list);
    await tester.tap(find.byKey(const Key('draft-save-1')));
    await tester.pumpAndSettle();

    final body = jsonDecode(server.last('PATCH', '/api/v1/meetings/5/drafts/1').body) as Map;
    expect(body['summary'], 'Акты сверки теряются');
    expect(body['author_id'], 5);
    await tester.scrollUntilVisible(find.text('Автор: Ольга Петрова'), -200, scrollable: list);
    expect(find.text('Акты сверки теряются'), findsOneWidget);
  });

  testWidgets('черновик без сути подтвердить нельзя', (tester) async {
    final server = FakeServer({
      'GET /api/v1/meetings/5': (_) => json(meetingJson(drafts: [draftJson(summary: '')])),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const MeetingScreen(meetingId: 5)));
    await tester.pumpAndSettle();
    expect(tester.widget<WebButton>(find.byKey(const Key('draft-confirm-1'))).onPressed, isNull);
  });

  testWidgets('отбросить черновик; ошибка обработки показана', (tester) async {
    final server = FakeServer({
      'GET /api/v1/meetings/5': (_) => json(meetingJson(drafts: [draftJson()])),
      'POST /api/v1/meetings/5/drafts/1/discard': (_) => json(draftJson(status: 'discarded')),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const MeetingScreen(meetingId: 5)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('draft-more-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('draft-discard-1')));
    await tester.pumpAndSettle();
    expect(find.text('Отброшен'), findsOneWidget);
    expect(find.text('Все черновики разобраны (1).'), findsOneWidget);
    expect(find.byKey(const Key('draft-confirm-1')), findsNothing);

    server.routes['GET /api/v1/meetings/5'] =
        (_) => json(meetingJson(status: 'failed', error: 'Запись пустая или не распознана.'));
    await tester.pumpWidget(screen(session, const MeetingScreen(key: Key('failed'), meetingId: 5)));
    await tester.pumpAndSettle();
    expect(find.text('Запись пустая или не распознана. Попробуйте загрузить её ещё раз.'), findsOneWidget);
  });

  testWidgets('список совещаний: статус и число черновиков', (tester) async {
    final server = FakeServer({
      'GET /api/v1/meetings': (_) => json([
            {
              'id': 5,
              'title': 'Планёрка закупок',
              'status': 'ready',
              'drafts_total': 3,
              'drafts_pending': 1,
              'uploaded_by': assignee,
              'created_at': '2026-11-10T10:00:00+05:00',
            },
          ]),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const MeetingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('10 ноября 2026, 10:00 · черновиков: 3, ждут решения: 1'), findsOneWidget);
  });
}
