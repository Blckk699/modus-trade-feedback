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

  /// Возврат с портала Битрикс24 (адрес возврата локального приложения)
  ///
  /// Этот адрес указывается в настройках локального приложения на портале. Клиент его не вызывает. Сервер проверяет `state` (cookie, срок, одноразовость) и `domain`, меняет `code` на токен портала, узнаёт пользователя через `user.current` и сопоставляет его с сотрудником: по `bitrix_user_id`, затем по почте без учёта регистра (при совпадении запоминает `bitrix_user_id`). Токены портала не хранятся.  Ответ всегда `302` на страницу клиента `<веб>/auth/bitrix/done`: - успех — `?code=<одноразовый код>`: клиент меняет его на сессию через `POST /auth/bitrix/exchange`.   Токена сессии в адресной строке нет; код живёт 60 секунд; - отказ — `?error=<код ошибки>`: `access_request_pending` (незнакомому сотруднику создана заявка на доступ   с именем и почтой из портала, либо она уже на рассмотрении), `access_request_rejected`, `user_disabled`,   `invalid_bitrix_auth` (неверный или просроченный `state`, чужой портал, портал отклонил `code`),   `bitrix_unavailable` (портал не ответил). 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] code:
  ///   Авторизационный код портала, живёт 30 секунд
  ///
  /// * [String] state:
  ///
  /// * [String] domain:
  ///   Домен портала
  ///
  /// * [String] memberId:
  Future<Response> bitrixLoginCallbackWithHttpInfo({ String? code, String? state, String? domain, String? memberId, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/bitrix/callback';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (code != null) {
      queryParams.addAll(_queryParams('', 'code', code));
    }
    if (state != null) {
      queryParams.addAll(_queryParams('', 'state', state));
    }
    if (domain != null) {
      queryParams.addAll(_queryParams('', 'domain', domain));
    }
    if (memberId != null) {
      queryParams.addAll(_queryParams('', 'member_id', memberId));
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

  /// Возврат с портала Битрикс24 (адрес возврата локального приложения)
  ///
  /// Этот адрес указывается в настройках локального приложения на портале. Клиент его не вызывает. Сервер проверяет `state` (cookie, срок, одноразовость) и `domain`, меняет `code` на токен портала, узнаёт пользователя через `user.current` и сопоставляет его с сотрудником: по `bitrix_user_id`, затем по почте без учёта регистра (при совпадении запоминает `bitrix_user_id`). Токены портала не хранятся.  Ответ всегда `302` на страницу клиента `<веб>/auth/bitrix/done`: - успех — `?code=<одноразовый код>`: клиент меняет его на сессию через `POST /auth/bitrix/exchange`.   Токена сессии в адресной строке нет; код живёт 60 секунд; - отказ — `?error=<код ошибки>`: `access_request_pending` (незнакомому сотруднику создана заявка на доступ   с именем и почтой из портала, либо она уже на рассмотрении), `access_request_rejected`, `user_disabled`,   `invalid_bitrix_auth` (неверный или просроченный `state`, чужой портал, портал отклонил `code`),   `bitrix_unavailable` (портал не ответил). 
  ///
  /// Parameters:
  ///
  /// * [String] code:
  ///   Авторизационный код портала, живёт 30 секунд
  ///
  /// * [String] state:
  ///
  /// * [String] domain:
  ///   Домен портала
  ///
  /// * [String] memberId:
  Future<void> bitrixLoginCallback({ String? code, String? state, String? domain, String? memberId, Future<void>? abortTrigger, }) async {
    final response = await bitrixLoginCallbackWithHttpInfo(code: code, state: state, domain: domain, memberId: memberId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

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

  /// Обменять одноразовый код входа через Битрикс24 на сессию
  ///
  /// Страница `<веб>/auth/bitrix/done` берёт `code` из адреса и получает ту же сессию, что у остальных способов входа. Код одноразовый и живёт 60 секунд; неверный, использованный или просроченный — `401 invalid_bitrix_auth`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ExchangeBitrixLoginRequest] exchangeBitrixLoginRequest (required):
  Future<Response> exchangeBitrixLoginWithHttpInfo(ExchangeBitrixLoginRequest exchangeBitrixLoginRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/bitrix/exchange';

    // ignore: prefer_final_locals
    Object? postBody = exchangeBitrixLoginRequest;

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

  /// Обменять одноразовый код входа через Битрикс24 на сессию
  ///
  /// Страница `<веб>/auth/bitrix/done` берёт `code` из адреса и получает ту же сессию, что у остальных способов входа. Код одноразовый и живёт 60 секунд; неверный, использованный или просроченный — `401 invalid_bitrix_auth`. 
  ///
  /// Parameters:
  ///
  /// * [ExchangeBitrixLoginRequest] exchangeBitrixLoginRequest (required):
  Future<Session?> exchangeBitrixLogin(ExchangeBitrixLoginRequest exchangeBitrixLoginRequest, { Future<void>? abortTrigger, }) async {
    final response = await exchangeBitrixLoginWithHttpInfo(exchangeBitrixLoginRequest, abortTrigger: abortTrigger,);
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

  /// Какие способы входа включены
  ///
  /// Публичный маршрут для экрана входа. `bitrix24=false` — кнопку «Войти через Битрикс24» не показывать: на сервере не заданы `BITRIX24_CLIENT_ID`, `BITRIX24_CLIENT_SECRET` и `BITRIX24_PORTAL`. 
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAuthMethodsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/methods';

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

  /// Какие способы входа включены
  ///
  /// Публичный маршрут для экрана входа. `bitrix24=false` — кнопку «Войти через Битрикс24» не показывать: на сервере не заданы `BITRIX24_CLIENT_ID`, `BITRIX24_CLIENT_SECRET` и `BITRIX24_PORTAL`. 
  Future<AuthMethods?> getAuthMethods({ Future<void>? abortTrigger, }) async {
    final response = await getAuthMethodsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuthMethods',) as AuthMethods;
    
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

  /// Вход по почте и паролю
  ///
  /// Выдаёт ту же сессию, что остальные способы входа. Ответы различают причину: - `401 invalid_credentials` — неверная почта или пароль; - `403 access_request_pending` — заявка на рассмотрении; `403 access_request_rejected` — заявка отклонена; - `403 user_disabled` — доступ отключён; - `403 password_change_required` — вход с временным паролем от администратора: повторите запрос с `new_password`; - `429 too_many_requests` — 5 неудачных попыток подряд по этой почте, вход заблокирован на 5 минут. Про заявку и временный пароль сервер говорит, только если пароль верный. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [EmailLogin] emailLogin (required):
  Future<Response> loginByEmailWithHttpInfo(EmailLogin emailLogin, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/login';

    // ignore: prefer_final_locals
    Object? postBody = emailLogin;

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

  /// Вход по почте и паролю
  ///
  /// Выдаёт ту же сессию, что остальные способы входа. Ответы различают причину: - `401 invalid_credentials` — неверная почта или пароль; - `403 access_request_pending` — заявка на рассмотрении; `403 access_request_rejected` — заявка отклонена; - `403 user_disabled` — доступ отключён; - `403 password_change_required` — вход с временным паролем от администратора: повторите запрос с `new_password`; - `429 too_many_requests` — 5 неудачных попыток подряд по этой почте, вход заблокирован на 5 минут. Про заявку и временный пароль сервер говорит, только если пароль верный. 
  ///
  /// Parameters:
  ///
  /// * [EmailLogin] emailLogin (required):
  Future<Session?> loginByEmail(EmailLogin emailLogin, { Future<void>? abortTrigger, }) async {
    final response = await loginByEmailWithHttpInfo(emailLogin, abortTrigger: abortTrigger,);
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
  /// Код обменивается на сессию один раз и истекает через `ttl_seconds` после выдачи. Защита от перебора: после 5 неудачных попыток с одного адреса за 15 минут — `429 too_many_requests` (адрес клиента берётся из `X-Forwarded-For` только от доверенного прокси). При массовом переборе со многих адресов активные коды сжигаются — пользователь запрашивает новый в боте. 
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
  /// Код обменивается на сессию один раз и истекает через `ttl_seconds` после выдачи. Защита от перебора: после 5 неудачных попыток с одного адреса за 15 минут — `429 too_many_requests` (адрес клиента берётся из `X-Forwarded-For` только от доверенного прокси). При массовом переборе со многих адресов активные коды сжигаются — пользователь запрашивает новый в боте. 
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

  /// Регистрация по рабочей почте и паролю
  ///
  /// Без `invite_token` — заявка на доступ (`status=pending`), как заявка из Telegram: те же уведомления администратору и собственнику, войти до одобрения нельзя. Повторная регистрация с той же почтой, пока заявка на рассмотрении, обновляет её (`200`). С действующим `invite_token` — сразу пользователь с ролью и подразделением приглашения и сессия (`201`). Почта уникальна без учёта регистра и не подтверждается письмом. Пароль — от 8 символов, хранится только хешем. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [EmailRegister] emailRegister (required):
  Future<Response> registerByEmailWithHttpInfo(EmailRegister emailRegister, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/register';

    // ignore: prefer_final_locals
    Object? postBody = emailRegister;

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

  /// Регистрация по рабочей почте и паролю
  ///
  /// Без `invite_token` — заявка на доступ (`status=pending`), как заявка из Telegram: те же уведомления администратору и собственнику, войти до одобрения нельзя. Повторная регистрация с той же почтой, пока заявка на рассмотрении, обновляет её (`200`). С действующим `invite_token` — сразу пользователь с ролью и подразделением приглашения и сессия (`201`). Почта уникальна без учёта регистра и не подтверждается письмом. Пароль — от 8 символов, хранится только хешем. 
  ///
  /// Parameters:
  ///
  /// * [EmailRegister] emailRegister (required):
  Future<RegisterResult?> registerByEmail(EmailRegister emailRegister, { Future<void>? abortTrigger, }) async {
    final response = await registerByEmailWithHttpInfo(emailRegister, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RegisterResult',) as RegisterResult;
    
    }
    return null;
  }

  /// Начать вход через Битрикс24
  ///
  /// Клиент открывает этот адрес обычным переходом браузера (не `fetch`). Сервер отвечает `302` на `https://<портал>/oauth/authorize/?client_id=…&state=…` и ставит cookie с `state`: он одноразовый, живёт 10 минут и привязан к браузеру. После входа портал возвращает пользователя на `GET /auth/bitrix/callback`. Вход через Битрикс24 не настроен — `404 not_found`. 
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> startBitrixLoginWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/bitrix/start';

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

  /// Начать вход через Битрикс24
  ///
  /// Клиент открывает этот адрес обычным переходом браузера (не `fetch`). Сервер отвечает `302` на `https://<портал>/oauth/authorize/?client_id=…&state=…` и ставит cookie с `state`: он одноразовый, живёт 10 минут и привязан к браузеру. После входа портал возвращает пользователя на `GET /auth/bitrix/callback`. Вход через Битрикс24 не настроен — `404 not_found`. 
  Future<void> startBitrixLogin({ Future<void>? abortTrigger, }) async {
    final response = await startBitrixLoginWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Переключиться на связанный аккаунт (демо-переключатель ролей)
  ///
  /// Выдаёт новую сессию от имени выбранного пользователя — с теми же правами, что при обычном входе под ним. Доступные пользователи — `Me.switch_targets`. Группа связанных аккаунтов задаётся настройкой вне репозитория; без неё список пуст, а маршрут отвечает `403`. Переключение пишется в журнал. Текущая сессия остаётся действующей: клиент заменяет токен на новый. Пользователь не из группы — `403 forbidden`; у выбранного отключён доступ — `403 user_disabled`. Только для сессии клиента: бот с сервисным ключом получает `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SwitchAccountRequest] switchAccountRequest (required):
  Future<Response> switchAccountWithHttpInfo(SwitchAccountRequest switchAccountRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/switch';

    // ignore: prefer_final_locals
    Object? postBody = switchAccountRequest;

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

  /// Переключиться на связанный аккаунт (демо-переключатель ролей)
  ///
  /// Выдаёт новую сессию от имени выбранного пользователя — с теми же правами, что при обычном входе под ним. Доступные пользователи — `Me.switch_targets`. Группа связанных аккаунтов задаётся настройкой вне репозитория; без неё список пуст, а маршрут отвечает `403`. Переключение пишется в журнал. Текущая сессия остаётся действующей: клиент заменяет токен на новый. Пользователь не из группы — `403 forbidden`; у выбранного отключён доступ — `403 user_disabled`. Только для сессии клиента: бот с сервисным ключом получает `403`. 
  ///
  /// Parameters:
  ///
  /// * [SwitchAccountRequest] switchAccountRequest (required):
  Future<Session?> switchAccount(SwitchAccountRequest switchAccountRequest, { Future<void>? abortTrigger, }) async {
    final response = await switchAccountWithHttpInfo(switchAccountRequest, abortTrigger: abortTrigger,);
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
}
