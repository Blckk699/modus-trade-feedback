//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AdminApi {
  AdminApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Добавить категорию
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CategoryWrite] categoryWrite (required):
  Future<Response> adminCreateCategoryWithHttpInfo(CategoryWrite categoryWrite, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/categories';

    // ignore: prefer_final_locals
    Object? postBody = categoryWrite;

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

  /// Добавить категорию
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [CategoryWrite] categoryWrite (required):
  Future<Category?> adminCreateCategory(CategoryWrite categoryWrite, { Future<void>? abortTrigger, }) async {
    final response = await adminCreateCategoryWithHttpInfo(categoryWrite, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Category',) as Category;
    
    }
    return null;
  }

  /// Добавить подразделение
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DepartmentWrite] departmentWrite (required):
  Future<Response> adminCreateDepartmentWithHttpInfo(DepartmentWrite departmentWrite, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/departments';

    // ignore: prefer_final_locals
    Object? postBody = departmentWrite;

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

  /// Добавить подразделение
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [DepartmentWrite] departmentWrite (required):
  Future<Department?> adminCreateDepartment(DepartmentWrite departmentWrite, { Future<void>? abortTrigger, }) async {
    final response = await adminCreateDepartmentWithHttpInfo(departmentWrite, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Department',) as Department;
    
    }
    return null;
  }

  /// Добавить сотрудника по Telegram ID
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UserCreate] userCreate (required):
  Future<Response> adminCreateUserWithHttpInfo(UserCreate userCreate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/users';

    // ignore: prefer_final_locals
    Object? postBody = userCreate;

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

  /// Добавить сотрудника по Telegram ID
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [UserCreate] userCreate (required):
  Future<User?> adminCreateUser(UserCreate userCreate, { Future<void>? abortTrigger, }) async {
    final response = await adminCreateUserWithHttpInfo(userCreate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'User',) as User;
    
    }
    return null;
  }

  /// Сроки первого ответа по приоритетам
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> adminGetDeadlineRulesWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/deadline-rules';

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

  /// Сроки первого ответа по приоритетам
  ///
  /// Только администратор, остальным — `403`.
  Future<List<DeadlineRule>?> adminGetDeadlineRules({ Future<void>? abortTrigger, }) async {
    final response = await adminGetDeadlineRulesWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<DeadlineRule>') as List)
        .cast<DeadlineRule>()
        .toList(growable: false);

    }
    return null;
  }

  /// Общие настройки
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> adminGetSettingsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/settings';

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

  /// Общие настройки
  ///
  /// Только администратор, остальным — `403`.
  Future<SystemSettings?> adminGetSettings({ Future<void>? abortTrigger, }) async {
    final response = await adminGetSettingsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SystemSettings',) as SystemSettings;
    
    }
    return null;
  }

  /// Изменить категорию: ответственный, заместитель, подразделение, активность
  ///
  /// Изменение влияет на маршрутизацию новых обращений; уже назначенные не переназначаются. Только администратор, остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] categoryId (required):
  ///
  /// * [CategoryUpdate] categoryUpdate (required):
  Future<Response> adminUpdateCategoryWithHttpInfo(int categoryId, CategoryUpdate categoryUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/categories/{category_id}'
      .replaceAll('{category_id}', categoryId.toString());

    // ignore: prefer_final_locals
    Object? postBody = categoryUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Изменить категорию: ответственный, заместитель, подразделение, активность
  ///
  /// Изменение влияет на маршрутизацию новых обращений; уже назначенные не переназначаются. Только администратор, остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] categoryId (required):
  ///
  /// * [CategoryUpdate] categoryUpdate (required):
  Future<Category?> adminUpdateCategory(int categoryId, CategoryUpdate categoryUpdate, { Future<void>? abortTrigger, }) async {
    final response = await adminUpdateCategoryWithHttpInfo(categoryId, categoryUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Category',) as Category;
    
    }
    return null;
  }

  /// Изменить сроки первого ответа
  ///
  /// Применяются к новым обращениям и к переназначениям после изменения. Только администратор, остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [List<DeadlineRule>] deadlineRule (required):
  Future<Response> adminUpdateDeadlineRulesWithHttpInfo(List<DeadlineRule> deadlineRule, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/deadline-rules';

    // ignore: prefer_final_locals
    Object? postBody = deadlineRule;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Изменить сроки первого ответа
  ///
  /// Применяются к новым обращениям и к переназначениям после изменения. Только администратор, остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [List<DeadlineRule>] deadlineRule (required):
  Future<List<DeadlineRule>?> adminUpdateDeadlineRules(List<DeadlineRule> deadlineRule, { Future<void>? abortTrigger, }) async {
    final response = await adminUpdateDeadlineRulesWithHttpInfo(deadlineRule, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<DeadlineRule>') as List)
        .cast<DeadlineRule>()
        .toList(growable: false);

    }
    return null;
  }

  /// Изменить название или руководителя подразделения
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] departmentId (required):
  ///
  /// * [DepartmentUpdate] departmentUpdate (required):
  Future<Response> adminUpdateDepartmentWithHttpInfo(int departmentId, DepartmentUpdate departmentUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/departments/{department_id}'
      .replaceAll('{department_id}', departmentId.toString());

    // ignore: prefer_final_locals
    Object? postBody = departmentUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Изменить название или руководителя подразделения
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [int] departmentId (required):
  ///
  /// * [DepartmentUpdate] departmentUpdate (required):
  Future<Department?> adminUpdateDepartment(int departmentId, DepartmentUpdate departmentUpdate, { Future<void>? abortTrigger, }) async {
    final response = await adminUpdateDepartmentWithHttpInfo(departmentId, departmentUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Department',) as Department;
    
    }
    return null;
  }

  /// Изменить время утренней сводки
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AdminUpdateSettingsRequest] adminUpdateSettingsRequest (required):
  Future<Response> adminUpdateSettingsWithHttpInfo(AdminUpdateSettingsRequest adminUpdateSettingsRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/settings';

    // ignore: prefer_final_locals
    Object? postBody = adminUpdateSettingsRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Изменить время утренней сводки
  ///
  /// Только администратор, остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [AdminUpdateSettingsRequest] adminUpdateSettingsRequest (required):
  Future<SystemSettings?> adminUpdateSettings(AdminUpdateSettingsRequest adminUpdateSettingsRequest, { Future<void>? abortTrigger, }) async {
    final response = await adminUpdateSettingsWithHttpInfo(adminUpdateSettingsRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SystemSettings',) as SystemSettings;
    
    }
    return null;
  }

  /// Изменить роль, подразделение, отсутствие, доступ
  ///
  /// `is_absent=true` — новые обращения его категорий получает заместитель. `is_disabled=true` — вход запрещён, текущие сессии сбрасываются. Только администратор, остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [UserUpdate] userUpdate (required):
  Future<Response> adminUpdateUserWithHttpInfo(int userId, UserUpdate userUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/admin/users/{user_id}'
      .replaceAll('{user_id}', userId.toString());

    // ignore: prefer_final_locals
    Object? postBody = userUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Изменить роль, подразделение, отсутствие, доступ
  ///
  /// `is_absent=true` — новые обращения его категорий получает заместитель. `is_disabled=true` — вход запрещён, текущие сессии сбрасываются. Только администратор, остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [UserUpdate] userUpdate (required):
  Future<User?> adminUpdateUser(int userId, UserUpdate userUpdate, { Future<void>? abortTrigger, }) async {
    final response = await adminUpdateUserWithHttpInfo(userId, userUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'User',) as User;
    
    }
    return null;
  }
}
