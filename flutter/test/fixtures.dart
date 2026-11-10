import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Ответы по примерам из contract/openapi.yaml.
Map<String, dynamic> meJson({
  int id = 4,
  String role = 'employee',
  String fullName = 'Айгерим Нурланова',
  Map<String, dynamic>? permissions,
  int assignedOpenCount = 0,
}) =>
    {
      'id': id,
      'telegram_id': 100000000 + id,
      'full_name': fullName,
      'position': 'Сотрудник закупок',
      'role': role,
      'department': role == 'owner' || role == 'admin' ? null : {'id': 1, 'name': 'Закупки'},
      'is_absent': false,
      'is_disabled': false,
      'responsible_for': <dynamic>[],
      'deputy_for': [
        {'id': 1, 'name': 'Межотдельное взаимодействие'},
      ],
      'assigned_open_count': assignedOpenCount,
      'permissions': permissions ?? employeePermissions,
    };

const employeePermissions = {
  'can_create_appeal': true,
  'can_process_appeals': true,
  'can_view_department': false,
  'can_view_all_appeals': false,
  'analytics_scope': 'none',
  'can_upload_meetings': false,
  'can_manage_settings': false,
  'can_view_unassigned': false,
};

final plainEmployeePermissions = <String, Object>{
  ...employeePermissions,
  'can_process_appeals': false,
};

const ownerPermissions = {
  'can_create_appeal': true,
  'can_process_appeals': true,
  'can_view_department': true,
  'can_view_all_appeals': true,
  'analytics_scope': 'company',
  'can_upload_meetings': true,
  'can_manage_settings': false,
  'can_view_unassigned': true,
};

const adminPermissions = {
  'can_create_appeal': true,
  'can_process_appeals': false,
  'can_view_department': true,
  'can_view_all_appeals': true,
  'analytics_scope': 'company',
  'can_upload_meetings': true,
  'can_manage_settings': true,
  'can_view_unassigned': true,
};

Map<String, dynamic> sessionJson([Map<String, dynamic>? me]) => {
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.mock.session',
      'token_type': 'bearer',
      'expires_at': '2026-12-10T19:30:00+05:00',
      'user': me ?? meJson(),
    };

const dictionariesJson = {
  'appeal_types': [
    {'code': 'problem', 'label': 'Проблема'},
    {'code': 'suggestion', 'label': 'Предложение'},
    {'code': 'praise', 'label': 'Положительный отзыв'},
  ],
  'priorities': [
    {'code': 'high', 'label': 'Высокий'},
    {'code': 'medium', 'label': 'Средний'},
    {'code': 'low', 'label': 'Низкий'},
  ],
  'statuses': [
    {'code': 'new', 'label': 'Новое', 'is_final': false},
    {'code': 'in_review', 'label': 'На рассмотрении', 'is_final': false},
    {'code': 'awaiting_info', 'label': 'Ожидает уточнения', 'is_final': false},
    {'code': 'in_progress', 'label': 'В работе', 'is_final': false},
    {'code': 'implemented', 'label': 'Реализовано', 'is_final': true},
    {'code': 'rejected', 'label': 'Отклонено', 'is_final': true},
    {'code': 'closed', 'label': 'Закрыто', 'is_final': true},
  ],
  'roles': [
    {'code': 'employee', 'label': 'Сотрудник'},
    {'code': 'head', 'label': 'Руководитель подразделения'},
    {'code': 'admin', 'label': 'Администратор'},
    {'code': 'owner', 'label': 'Собственник'},
  ],
  'sources': [
    {'code': 'form', 'label': 'Форма'},
  ],
  'actions': [
    {'code': 'take', 'label': 'Взять на рассмотрение', 'from': ['new'], 'to': 'in_review'},
  ],
  'due_filters': [
    {'code': 'overdue', 'label': 'Просрочено'},
  ],
  'timezone': '+05:00',
};

Map<String, dynamic> errorJson(String code, String message) => {
      'error': {'code': code, 'message': message, 'details': null},
    };

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Фейковый сервер: маршрут `МЕТОД /путь` → ответ. Запоминает запросы.
class FakeServer {
  FakeServer(this.routes);

  final Map<String, http.Response Function(http.Request)> routes;
  final List<http.Request> requests = [];

  late final client = MockClient((request) async {
    requests.add(request);
    final handler = routes['${request.method} ${request.url.path}'];
    if (handler == null) {
      return json(errorJson('not_found', 'Не найдено.'), 404);
    }
    return handler(request);
  });

  http.Request last(String method, String path) =>
      requests.lastWhere((r) => r.method == method && r.url.path == path);
}

const author = {'id': 4, 'full_name': 'Айгерим Нурланова', 'role': 'employee', 'department': {'id': 1, 'name': 'Закупки'}};
const assignee = {'id': 3, 'full_name': 'Марат Сейткали', 'role': 'head', 'department': {'id': 1, 'name': 'Закупки'}};

/// Обращение по схеме `Appeal` (для списка — подмножество `AppealListItem` тоже подходит).
Map<String, dynamic> appealJson({
  int id = 21,
  String number = 'A-021',
  String status = 'new',
  String dueState = 'on_time',
  String? summary = 'В заявках на оборудование не хватает параметров',
  String? rejectionReason,
  String? result,
  List<String> allowedActions = const ['send_message', 'upload_attachment'],
  List<Map<String, dynamic>> attachments = const [],
  bool hasUnread = false,
  Map<String, dynamic>? assigneeJson = assignee,
}) =>
    {
      'id': id,
      'number': number,
      'type': 'problem',
      'category': {'id': 1, 'name': 'Межотдельное взаимодействие'},
      'department': {'id': 1, 'name': 'Закупки'},
      'priority': 'medium',
      'status': status,
      'summary': summary,
      'author': author,
      'assignee': assigneeJson,
      'source': 'form',
      'first_response_due_at': assigneeJson == null ? null : '2026-11-13T10:15:00+05:00',
      'due_state': assigneeJson == null ? 'no_deadline' : dueState,
      'escalation_level': 0,
      'participants_count': 1,
      'merged_into': null,
      'access': 'full',
      'has_unread': hasUnread,
      'created_at': '2026-11-10T10:15:00+05:00',
      'updated_at': '2026-11-10T10:15:00+05:00',
      'text': 'В заявках на приобретение оборудования иногда не хватает назначения изделия.',
      'proposed_solution': 'Добавить обязательные поля',
      'first_response_at': null,
      'decision': null,
      'rejection_reason': rejectionReason,
      'result': result,
      'public_summary': null,
      'public_result': null,
      'forwarded_from': null,
      'closed_reason': null,
      'bitrix_task': null,
      'discussion': null,
      'attachments': attachments,
      'viewer_relations': ['author'],
      'allowed_actions': allowedActions,
    };

Map<String, dynamic> messageJson(int id, String text, {bool question = false, Map<String, dynamic> by = assignee}) => {
      'id': id,
      'appeal_id': 21,
      'author': by,
      'text': text,
      'is_clarification_question': question,
      'created_at': '2026-11-10T11:00:00+05:00',
    };

const categoriesJson = [
  {
    'id': 1,
    'name': 'Межотдельное взаимодействие',
    'department': {'id': 1, 'name': 'Закупки'},
    'responsible': assignee,
    'deputy': null,
    'is_active': true,
  },
  {
    'id': 9,
    'name': 'Архивная',
    'department': {'id': 1, 'name': 'Закупки'},
    'responsible': null,
    'deputy': null,
    'is_active': false,
  },
];

const headPermissions = {
  'can_create_appeal': true,
  'can_process_appeals': true,
  'can_view_department': true,
  'can_view_all_appeals': false,
  'analytics_scope': 'department',
  'can_upload_meetings': false,
  'can_manage_settings': false,
  'can_view_unassigned': false,
};

const usersJson = [
  {
    'id': 3, 'telegram_id': null, 'full_name': 'Марат Сейткали', 'position': null, 'role': 'head',
    'department': {'id': 1, 'name': 'Закупки'}, 'is_absent': false, 'is_disabled': false,
  },
  {
    'id': 5, 'telegram_id': null, 'full_name': 'Ольга Петрова', 'position': null, 'role': 'employee',
    'department': {'id': 2, 'name': 'Бухгалтерия'}, 'is_absent': true, 'is_disabled': false,
  },
  {
    'id': 2, 'telegram_id': null, 'full_name': 'Анна Ли', 'position': null, 'role': 'admin',
    'department': null, 'is_absent': false, 'is_disabled': false,
  },
  {
    'id': 9, 'telegram_id': null, 'full_name': 'Уволенный', 'position': null, 'role': 'employee',
    'department': null, 'is_absent': false, 'is_disabled': true,
  },
];
