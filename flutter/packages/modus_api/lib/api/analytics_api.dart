//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AnalyticsApi {
  AnalyticsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Экран сводки и аналитики
  ///
  /// Собственник — по компании (может сузить `department_id`), руководитель — только по своему подразделению (`department_id` другого подразделения — `403`). Остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] departmentId:
  ///
  /// * [int] categoryId:
  ///
  /// * [List<AppealStatus>] status:
  ///
  /// * [DueFilter] due:
  Future<Response> getAnalyticsSummaryWithHttpInfo({ int? departmentId, int? categoryId, List<AppealStatus>? status, DueFilter? due, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/analytics/summary';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (departmentId != null) {
      queryParams.addAll(_queryParams('', 'department_id', departmentId));
    }
    if (categoryId != null) {
      queryParams.addAll(_queryParams('', 'category_id', categoryId));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('multi', 'status', status));
    }
    if (due != null) {
      queryParams.addAll(_queryParams('', 'due', due));
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

  /// Экран сводки и аналитики
  ///
  /// Собственник — по компании (может сузить `department_id`), руководитель — только по своему подразделению (`department_id` другого подразделения — `403`). Остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] departmentId:
  ///
  /// * [int] categoryId:
  ///
  /// * [List<AppealStatus>] status:
  ///
  /// * [DueFilter] due:
  Future<AnalyticsSummary?> getAnalyticsSummary({ int? departmentId, int? categoryId, List<AppealStatus>? status, DueFilter? due, Future<void>? abortTrigger, }) async {
    final response = await getAnalyticsSummaryWithHttpInfo(departmentId: departmentId, categoryId: categoryId, status: status, due: due, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AnalyticsSummary',) as AnalyticsSummary;
    
    }
    return null;
  }

  /// Текст сводки для бота
  ///
  /// Команда сводки в боте: бот вызывает от имени пользователя и отправляет `text` как есть (Telegram HTML). Руководитель получает своё подразделение, собственник — компанию. Остальным — `403`. Утренняя сводка приходит в очередь уведомлений (`kind=digest`) сама. 
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getDigestWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/analytics/digest';

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

  /// Текст сводки для бота
  ///
  /// Команда сводки в боте: бот вызывает от имени пользователя и отправляет `text` как есть (Telegram HTML). Руководитель получает своё подразделение, собственник — компанию. Остальным — `403`. Утренняя сводка приходит в очередь уведомлений (`kind=digest`) сама. 
  Future<Digest?> getDigest({ Future<void>? abortTrigger, }) async {
    final response = await getDigestWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Digest',) as Digest;
    
    }
    return null;
  }
}
