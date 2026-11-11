import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/appeals/queue_scopes.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/appeals/appeal_screen.dart';
import 'package:modus_feedback/ui/appeals/queue_screen.dart';

import 'fixtures.dart';

Future<SessionController> signedIn(FakeServer server, Map<String, dynamic> me) async {
  server.routes['GET /api/v1/me'] = (_) => json(me);
  server.routes['GET /api/v1/dictionaries'] = (_) => json(dictionariesJson);
  final session = SessionController(
    api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
    store: MemorySessionStore(serverUrl: 'http://mock.test', token: 'token', tokenServer: 'http://mock.test'),
  );
  await session.restore();
  return session;
}

Widget screen(SessionController session, Widget child) =>
    SessionScope(controller: session, child: MaterialApp(home: child));

Me me(Map<String, dynamic> json) => Me.fromJson(json)!;

final list = find.byType(Scrollable).first;

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  group('охваты очереди как в вебе', () {
    test('собственник: подразделение, все, нераспределённые, назначенные; старт — все', () {
      final owner = me(meJson(id: 1, role: 'owner', permissions: ownerPermissions));
      expect(queueScopes(owner),
          [AppealScope.department, AppealScope.all, AppealScope.unassigned, AppealScope.assigned]);
      expect(defaultQueueScope(owner), AppealScope.all);
    });

    test('руководитель — подразделение, администратор — нераспределённые, ответственный — назначенные', () {
      expect(defaultQueueScope(me(meJson(id: 3, role: 'head', permissions: headPermissions))), AppealScope.department);
      expect(defaultQueueScope(me(meJson(id: 2, role: 'admin', permissions: adminPermissions))), AppealScope.unassigned);
      expect(queueScopes(me(meJson())), [AppealScope.assigned]);
    });

    test('оставшееся время до срока', () {
      final now = DateTime.utc(2026, 11, 10, 10);
      expect(timeLeftLabel(DateTime.utc(2026, 11, 11, 13, 30), now), 'осталось 1 д 3 ч');
      expect(timeLeftLabel(DateTime.utc(2026, 11, 10, 12, 15), now), 'осталось 2 ч 15 мин');
      expect(timeLeftLabel(DateTime.utc(2026, 11, 10, 9, 20), now), 'просрочено на 40 мин');
    });
  });

  testWidgets('очередь: по сроку, открытые статусы, просроченное выделено; фильтры уходят в запрос', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals': (_) => json({
            'items': [
              appealJson(id: 1, number: 'A-001', dueState: 'overdue'),
              appealJson(id: 2, number: 'A-002', status: 'in_review', dueState: 'answered'),
            ],
            'total': 2,
            'page': 1,
            'page_size': 30,
          }),
      'GET /api/v1/categories': (_) => json(categoriesJson),
      'GET /api/v1/departments': (_) => json([
            {'id': 1, 'name': 'Закупки', 'head': null},
            {'id': 2, 'name': 'Бухгалтерия', 'head': null},
          ]),
    });
    final session = await signedIn(server, meJson(id: 1, role: 'owner', permissions: ownerPermissions));
    await tester.pumpWidget(screen(session, const QueueScreen()));
    await tester.pumpAndSettle();

    var query = server.last('GET', '/api/v1/appeals').url.queryParametersAll;
    expect(query['scope'], ['all']);
    expect(query['sort'], ['due_asc']);
    expect(query['status'], ['new', 'in_review', 'awaiting_info', 'in_progress']);
    expect(find.byKey(const Key('time-left-1')), findsOneWidget);
    // Выделение — по due_state от бэкенда: у просроченной строки цветной фон.
    final overdueRow = tester.widget<Material>(
        find.ancestor(of: find.byKey(const Key('queue-1')), matching: find.byType(Material)).first);
    final normalRow = tester.widget<Material>(
        find.ancestor(of: find.byKey(const Key('queue-2')), matching: find.byType(Material)).first);
    expect(overdueRow.color, isNot(Colors.transparent));
    expect(normalRow.color, Colors.transparent);
    expect(find.byKey(const Key('time-left-2')), findsNothing, reason: 'первый ответ уже дан');

    await tester.tap(find.byKey(const Key('scope-unassigned')));
    await tester.pumpAndSettle();
    expect(server.last('GET', '/api/v1/appeals').url.queryParameters['scope'], 'unassigned');

    await tester.tap(find.byKey(const Key('queue-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ожидает уточнения').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-due')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Просрочено').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-category-true')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Межотдельное взаимодействие').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-department-true')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бухгалтерия').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filters-apply')));
    await tester.pumpAndSettle();

    query = server.last('GET', '/api/v1/appeals').url.queryParametersAll;
    expect(query['scope'], ['unassigned']);
    expect(query['status'], ['awaiting_info']);
    expect(query['due'], ['overdue']);
    expect(query['category_id'], ['1']);
    expect(query['department_id'], ['2']);
    expect(find.descendant(of: find.byKey(const Key('queue-filters')), matching: find.text('4')), findsOneWidget);
  });

  testWidgets('руководитель не видит фильтр подразделения', (tester) async {
    final server = FakeServer({
      'GET /api/v1/appeals': (_) => json({'items': [], 'total': 0, 'page': 1, 'page_size': 30}),
      'GET /api/v1/categories': (_) => json(categoriesJson),
    });
    final session = await signedIn(server, meJson(id: 3, role: 'head', permissions: headPermissions));
    await tester.pumpWidget(screen(session, const QueueScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Обращений нет.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('queue-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-department-false')), findsNothing);
    expect(find.byKey(const Key('filter-department-true')), findsNothing);
  });

  /// Карточка ответственного с заданными allowed_actions; действие возвращает обновлённое обращение.
  Future<FakeServer> openCard(WidgetTester tester, List<String> actions, {Map<String, dynamic>? updated}) async {
    final server = FakeServer({
      'GET /api/v1/appeals/21': (_) => json(appealJson(allowedActions: actions)),
      'GET /api/v1/appeals/21/history': (_) => json([]),
      'GET /api/v1/appeals/21/messages': (_) => json([]),
      'GET /api/v1/users': (_) => json(usersJson),
    });
    for (final path in ['take', 'request-info', 'start-work', 'reject', 'implement', 'accept-feedback', 'reassign']) {
      server.routes['POST /api/v1/appeals/21/$path'] = (_) => json(updated ?? appealJson(status: 'in_review'));
    }
    final session = await signedIn(server, meJson(id: 3, role: 'head', permissions: headPermissions));
    await tester.pumpWidget(screen(session, const AppealScreen(appealId: 21)));
    await tester.pumpAndSettle();
    return server;
  }

  testWidgets('показаны только действия из allowed_actions', (tester) async {
    await openCard(tester, ['take', 'reassign', 'send_message']);
    expect(find.byKey(const Key('action-take')), findsOneWidget);
    expect(find.byKey(const Key('action-reassign')), findsOneWidget);
    for (final hidden in ['request_info', 'start_work', 'reject', 'implement', 'accept_feedback']) {
      expect(find.byKey(Key('action-$hidden')), findsNothing, reason: hidden);
    }
    expect(find.text('Взять на рассмотрение'), findsOneWidget, reason: 'подпись из справочника');
  });

  testWidgets('взять: необязательный ответ, карточка обновляется ответом сервера', (tester) async {
    final server = await openCard(tester, ['take']);
    await tester.tap(find.byKey(const Key('action-take')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('action-submit')));
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/take').body), {'comment': null});
    expect(find.text('На рассмотрении'), findsOneWidget);
    expect(find.byKey(const Key('action-take')), findsNothing, reason: 'в новом обращении действия нет');
  });

  testWidgets('отклонить без причины нельзя; причина уходит в запрос; ошибка сервера видна', (tester) async {
    final server = await openCard(tester, ['reject'], updated: appealJson(status: 'rejected', rejectionReason: 'Нет бюджета.'));
    await tester.tap(find.byKey(const Key('action-reject')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('action-submit'));
    expect(tester.widget<ButtonStyleButton>(submit).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('action-text')), '  Нет бюджета.  ');
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(submit).onPressed, isNotNull);

    server.routes['POST /api/v1/appeals/21/reject'] = (_) => json(
        errorJson('invalid_transition', 'Обращение уже в другом статусе.'), 409);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Обращение уже в другом статусе.'), findsOneWidget);

    server.routes['POST /api/v1/appeals/21/reject'] =
        (_) => json(appealJson(status: 'rejected', rejectionReason: 'Нет бюджета.'));
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/reject').body), {'reason': 'Нет бюджета.'});
    expect(find.text('Причина отказа'), findsOneWidget);
  });

  testWidgets('вопрос, в работу и принять отзыв отправляют свои поля', (tester) async {
    final server = await openCard(tester, ['request_info', 'start_work', 'accept_feedback'],
        updated: appealJson(allowedActions: const ['request_info', 'start_work', 'accept_feedback']));
    Future<void> run(String action, String? text) async {
      await tester.tap(find.byKey(Key('action-$action')));
      await tester.pumpAndSettle();
      if (text != null) await tester.enterText(find.byKey(const Key('action-text')), text);
      await tester.pump();
      await tester.tap(find.byKey(const Key('action-submit')));
      await tester.pumpAndSettle();
    }

    await run('request_info', 'Какие документы?');
    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/request-info').body), {'question': 'Какие документы?'});
    await run('start_work', 'Добавим поля');
    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/start-work').body), {'decision': 'Добавим поля'});
    await run('accept_feedback', 'Спасибо!');
    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/accept-feedback').body), {'comment': 'Спасибо!'});
  });

  testWidgets('реализовано без результата нельзя; публичные формулировки необязательны', (tester) async {
    final server = await openCard(tester, ['implement'], updated: appealJson(status: 'implemented', result: 'Поля добавлены.'));
    await tester.tap(find.byKey(const Key('action-implement')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('action-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('implement-result')), 'Поля добавлены.');
    await tester.enterText(find.byKey(const Key('implement-public-result')), 'Шаблон заявки дополнен');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/implement').body), {
      'result': 'Поля добавлены.',
      'public_summary': null,
      'public_result': 'Шаблон заявки дополнен',
    });
    expect(find.text('Результат'), findsOneWidget);
  });

  testWidgets('переназначение: сотрудник и причина обязательны; админы, отключённые и текущий скрыты', (tester) async {
    final server = await openCard(tester, ['reassign']);
    await tester.tap(find.byKey(const Key('action-reassign')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('action-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const Key('reassign-user')));
    await tester.pumpAndSettle();
    expect(find.text('Анна Ли'), findsNothing);
    expect(find.text('Уволенный'), findsNothing);
    expect(find.textContaining('Марат Сейткали —'), findsNothing, reason: 'текущий ответственный');
    await tester.tap(find.text('Ольга Петрова — Бухгалтерия (отсутствует)').last);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull, reason: 'нет причины');
    await tester.enterText(find.byKey(const Key('reassign-reason')), 'Вопрос бухгалтерии');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(jsonDecode(server.last('POST', '/api/v1/appeals/21/reassign').body),
        {'assignee_id': 5, 'reason': 'Вопрос бухгалтерии'});
  });
}
