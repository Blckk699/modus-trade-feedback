//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AccessApi {
  AccessApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Принять приглашение
  ///
  /// Опознание как у заявки: бот (`/start inv_<токен>`) — заголовки `X-Service-Key` и `X-Telegram-Id`, Mini App — `init_data`, веб (`/invite/<токен>`) — `telegram_login`.  - Незнакомый аккаунт и действующее приглашение — пользователь создаётся с ролью и подразделением   из приглашения, `created=true`. Имя: из приглашения, иначе `full_name`, иначе из профиля Telegram. - Уже заведённый пользователь — ничего не меняется, `created=false`, приглашение не расходуется. - Отключённый — `403 user_disabled`. - Просроченное, отозванное или исчерпанное приглашение — `410 invite_invalid` (предложить заявку). - Больше 10 недействительных токенов за 15 минут с одного адреса (у бота — с одного Telegram ID) — `429 too_many_requests`.  `session` — сессия для Mini App и веба (как у `/auth/_*`). Боту сессия не нужна, ему `session=null`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [InviteAccept] inviteAccept (required):
  Future<Response> acceptInviteWithHttpInfo(InviteAccept inviteAccept, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/invites/accept';

    // ignore: prefer_final_locals
    Object? postBody = inviteAccept;

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

  /// Принять приглашение
  ///
  /// Опознание как у заявки: бот (`/start inv_<токен>`) — заголовки `X-Service-Key` и `X-Telegram-Id`, Mini App — `init_data`, веб (`/invite/<токен>`) — `telegram_login`.  - Незнакомый аккаунт и действующее приглашение — пользователь создаётся с ролью и подразделением   из приглашения, `created=true`. Имя: из приглашения, иначе `full_name`, иначе из профиля Telegram. - Уже заведённый пользователь — ничего не меняется, `created=false`, приглашение не расходуется. - Отключённый — `403 user_disabled`. - Просроченное, отозванное или исчерпанное приглашение — `410 invite_invalid` (предложить заявку). - Больше 10 недействительных токенов за 15 минут с одного адреса (у бота — с одного Telegram ID) — `429 too_many_requests`.  `session` — сессия для Mini App и веба (как у `/auth/_*`). Боту сессия не нужна, ему `session=null`. 
  ///
  /// Parameters:
  ///
  /// * [InviteAccept] inviteAccept (required):
  Future<InviteAccepted?> acceptInvite(InviteAccept inviteAccept, { Future<void>? abortTrigger, }) async {
    final response = await acceptInviteWithHttpInfo(inviteAccept, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InviteAccepted',) as InviteAccepted;
    
    }
    return null;
  }

  /// Одобрить заявку — создаёт пользователя
  ///
  /// Администратор и собственник. Роль по умолчанию `employee`, `owner` не выдаётся (`422`). Подразделение по умолчанию — выбранное в заявке. Заявителю уходит уведомление `access_request_approved`. Заявка уже решена или Telegram ID уже заведён — `409 conflict`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] requestId (required):
  ///
  /// * [AccessRequestApprove] accessRequestApprove (required):
  Future<Response> approveAccessRequestWithHttpInfo(int requestId, AccessRequestApprove accessRequestApprove, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/access-requests/{request_id}/approve'
      .replaceAll('{request_id}', requestId.toString());

    // ignore: prefer_final_locals
    Object? postBody = accessRequestApprove;

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

  /// Одобрить заявку — создаёт пользователя
  ///
  /// Администратор и собственник. Роль по умолчанию `employee`, `owner` не выдаётся (`422`). Подразделение по умолчанию — выбранное в заявке. Заявителю уходит уведомление `access_request_approved`. Заявка уже решена или Telegram ID уже заведён — `409 conflict`. 
  ///
  /// Parameters:
  ///
  /// * [int] requestId (required):
  ///
  /// * [AccessRequestApprove] accessRequestApprove (required):
  Future<AccessRequest?> approveAccessRequest(int requestId, AccessRequestApprove accessRequestApprove, { Future<void>? abortTrigger, }) async {
    final response = await approveAccessRequestWithHttpInfo(requestId, accessRequestApprove, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AccessRequest',) as AccessRequest;
    
    }
    return null;
  }

  /// Создать приглашение
  ///
  /// Администратор и собственник. Роль кроме `owner`, срок по умолчанию 7 дней, использований по умолчанию 1. `token`, `bot_link` и `web_link` есть только в этом ответе: в базе хранится хеш токена. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [InviteCreate] inviteCreate (required):
  Future<Response> createInviteWithHttpInfo(InviteCreate inviteCreate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/invites';

    // ignore: prefer_final_locals
    Object? postBody = inviteCreate;

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

  /// Создать приглашение
  ///
  /// Администратор и собственник. Роль кроме `owner`, срок по умолчанию 7 дней, использований по умолчанию 1. `token`, `bot_link` и `web_link` есть только в этом ответе: в базе хранится хеш токена. 
  ///
  /// Parameters:
  ///
  /// * [InviteCreate] inviteCreate (required):
  Future<InviteCreated?> createInvite(InviteCreate inviteCreate, { Future<void>? abortTrigger, }) async {
    final response = await createInviteWithHttpInfo(inviteCreate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InviteCreated',) as InviteCreated;
    
    }
    return null;
  }

  /// Что за приглашение (без входа)
  ///
  /// Для страницы `/invite/<токен>` в вебе до входа. Недействительное — `410 invite_invalid`. Больше 10 недействительных токенов с одного адреса за 15 минут — `429 too_many_requests` (защита от перебора). 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> getInvitePreviewWithHttpInfo(String token, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/invites/{token}'
      .replaceAll('{token}', token);

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

  /// Что за приглашение (без входа)
  ///
  /// Для страницы `/invite/<токен>` в вебе до входа. Недействительное — `410 invite_invalid`. Больше 10 недействительных токенов с одного адреса за 15 минут — `429 too_many_requests` (защита от перебора). 
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<InvitePreview?> getInvitePreview(String token, { Future<void>? abortTrigger, }) async {
    final response = await getInvitePreviewWithHttpInfo(token, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'InvitePreview',) as InvitePreview;
    
    }
    return null;
  }

  /// Состояние доступа и своей заявки
  ///
  /// Что показать незнакомому аккаунту: форму заявки, «на рассмотрении», отказ с причиной или вход. Опознание такое же, как при подаче: бот — заголовки и пустое тело `{}`, Mini App — `init_data`, веб — `telegram_login`. `request` — последняя заявка аккаунта или `null`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TelegramIdentity] telegramIdentity (required):
  Future<Response> getMyAccessRequestWithHttpInfo(TelegramIdentity telegramIdentity, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/access-requests/mine';

    // ignore: prefer_final_locals
    Object? postBody = telegramIdentity;

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

  /// Состояние доступа и своей заявки
  ///
  /// Что показать незнакомому аккаунту: форму заявки, «на рассмотрении», отказ с причиной или вход. Опознание такое же, как при подаче: бот — заголовки и пустое тело `{}`, Mini App — `init_data`, веб — `telegram_login`. `request` — последняя заявка аккаунта или `null`. 
  ///
  /// Parameters:
  ///
  /// * [TelegramIdentity] telegramIdentity (required):
  Future<AccessStatus?> getMyAccessRequest(TelegramIdentity telegramIdentity, { Future<void>? abortTrigger, }) async {
    final response = await getMyAccessRequestWithHttpInfo(telegramIdentity, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AccessStatus',) as AccessStatus;
    
    }
    return null;
  }

  /// Подразделения для формы заявки (без входа)
  ///
  /// Короткий список для выбора подразделения незнакомым аккаунтом. Сессия не нужна.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listAccessDepartmentsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/access-requests/departments';

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

  /// Подразделения для формы заявки (без входа)
  ///
  /// Короткий список для выбора подразделения незнакомым аккаунтом. Сессия не нужна.
  Future<List<DepartmentRef>?> listAccessDepartments({ Future<void>? abortTrigger, }) async {
    final response = await listAccessDepartmentsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<DepartmentRef>') as List)
        .cast<DepartmentRef>()
        .toList(growable: false);

    }
    return null;
  }

  /// Заявки на доступ
  ///
  /// Администратор и собственник (`Me.permissions.can_manage_access`), остальным — `403`. Новые первыми.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AccessRequestStatus] status:
  ///   Без параметра — все заявки
  ///
  /// * [int] page:
  ///
  /// * [int] pageSize:
  Future<Response> listAccessRequestsWithHttpInfo({ AccessRequestStatus? status, int? page, int? pageSize, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/access-requests';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
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

  /// Заявки на доступ
  ///
  /// Администратор и собственник (`Me.permissions.can_manage_access`), остальным — `403`. Новые первыми.
  ///
  /// Parameters:
  ///
  /// * [AccessRequestStatus] status:
  ///   Без параметра — все заявки
  ///
  /// * [int] page:
  ///
  /// * [int] pageSize:
  Future<AccessRequestPage?> listAccessRequests({ AccessRequestStatus? status, int? page, int? pageSize, Future<void>? abortTrigger, }) async {
    final response = await listAccessRequestsWithHttpInfo(status: status, page: page, pageSize: pageSize, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AccessRequestPage',) as AccessRequestPage;
    
    }
    return null;
  }

  /// Приглашения
  ///
  /// Администратор и собственник, остальным — `403`. Все приглашения, новые первыми; `include_inactive=false` оставляет только действующие. Токена в списке нет — он показывается один раз при создании. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [bool] includeInactive:
  Future<Response> listInvitesWithHttpInfo({ bool? includeInactive, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/invites';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (includeInactive != null) {
      queryParams.addAll(_queryParams('', 'include_inactive', includeInactive));
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

  /// Приглашения
  ///
  /// Администратор и собственник, остальным — `403`. Все приглашения, новые первыми; `include_inactive=false` оставляет только действующие. Токена в списке нет — он показывается один раз при создании. 
  ///
  /// Parameters:
  ///
  /// * [bool] includeInactive:
  Future<List<Invite>?> listInvites({ bool? includeInactive, Future<void>? abortTrigger, }) async {
    final response = await listInvitesWithHttpInfo(includeInactive: includeInactive, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Invite>') as List)
        .cast<Invite>()
        .toList(growable: false);

    }
    return null;
  }

  /// Отклонить заявку
  ///
  /// Администратор и собственник. Причина необязательна, заявитель увидит её в уведомлении `access_request_rejected` и в `POST /access-requests/mine`. Заявка уже решена — `409 conflict`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] requestId (required):
  ///
  /// * [AccessRequestReject] accessRequestReject (required):
  Future<Response> rejectAccessRequestWithHttpInfo(int requestId, AccessRequestReject accessRequestReject, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/access-requests/{request_id}/reject'
      .replaceAll('{request_id}', requestId.toString());

    // ignore: prefer_final_locals
    Object? postBody = accessRequestReject;

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

  /// Отклонить заявку
  ///
  /// Администратор и собственник. Причина необязательна, заявитель увидит её в уведомлении `access_request_rejected` и в `POST /access-requests/mine`. Заявка уже решена — `409 conflict`. 
  ///
  /// Parameters:
  ///
  /// * [int] requestId (required):
  ///
  /// * [AccessRequestReject] accessRequestReject (required):
  Future<AccessRequest?> rejectAccessRequest(int requestId, AccessRequestReject accessRequestReject, { Future<void>? abortTrigger, }) async {
    final response = await rejectAccessRequestWithHttpInfo(requestId, accessRequestReject, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AccessRequest',) as AccessRequest;
    
    }
    return null;
  }

  /// Отозвать приглашение
  ///
  /// Администратор и собственник. Повторный отзыв ничего не меняет. Уже созданные по ссылке пользователи остаются.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] inviteId (required):
  Future<Response> revokeInviteWithHttpInfo(int inviteId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/invites/{invite_id}/revoke'
      .replaceAll('{invite_id}', inviteId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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

  /// Отозвать приглашение
  ///
  /// Администратор и собственник. Повторный отзыв ничего не меняет. Уже созданные по ссылке пользователи остаются.
  ///
  /// Parameters:
  ///
  /// * [int] inviteId (required):
  Future<Invite?> revokeInvite(int inviteId, { Future<void>? abortTrigger, }) async {
    final response = await revokeInviteWithHttpInfo(inviteId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Invite',) as Invite;
    
    }
    return null;
  }

  /// Подать или обновить заявку на доступ
  ///
  /// Вызывает незнакомый системе Telegram-аккаунт. Кто он, бэкенд узнаёт одним из трёх способов: - **бот** — заголовки `X-Service-Key` и `X-Telegram-Id`, имя из профиля в `full_name`, ник в `telegram_username`; - **Mini App** — `init_data` (`Telegram.WebApp.initData` без изменений); - **веб** — `telegram_login`, поля колбэка Telegram Login как есть.  Ровно один способ, иначе `401 unauthorized` (ни одного) или `422 validation_error` (оба поля сразу). У аккаунта одна заявка `pending`: повторная подача её обновляет (`200`), новая — `201`. После отказа можно подать новую. Уже заведённый пользователь — `409 already_registered`, отключённый — `403 user_disabled`. Не больше 5 подач с аккаунта в час — `429 too_many_requests`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AccessRequestSubmit] accessRequestSubmit (required):
  Future<Response> submitAccessRequestWithHttpInfo(AccessRequestSubmit accessRequestSubmit, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/access-requests';

    // ignore: prefer_final_locals
    Object? postBody = accessRequestSubmit;

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

  /// Подать или обновить заявку на доступ
  ///
  /// Вызывает незнакомый системе Telegram-аккаунт. Кто он, бэкенд узнаёт одним из трёх способов: - **бот** — заголовки `X-Service-Key` и `X-Telegram-Id`, имя из профиля в `full_name`, ник в `telegram_username`; - **Mini App** — `init_data` (`Telegram.WebApp.initData` без изменений); - **веб** — `telegram_login`, поля колбэка Telegram Login как есть.  Ровно один способ, иначе `401 unauthorized` (ни одного) или `422 validation_error` (оба поля сразу). У аккаунта одна заявка `pending`: повторная подача её обновляет (`200`), новая — `201`. После отказа можно подать новую. Уже заведённый пользователь — `409 already_registered`, отключённый — `403 user_disabled`. Не больше 5 подач с аккаунта в час — `429 too_many_requests`. 
  ///
  /// Parameters:
  ///
  /// * [AccessRequestSubmit] accessRequestSubmit (required):
  Future<AccessRequest?> submitAccessRequest(AccessRequestSubmit accessRequestSubmit, { Future<void>? abortTrigger, }) async {
    final response = await submitAccessRequestWithHttpInfo(accessRequestSubmit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AccessRequest',) as AccessRequest;
    
    }
    return null;
  }
}
