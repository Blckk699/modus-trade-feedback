//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AppealsApi {
  AppealsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Создать обращение
  ///
  /// Форма в клиентах (`source=form`) и подтверждённый черновик из бота (`source=bot`). Работает без AI-сервисов. Бэкенд сразу маршрутизирует обращение: назначает ответственного по правилу категории (или заместителя, если ответственный отсутствует) и срок первого ответа. Если ответственного нет или категория не указана, `assignee` = null и обращение в очереди администратора. Вложения загружаются после создания: `POST /appeals/{appeal_id}/attachments`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AppealCreate] appealCreate (required):
  Future<Response> createAppealWithHttpInfo(AppealCreate appealCreate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals';

    // ignore: prefer_final_locals
    Object? postBody = appealCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Создать обращение
  ///
  /// Форма в клиентах (`source=form`) и подтверждённый черновик из бота (`source=bot`). Работает без AI-сервисов. Бэкенд сразу маршрутизирует обращение: назначает ответственного по правилу категории (или заместителя, если ответственный отсутствует) и срок первого ответа. Если ответственного нет или категория не указана, `assignee` = null и обращение в очереди администратора. Вложения загружаются после создания: `POST /appeals/{appeal_id}/attachments`. 
  ///
  /// Parameters:
  ///
  /// * [AppealCreate] appealCreate (required):
  Future<Appeal?> createAppeal(AppealCreate appealCreate, { Future<void>? abortTrigger, }) async {
    final response = await createAppealWithHttpInfo(appealCreate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Appeal',) as Appeal;
    
    }
    return null;
  }

  /// Карточка обращения
  ///
  /// `access=participant` — пользователь видит основное обращение как участник склеенного повтора: статус, ответственного, срок и итог, но `text`, `proposed_solution`, `author` и вложения скрыты (null / пусто). 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<Response> getAppealWithHttpInfo(int appealId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Карточка обращения
  ///
  /// `access=participant` — пользователь видит основное обращение как участник склеенного повтора: статус, ответственного, срок и итог, но `text`, `proposed_solution`, `author` и вложения скрыты (null / пусто). 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<Appeal?> getAppeal(int appealId, { Future<void>? abortTrigger, }) async {
    final response = await getAppealWithHttpInfo(appealId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Appeal',) as Appeal;
    
    }
    return null;
  }

  /// История событий обращения
  ///
  /// По возрастанию времени. Участник склеенного повтора историю основного не видит (403).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<Response> getAppealHistoryWithHttpInfo(int appealId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/history'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// История событий обращения
  ///
  /// По возрастанию времени. Участник склеенного повтора историю основного не видит (403).
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<List<HistoryEvent>?> getAppealHistory(int appealId, { Future<void>? abortTrigger, }) async {
    final response = await getAppealHistoryWithHttpInfo(appealId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<HistoryEvent>') as List)
        .cast<HistoryEvent>()
        .toList(growable: false);

    }
    return null;
  }

  /// Список обращений, которые видит пользователь
  ///
  /// Видимость по матрице доступа: сотрудник — свои (автор или участник склеенного), ответственный — назначенные, руководитель — своего подразделения, администратор и собственник — все. `scope` сужает выборку внутри видимого. Очередь ответственного: `scope=assigned&sort=due_asc`. Очередь нераспределённых для администратора: `scope=unassigned`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AppealScope] scope:
  ///
  /// * [List<AppealStatus>] status:
  ///   Один или несколько статусов
  ///
  /// * [AppealType] type:
  ///
  /// * [Priority] priority:
  ///
  /// * [int] categoryId:
  ///
  /// * [int] departmentId:
  ///
  /// * [DueFilter] due:
  ///
  /// * [String] q:
  ///   Поиск по номеру, сути и тексту
  ///
  /// * [String] sort:
  ///
  /// * [int] page:
  ///
  /// * [int] pageSize:
  Future<Response> listAppealsWithHttpInfo({ AppealScope? scope, List<AppealStatus>? status, AppealType? type, Priority? priority, int? categoryId, int? departmentId, DueFilter? due, String? q, String? sort, int? page, int? pageSize, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (scope != null) {
      queryParams.addAll(_queryParams('', 'scope', scope));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('multi', 'status', status));
    }
    if (type != null) {
      queryParams.addAll(_queryParams('', 'type', type));
    }
    if (priority != null) {
      queryParams.addAll(_queryParams('', 'priority', priority));
    }
    if (categoryId != null) {
      queryParams.addAll(_queryParams('', 'category_id', categoryId));
    }
    if (departmentId != null) {
      queryParams.addAll(_queryParams('', 'department_id', departmentId));
    }
    if (due != null) {
      queryParams.addAll(_queryParams('', 'due', due));
    }
    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }
    if (sort != null) {
      queryParams.addAll(_queryParams('', 'sort', sort));
    }
    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (pageSize != null) {
      queryParams.addAll(_queryParams('', 'page_size', pageSize));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Список обращений, которые видит пользователь
  ///
  /// Видимость по матрице доступа: сотрудник — свои (автор или участник склеенного), ответственный — назначенные, руководитель — своего подразделения, администратор и собственник — все. `scope` сужает выборку внутри видимого. Очередь ответственного: `scope=assigned&sort=due_asc`. Очередь нераспределённых для администратора: `scope=unassigned`. 
  ///
  /// Parameters:
  ///
  /// * [AppealScope] scope:
  ///
  /// * [List<AppealStatus>] status:
  ///   Один или несколько статусов
  ///
  /// * [AppealType] type:
  ///
  /// * [Priority] priority:
  ///
  /// * [int] categoryId:
  ///
  /// * [int] departmentId:
  ///
  /// * [DueFilter] due:
  ///
  /// * [String] q:
  ///   Поиск по номеру, сути и тексту
  ///
  /// * [String] sort:
  ///
  /// * [int] page:
  ///
  /// * [int] pageSize:
  Future<AppealPage?> listAppeals({ AppealScope? scope, List<AppealStatus>? status, AppealType? type, Priority? priority, int? categoryId, int? departmentId, DueFilter? due, String? q, String? sort, int? page, int? pageSize, Future<void>? abortTrigger, }) async {
    final response = await listAppealsWithHttpInfo(scope: scope, status: status, type: type, priority: priority, categoryId: categoryId, departmentId: departmentId, due: due, q: q, sort: sort, page: page, pageSize: pageSize, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AppealPage',) as AppealPage;
    
    }
    return null;
  }
}
