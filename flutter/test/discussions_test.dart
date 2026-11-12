import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/appeals/deadline.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/appeals/appeal_screen.dart';
import 'package:modus_feedback/ui/discussions/discussion_screen.dart';
import 'package:modus_feedback/ui/discussions/feed_screen.dart';

import 'package:modus_feedback/ui/web/web_ui.dart';
import 'fixtures.dart';

Future<SessionController> signedIn(FakeServer server, [Map<String, dynamic>? me]) async {
  server.routes['GET /api/v1/me'] = (_) => json(me ?? meJson());
  server.routes['GET /api/v1/dictionaries'] = (_) => json(dictionariesJson);
  server.routes['GET /api/v1/discussions/9/comments'] ??= (_) => json([
        {'id': 1, 'discussion_id': 9, 'author': assignee, 'text': 'Поддерживаю', 'created_at': '2026-11-10T13:00:00+05:00'},
      ]);
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

  test('срок обсуждения — 18:00 по UTC+5 выбранного дня', () {
    expect(deadlineFromDate(DateTime(2026, 11, 13)).toIso8601String(), '2026-11-13T13:00:00.000Z');
    expect(systemToday(DateTime.utc(2026, 11, 10, 20)), DateTime(2026, 11, 11), reason: '20:00 UTC — уже 11-е по UTC+5');
  });

  testWidgets('вынос на обсуждение: формулировка и срок, ссылка появляется в карточке', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(status: 'in_review', allowedActions: const ['publish_discussion'])),
      'GET /api/v1/appeals/21/history': (_) => json([]),
      'GET /api/v1/appeals/21/messages': (_) => json([]),
      'GET /api/v1/appeals/21/similar': (_) => json([]),
      'POST /api/v1/appeals/21/discussion': (_) => json(discussionJson(), 201),
    });
    final session = await signedIn(server, meJson(id: 3, role: 'head', permissions: headPermissions));
    await tester.pumpWidget(screen(session, const AppealScreen(appealId: 21)));
    await tester.pumpAndSettle();

    await tapAction(tester, 'publish_discussion');
    await tester.pumpAndSettle();
    final text = tester.widget<TextField>(find.byKey(const Key('discussion-text')));
    expect(text.controller!.text, 'В заявках на оборудование не хватает параметров', reason: 'подставлена суть');
    await tester.enterText(find.byKey(const Key('discussion-text')), 'Обязательные поля в заявке');
    await tester.pump();
    await tapVisible(tester, find.byKey(const Key('discussion-publish')));
    await tester.pumpAndSettle();

    final body = jsonDecode(server.last('POST', '/api/v1/appeals/21/discussion').body) as Map;
    expect(body['public_text'], 'Обязательные поля в заявке');
    expect(DateTime.parse(body['deadline'] as String).toUtc().hour, 13, reason: '18:00 по UTC+5');
    expect(find.byKey(const Key('discussion-link')), findsOneWidget);
    expect(find.byKey(const Key('action-publish_discussion')), findsNothing, reason: 'второй раз не выносим');
  });

  testWidgets('лента: открытые обсуждения со счётом и сроком, вкладка «Реализовано»', (tester) async {
    final server = FakeServer({
      'GET /api/v1/discussions': (r) => json({
            'items': [
              if (r.url.queryParameters['status'] == 'open') discussionJson(myVote: 'for'),
              if (r.url.queryParameters['status'] == 'closed') discussionJson(id: 8, status: 'closed', outcome: 'Внедряем.'),
            ],
            'total': 1,
            'page': 1,
            'page_size': 50,
          }),
      'GET /api/v1/feed/implemented': (_) => json({
            'items': [
              {
                'appeal_id': 4,
                'number': 'A-004',
                'type': 'suggestion',
                'category': {'id': 2, 'name': 'Документооборот'},
                'department': null,
                'public_summary': 'Сверять акты раз в месяц',
                'result': 'Ввели ежемесячную сверку',
                'author_display': 'Дина Жуматова, Бухгалтерия',
                'implemented_at': '2026-11-08T15:00:00+05:00',
                'discussion_id': null,
              },
            ],
            'total': 1,
            'page': 1,
            'page_size': 50,
          }),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const FeedScreen()));
    await tester.pumpAndSettle();

    expect(server.last('GET', '/api/v1/discussions').url.queryParameters['status'], 'open');
    expect(find.text('Добавить обязательные поля в шаблон заявки на оборудование'), findsOneWidget);
    expect(find.text('до 13 ноября 2026, 18:00'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2 комментария'), findsOneWidget);
    expect(find.text('вы проголосовали «за»'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('tab-implemented')));
    await tester.pumpAndSettle();
    expect(find.text('Что предложили'), findsOneWidget);
    expect(find.text('Сверять акты раз в месяц'), findsOneWidget);
    expect(find.text('Ввели ежемесячную сверку'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('tab-closed')));
    await tester.pumpAndSettle();
    expect(find.text('Итог: Внедряем.'), findsOneWidget);
  });

  testWidgets('голос «за», смена на «против» и отзыв повторным нажатием', (tester) async {
    String? myVote;
    final server = FakeServer({
      'GET /api/v1/discussions/9': (_) => json(discussionJson(myVote: myVote)),
      'PUT /api/v1/discussions/9/vote': (r) {
        myVote = (jsonDecode(r.body) as Map)['value'] as String;
        return json(discussionJson(myVote: myVote, votesFor: myVote == 'for' ? 5 : 4, votesAgainst: myVote == 'against' ? 2 : 1));
      },
      'DELETE /api/v1/discussions/9/vote': (_) {
        myVote = null;
        return json(discussionJson());
      },
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const DiscussionScreen(discussionId: 9)));
    await tester.pumpAndSettle();
    expect(find.text('За 4'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('vote-for')));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('PUT', '/api/v1/discussions/9/vote').body), {'value': 'for'});
    expect(find.text('За 5'), findsOneWidget);
    expect(find.text('Нажмите на свой голос ещё раз, чтобы отозвать.'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('vote-against')));
    await tester.pumpAndSettle();
    expect(find.text('Против 2'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('vote-against')));
    await tester.pumpAndSettle();
    expect(server.requests.where((r) => r.method == 'DELETE').length, 1);
    expect(find.text('Против 1'), findsOneWidget);
  });

  testWidgets('комментарий уходит и появляется в списке', (tester) async {
    final server = FakeServer({
      'GET /api/v1/discussions/9': (_) => json(discussionJson()),
      'POST /api/v1/discussions/9/comments': (r) => json({
            'id': 2,
            'discussion_id': 9,
            'author': author,
            'text': (jsonDecode(r.body) as Map)['text'],
            'created_at': '2026-11-10T14:00:00+05:00',
          }, 201),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const DiscussionScreen(discussionId: 9)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('comment-text')), 200, scrollable: list);
    expect(find.text('Поддерживаю'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('comment-text')), 'У нас то же самое');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('comment-send')));
    await tapVisible(tester, find.byKey(const Key('comment-send')));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/discussions/9/comments').body), {'text': 'У нас то же самое'});
    expect(find.text('У нас то же самое'), findsOneWidget);
  });

  testWidgets('автор отвечает на запрос о показе имени', (tester) async {
    final server = FakeServer({
      'GET /api/v1/discussions/9': (_) => json(discussionJson(canSetNameConsent: true, canVote: false)),
      'POST /api/v1/discussions/9/name-consent': (_) =>
          json(discussionJson(canSetNameConsent: true, canVote: false, consent: 'shown', authorDisplay: 'Айгерим Нурланова, Закупки')),
    });
    final session = await signedIn(server);
    await tester.pumpWidget(screen(session, const DiscussionScreen(discussionId: 9)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Показывать ваше имя?'), findsOneWidget);
    expect(find.text('Ваше обращение A-021'), findsOneWidget);
    expect(find.text('Не показывать'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('consent-show')));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/discussions/9/name-consent').body), {'show_name': true});
    expect(find.text('Ваше имя показано в обсуждении.'), findsOneWidget);
    expect(find.text('Скрыть имя'), findsOneWidget);
    expect(find.byKey(const Key('consent-show')), findsNothing);
  });

  testWidgets('руководитель фиксирует итог; без итога кнопка неактивна', (tester) async {
    final server = FakeServer({
      'GET /api/v1/discussions/9': (_) => json(discussionJson(canClose: true)),
      'POST /api/v1/discussions/9/close': (_) =>
          json(discussionJson(status: 'closed', outcome: 'Добавляем поля с 1 декабря.', canVote: false)),
    });
    final session = await signedIn(server, meJson(id: 3, role: 'head', permissions: headPermissions));
    await tester.pumpWidget(screen(session, const DiscussionScreen(discussionId: 9)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('close-open')), 200, scrollable: list);
    await tapVisible(tester, find.byKey(const Key('close-open')));
    await tester.pumpAndSettle();
    expect(tester.widget<WebButton>(find.byKey(const Key('close-submit'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('close-outcome')), 'Добавляем поля с 1 декабря.');
    await tester.pump();
    await tapVisible(tester, find.byKey(const Key('close-submit')));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/discussions/9/close').body), {'outcome': 'Добавляем поля с 1 декабря.'});
    await tester.scrollUntilVisible(find.byKey(const Key('discussion-outcome')), -200, scrollable: list);
    expect(find.text('Добавляем поля с 1 декабря.'), findsOneWidget);
    expect(find.text('Обсуждение завершено'), findsOneWidget);
    expect(find.byKey(const Key('comment-text')), findsNothing, reason: 'в завершённом не комментируют');
  });
}
