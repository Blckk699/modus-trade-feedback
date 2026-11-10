//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuthApi {
  AuthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Dev-вход под выбранным пользователем
  ///
  /// Работает только при `DEV_LOGIN_ENABLED=true`, иначе `403 dev_login_disabled`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DevLoginRequest] devLoginRequest (required):
  Future<Response> devLoginWithHttpInfo(DevLoginRequest devLoginRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/dev/login';

    // ignore: prefer_final_locals
    Object? postBody = devLoginRequest;

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

  /// Dev-вход под выбранным пользователем
  ///
  /// Работает только при `DEV_LOGIN_ENABLED=true`, иначе `403 dev_login_disabled`.
  ///
  /// Parameters:
  ///
  /// * [DevLoginRequest] devLoginRequest (required):
  Future<Session?> devLogin(DevLoginRequest devLoginRequest, { Future<void>? abortTrigger, }) async {
    final response = await devLoginWithHttpInfo(devLoginRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Session',) as Session;
    
    }
    return null;
  }

  /// Выдать одноразовый код входа (только бот)
  ///
  /// Бот вызывает с `X-Service-Key` и `X-Telegram-Id` пользователя и показывает код в чате. Пользователь вводит код в мобильном приложении (`POST /auth/code`). 
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> issueLoginCodeWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/login-codes';

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

  /// Выдать одноразовый код входа (только бот)
  ///
  /// Бот вызывает с `X-Service-Key` и `X-Telegram-Id` пользователя и показывает код в чате. Пользователь вводит код в мобильном приложении (`POST /auth/code`). 
  Future<LoginCode?> issueLoginCode({ Future<void>? abortTrigger, }) async {
    final response = await issueLoginCodeWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LoginCode',) as LoginCode;
    
    }
    return null;
  }

  /// Список пользователей для dev-входа
  ///
  /// Работает только при `DEV_LOGIN_ENABLED=true`. На сервере для демо выключен — `403 dev_login_disabled`.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listDevUsersWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/dev/users';

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

  /// Список пользователей для dev-входа
  ///
  /// Работает только при `DEV_LOGIN_ENABLED=true`. На сервере для демо выключен — `403 dev_login_disabled`.
  Future<List<UserBrief>?> listDevUsers({ Future<void>? abortTrigger, }) async {
    final response = await listDevUsersWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<UserBrief>') as List)
        .cast<UserBrief>()
        .toList(growable: false);

    }
    return null;
  }

  /// Вход из Mini App по initData
  ///
  /// Бэкенд проверяет подпись `initData` токеном бота и выдаёт сессию.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MiniAppLoginRequest] miniAppLoginRequest (required):
  Future<Response> loginMiniAppWithHttpInfo(MiniAppLoginRequest miniAppLoginRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/telegram/mini-app';

    // ignore: prefer_final_locals
    Object? postBody = miniAppLoginRequest;

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

  /// Вход из Mini App по initData
  ///
  /// Бэкенд проверяет подпись `initData` токеном бота и выдаёт сессию.
  ///
  /// Parameters:
  ///
  /// * [MiniAppLoginRequest] miniAppLoginRequest (required):
  Future<Session?> loginMiniApp(MiniAppLoginRequest miniAppLoginRequest, { Future<void>? abortTrigger, }) async {
    final response = await loginMiniAppWithHttpInfo(miniAppLoginRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Session',) as Session;
    
    }
    return null;
  }

  /// Вход через Telegram Login в вебе
  ///
  /// Тело — поля, которые виджет Telegram Login передаёт в колбэк, без изменений.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TelegramWidgetLoginRequest] telegramWidgetLoginRequest (required):
  Future<Response> loginTelegramWidgetWithHttpInfo(TelegramWidgetLoginRequest telegramWidgetLoginRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/telegram/widget';

    // ignore: prefer_final_locals
    Object? postBody = telegramWidgetLoginRequest;

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

  /// Вход через Telegram Login в вебе
  ///
  /// Тело — поля, которые виджет Telegram Login передаёт в колбэк, без изменений.
  ///
  /// Parameters:
  ///
  /// * [TelegramWidgetLoginRequest] telegramWidgetLoginRequest (required):
  Future<Session?> loginTelegramWidget(TelegramWidgetLoginRequest telegramWidgetLoginRequest, { Future<void>? abortTrigger, }) async {
    final response = await loginTelegramWidgetWithHttpInfo(telegramWidgetLoginRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Session',) as Session;
    
    }
    return null;
  }

  /// Вход в мобильное приложение по одноразовому коду из бота
  ///
  /// Код обменивается на сессию один раз и истекает через `ttl_seconds` после выдачи.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CodeLoginRequest] codeLoginRequest (required):
  Future<Response> loginWithCodeWithHttpInfo(CodeLoginRequest codeLoginRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/code';

    // ignore: prefer_final_locals
    Object? postBody = codeLoginRequest;

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

  /// Вход в мобильное приложение по одноразовому коду из бота
  ///
  /// Код обменивается на сессию один раз и истекает через `ttl_seconds` после выдачи.
  ///
  /// Parameters:
  ///
  /// * [CodeLoginRequest] codeLoginRequest (required):
  Future<Session?> loginWithCode(CodeLoginRequest codeLoginRequest, { Future<void>? abortTrigger, }) async {
    final response = await loginWithCodeWithHttpInfo(codeLoginRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Session',) as Session;
    
    }
    return null;
  }

  /// Выход, токен становится недействительным
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> logoutWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/logout';

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

  /// Выход, токен становится недействительным
  Future<void> logout({ Future<void>? abortTrigger, }) async {
    final response = await logoutWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
