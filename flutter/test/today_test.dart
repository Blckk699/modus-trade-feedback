import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/app.dart';
import 'package:modus_feedback/api/api_service.dart';
import 'package:modus_feedback/session/session_controller.dart';
import 'package:modus_feedback/session/session_store.dart';
import 'package:modus_feedback/ui/home/today_screen.dart';

import 'fixtures.dart';

TodayData data({
  int? assignedOpen,
  int assignedOverdue = 0,
  int? unassignedTotal,
  int discussions = 0,
}) =>
    TodayData(
      queue: const [],
      assignedOpen: assignedOpen,
      assignedOverdue: assignedOverdue,
      awaitingMe: const [],
      unassigned: const [],
      unassignedTotal: unassignedTotal,
      accessRequests: null,
      summary: null,
      discussions: const <Discussion>[],
      discussionsTotal: discussions,
      loadedAt: DateTime(2026, 11, 12, 18),
    );

void main() {
  setUpAll(() => initializeDateFormatting('ru'));

  test('главное на сейчас — фразы из чисел, как buildBrief в вебе', () {
    expect(buildBrief(data(assignedOpen: 3, assignedOverdue: 1, unassignedTotal: 2, discussions: 1)), [
      'У вас 3 обращения в работе, 1 просрочено.',
      '2 обращения ждут ответственного.',
      'Идёт 1 обсуждение, можно проголосовать.',
    ]);
    expect(buildBrief(data()).first, 'Срочного нет.');
  });

  test('приветствие по времени UTC+5 и первому слову имени', () {
    expect(greeting('Александр Кислянский', DateTime.utc(2026, 11, 12, 14)), 'Добрый вечер, Александр');
    expect(greeting('Карина Шаймерденова', DateTime.utc(2026, 11, 12, 3)), 'Доброе утро, Карина');
  });

  testWidgets('администратор: «Ждёт вас» с обращением без ответственного', (tester) async {
    final server = FakeServer({
      'GET /api/v1/me': (_) => json(meJson(id: 2, role: 'admin', fullName: 'Ксения Гарипова', permissions: adminPermissions)),
      'GET /api/v1/dictionaries': (_) => json(dictionariesJson),
      'GET /api/v1/appeals': (r) => json({
            'items': r.url.queryParameters['scope'] == 'unassigned' || r.url.queryParameters['scope'] == 'all'
                ? [appealJson(id: 25, number: 'A-025', assigneeJson: null, summary: 'Нет воды')]
                : [],
            'total': 1,
            'page': 1,
            'page_size': 5,
          }),
      'GET /api/v1/discussions': (_) => json({'items': [], 'total': 0, 'page': 1, 'page_size': 4}),
      'GET /api/v1/admin/access-requests': (_) => json({'items': [], 'total': 0, 'page': 1, 'page_size': 1}),
      'GET /api/v1/analytics/summary': (_) => json(errorJson('forbidden', 'Нет доступа.'), 403),
      'GET /api/v1/notifications/unread-count': (_) => json({'count': 0}),
    });
    final session = SessionController(
      api: ApiService(baseUrl: 'http://mock.test', httpClient: server.client),
      store: MemorySessionStore(serverUrl: 'http://mock.test', token: 't', tokenServer: 'http://mock.test'),
    );
    await session.restore();
    await tester.pumpWidget(ModusApp(session: session));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ксения'), findsWidgets);
    expect(find.textContaining('1 обращение ждёт ответственного.'), findsOneWidget);
    expect(find.text('Ждёт вас'), findsOneWidget);
    expect(find.text('Ответственного нет: выберите, кто ответит.'), findsOneWidget);
  });
}
