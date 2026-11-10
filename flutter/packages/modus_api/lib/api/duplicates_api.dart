//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DuplicatesApi {
  DuplicatesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// «Это другое» — убрать подсказку навсегда
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] suggestionId (required):
  Future<Response> dismissSuggestionWithHttpInfo(int suggestionId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/duplicate-suggestions/{suggestion_id}/dismiss'
      .replaceAll('{suggestion_id}', suggestionId.toString());

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

  /// «Это другое» — убрать подсказку навсегда
  ///
  /// Parameters:
  ///
  /// * [int] suggestionId (required):
  Future<void> dismissSuggestion(int suggestionId, { Future<void>? abortTrigger, }) async {
    final response = await dismissSuggestionWithHttpInfo(suggestionId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Подсказки о похожих обращениях
  ///
  /// Ищутся среди обращений, которые видит пользователь: ответственный — среди назначенных ему, руководитель — в своём подразделении, собственник — по всей компании. Автору не отдаётся (пустой список). Отклонённые кнопкой «Это другое» не возвращаются. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<Response> listSimilarWithHttpInfo(int appealId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/similar'
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

  /// Подсказки о похожих обращениях
  ///
  /// Ищутся среди обращений, которые видит пользователь: ответственный — среди назначенных ему, руководитель — в своём подразделении, собственник — по всей компании. Автору не отдаётся (пустой список). Отклонённые кнопкой «Это другое» не возвращаются. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<List<DuplicateSuggestion>?> listSimilar(int appealId, { Future<void>? abortTrigger, }) async {
    final response = await listSimilarWithHttpInfo(appealId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<DuplicateSuggestion>') as List)
        .cast<DuplicateSuggestion>()
        .toList(growable: false);

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
}
