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
  ],
  'priorities': [
    {'code': 'high', 'label': 'Высокий'},
  ],
  'statuses': [
    {'code': 'new', 'label': 'Новое', 'is_final': false},
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
