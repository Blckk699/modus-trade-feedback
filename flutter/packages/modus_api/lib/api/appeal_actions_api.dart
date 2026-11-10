//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AppealActionsApi {
  AppealActionsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Принять положительный отзыв одним действием (Новое → Закрыто)
  ///
  /// Только для `type=praise`. Для других типов — `409 invalid_transition`. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [AcceptFeedbackRequest] acceptFeedbackRequest:
  Future<Response> acceptFeedbackWithHttpInfo(int appealId, { AcceptFeedbackRequest? acceptFeedbackRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/accept-feedback'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = acceptFeedbackRequest;

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

  /// Принять положительный отзыв одним действием (Новое → Закрыто)
  ///
  /// Только для `type=praise`. Для других типов — `409 invalid_transition`. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [AcceptFeedbackRequest] acceptFeedbackRequest:
  Future<Appeal?> acceptFeedback(int appealId, { AcceptFeedbackRequest? acceptFeedbackRequest, Future<void>? abortTrigger, }) async {
    final response = await acceptFeedbackWithHttpInfo(appealId, acceptFeedbackRequest: acceptFeedbackRequest, abortTrigger: abortTrigger,);
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

  /// Зафиксировать результат (В работе → Реализовано)
  ///
  /// Обращение попадает в ленту реализованного, которую видят все сотрудники. В ленте показываются «что предложили» и «что сделали»: - что предложили — `public_summary`; если не задан — публичная формулировка обсуждения, а без обсуждения — краткая суть; - что сделали — `public_result`; если не задан — `result`. Поэтому `result` без `public_result` пишите так,   чтобы его можно было показать всем. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [ImplementAppealRequest] implementAppealRequest (required):
  Future<Response> implementAppealWithHttpInfo(int appealId, ImplementAppealRequest implementAppealRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/implement'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = implementAppealRequest;

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

  /// Зафиксировать результат (В работе → Реализовано)
  ///
  /// Обращение попадает в ленту реализованного, которую видят все сотрудники. В ленте показываются «что предложили» и «что сделали»: - что предложили — `public_summary`; если не задан — публичная формулировка обсуждения, а без обсуждения — краткая суть; - что сделали — `public_result`; если не задан — `result`. Поэтому `result` без `public_result` пишите так,   чтобы его можно было показать всем. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [ImplementAppealRequest] implementAppealRequest (required):
  Future<Appeal?> implementAppeal(int appealId, ImplementAppealRequest implementAppealRequest, { Future<void>? abortTrigger, }) async {
    final response = await implementAppealWithHttpInfo(appealId, implementAppealRequest, abortTrigger: abortTrigger,);
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

  /// Присоединить это обращение как повтор к основному
  ///
  /// `appeal_id` — повтор, `main_appeal_id` — основное. Оба в статусах «Новое» или «На рассмотрении» и оба видны пользователю, иначе `409 merge_not_allowed` / `403`. Повтор между зонами разных ответственных склеивает руководитель или собственник. Повтор переходит в «Закрыто» со ссылкой на основное, его автор становится участником основного и получает его статусы. Ответ — основное обращение с обновлённым `participants_count`. Кто: ответственный (оба обращения назначены ему), руководитель, собственник. Администратору — `403`, даже если он видит оба обращения. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [MergeAppealRequest] mergeAppealRequest (required):
  Future<Response> mergeAppealWithHttpInfo(int appealId, MergeAppealRequest mergeAppealRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/merge'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = mergeAppealRequest;

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

  /// Присоединить это обращение как повтор к основному
  ///
  /// `appeal_id` — повтор, `main_appeal_id` — основное. Оба в статусах «Новое» или «На рассмотрении» и оба видны пользователю, иначе `409 merge_not_allowed` / `403`. Повтор между зонами разных ответственных склеивает руководитель или собственник. Повтор переходит в «Закрыто» со ссылкой на основное, его автор становится участником основного и получает его статусы. Ответ — основное обращение с обновлённым `participants_count`. Кто: ответственный (оба обращения назначены ему), руководитель, собственник. Администратору — `403`, даже если он видит оба обращения. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [MergeAppealRequest] mergeAppealRequest (required):
  Future<Appeal?> mergeAppeal(int appealId, MergeAppealRequest mergeAppealRequest, { Future<void>? abortTrigger, }) async {
    final response = await mergeAppealWithHttpInfo(appealId, mergeAppealRequest, abortTrigger: abortTrigger,);
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

  /// Переназначить ответственного с причиной
  ///
  /// Руководитель (в своём подразделении), администратор, собственник. Если первого ответа ещё не было, срок первого ответа отсчитывается заново; у отвеченного обращения срок не меняется. Причина пишется в историю. Назначить можно действующего сотрудника, кроме администратора (`422`). Этим же маршрутом администратор назначает ответственного из очереди нераспределённых. Ответственному, сотруднику — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [ReassignAppealRequest] reassignAppealRequest (required):
  Future<Response> reassignAppealWithHttpInfo(int appealId, ReassignAppealRequest reassignAppealRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/reassign'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = reassignAppealRequest;

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

  /// Переназначить ответственного с причиной
  ///
  /// Руководитель (в своём подразделении), администратор, собственник. Если первого ответа ещё не было, срок первого ответа отсчитывается заново; у отвеченного обращения срок не меняется. Причина пишется в историю. Назначить можно действующего сотрудника, кроме администратора (`422`). Этим же маршрутом администратор назначает ответственного из очереди нераспределённых. Ответственному, сотруднику — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [ReassignAppealRequest] reassignAppealRequest (required):
  Future<Appeal?> reassignAppeal(int appealId, ReassignAppealRequest reassignAppealRequest, { Future<void>? abortTrigger, }) async {
    final response = await reassignAppealWithHttpInfo(appealId, reassignAppealRequest, abortTrigger: abortTrigger,);
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

  /// Отклонить с обязательной причиной (На рассмотрении → Отклонено)
  ///
  /// Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [RejectAppealRequest] rejectAppealRequest (required):
  Future<Response> rejectAppealWithHttpInfo(int appealId, RejectAppealRequest rejectAppealRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/reject'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = rejectAppealRequest;

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

  /// Отклонить с обязательной причиной (На рассмотрении → Отклонено)
  ///
  /// Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [RejectAppealRequest] rejectAppealRequest (required):
  Future<Appeal?> rejectAppeal(int appealId, RejectAppealRequest rejectAppealRequest, { Future<void>? abortTrigger, }) async {
    final response = await rejectAppealWithHttpInfo(appealId, rejectAppealRequest, abortTrigger: abortTrigger,);
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

  /// Задать автору уточняющий вопрос (На рассмотрении → Ожидает уточнения)
  ///
  /// Вопрос попадает в переписку с `is_clarification_question=true`, автору уходит уведомление. Срок первого ответа к этому моменту уже выполнен (первый ответ фиксирует `take`), других сроков нет. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [RequestInfoRequest] requestInfoRequest (required):
  Future<Response> requestInfoWithHttpInfo(int appealId, RequestInfoRequest requestInfoRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/request-info'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = requestInfoRequest;

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

  /// Задать автору уточняющий вопрос (На рассмотрении → Ожидает уточнения)
  ///
  /// Вопрос попадает в переписку с `is_clarification_question=true`, автору уходит уведомление. Срок первого ответа к этому моменту уже выполнен (первый ответ фиксирует `take`), других сроков нет. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [RequestInfoRequest] requestInfoRequest (required):
  Future<Appeal?> requestInfo(int appealId, RequestInfoRequest requestInfoRequest, { Future<void>? abortTrigger, }) async {
    final response = await requestInfoWithHttpInfo(appealId, requestInfoRequest, abortTrigger: abortTrigger,);
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

  /// Принять решение и перевести в работу (На рассмотрении → В работе)
  ///
  /// Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [StartWorkRequest] startWorkRequest (required):
  Future<Response> startWorkWithHttpInfo(int appealId, StartWorkRequest startWorkRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/start-work'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = startWorkRequest;

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

  /// Принять решение и перевести в работу (На рассмотрении → В работе)
  ///
  /// Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [StartWorkRequest] startWorkRequest (required):
  Future<Appeal?> startWork(int appealId, StartWorkRequest startWorkRequest, { Future<void>? abortTrigger, }) async {
    final response = await startWorkWithHttpInfo(appealId, startWorkRequest, abortTrigger: abortTrigger,);
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

  /// Взять на рассмотрение (Новое → На рассмотрении)
  ///
  /// Фиксирует время первого ответа, если оно ещё не зафиксировано. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [TakeAppealRequest] takeAppealRequest:
  Future<Response> takeAppealWithHttpInfo(int appealId, { TakeAppealRequest? takeAppealRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/take'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = takeAppealRequest;

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

  /// Взять на рассмотрение (Новое → На рассмотрении)
  ///
  /// Фиксирует время первого ответа, если оно ещё не зафиксировано. Кто: ответственный, руководитель подразделения обращения, собственник. Руководитель и собственник действуют без смены ответственного. Администратору и остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [TakeAppealRequest] takeAppealRequest:
  Future<Appeal?> takeAppeal(int appealId, { TakeAppealRequest? takeAppealRequest, Future<void>? abortTrigger, }) async {
    final response = await takeAppealWithHttpInfo(appealId, takeAppealRequest: takeAppealRequest, abortTrigger: abortTrigger,);
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
}
