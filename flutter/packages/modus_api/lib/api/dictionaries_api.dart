//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DictionariesApi {
  DictionariesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Подписи перечислений и таблица переходов
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getDictionariesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/dictionaries';

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

  /// Подписи перечислений и таблица переходов
  Future<Dictionaries?> getDictionaries({ Future<void>? abortTrigger, }) async {
    final response = await getDictionariesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Dictionaries',) as Dictionaries;
    
    }
    return null;
  }

  /// Категории с ответственными
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [bool] includeInactive:
  Future<Response> listCategoriesWithHttpInfo({ bool? includeInactive, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/categories';

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

  /// Категории с ответственными
  ///
  /// Parameters:
  ///
  /// * [bool] includeInactive:
  Future<List<Category>?> listCategories({ bool? includeInactive, Future<void>? abortTrigger, }) async {
    final response = await listCategoriesWithHttpInfo(includeInactive: includeInactive, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Category>') as List)
        .cast<Category>()
        .toList(growable: false);

    }
    return null;
  }

  /// Подразделения
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listDepartmentsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/departments';

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

  /// Подразделения
  Future<List<Department>?> listDepartments({ Future<void>? abortTrigger, }) async {
    final response = await listDepartmentsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Department>') as List)
        .cast<Department>()
        .toList(growable: false);

    }
    return null;
  }

  /// Справочник сотрудников
  ///
  /// Для выбора ответственного при переназначении и автора черновика совещания. `telegram_id` отдаётся только администратору, остальным — null. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  ///
  /// * [int] departmentId:
  ///
  /// * [Role] role:
  ///
  /// * [bool] includeDisabled:
  ///   Только для администратора
  Future<Response> listUsersWithHttpInfo({ String? q, int? departmentId, Role? role, bool? includeDisabled, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/users';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }
    if (departmentId != null) {
      queryParams.addAll(_queryParams('', 'department_id', departmentId));
    }
    if (role != null) {
      queryParams.addAll(_queryParams('', 'role', role));
    }
    if (includeDisabled != null) {
      queryParams.addAll(_queryParams('', 'include_disabled', includeDisabled));
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

  /// Справочник сотрудников
  ///
  /// Для выбора ответственного при переназначении и автора черновика совещания. `telegram_id` отдаётся только администратору, остальным — null. 
  ///
  /// Parameters:
  ///
  /// * [String] q:
  ///
  /// * [int] departmentId:
  ///
  /// * [Role] role:
  ///
  /// * [bool] includeDisabled:
  ///   Только для администратора
  Future<List<User>?> listUsers({ String? q, int? departmentId, Role? role, bool? includeDisabled, Future<void>? abortTrigger, }) async {
    final response = await listUsersWithHttpInfo(q: q, departmentId: departmentId, role: role, includeDisabled: includeDisabled, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<User>') as List)
        .cast<User>()
        .toList(growable: false);

    }
    return null;
  }
}
