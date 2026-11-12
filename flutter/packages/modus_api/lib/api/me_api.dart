//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MeApi {
  MeApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Кто я
  ///
  /// Роль, подразделение, назначения ответственным и права для навигации. Бот вызывает с `X-Service-Key` и `X-Telegram-Id`, чтобы опознать пользователя: незаведённый получает `403 user_not_registered`, отключённый — `403 user_disabled`. 
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMeWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me';

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

  /// Кто я
  ///
  /// Роль, подразделение, назначения ответственным и права для навигации. Бот вызывает с `X-Service-Key` и `X-Telegram-Id`, чтобы опознать пользователя: незаведённый получает `403 user_not_registered`, отключённый — `403 user_disabled`. 
  Future<Me?> getMe({ Future<void>? abortTrigger, }) async {
    final response = await getMeWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }

  /// Привязать Telegram к аккаунту
  ///
  /// Тело — поля Telegram Login без изменений, проверяются так же, как при входе виджетом. Потом пользователь входит через Telegram и получает уведомления бота. Telegram у другого сотрудника — `409 telegram_taken`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TelegramWidgetLoginRequest] telegramWidgetLoginRequest (required):
  Future<Response> linkTelegramWithHttpInfo(TelegramWidgetLoginRequest telegramWidgetLoginRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/telegram';

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

  /// Привязать Telegram к аккаунту
  ///
  /// Тело — поля Telegram Login без изменений, проверяются так же, как при входе виджетом. Потом пользователь входит через Telegram и получает уведомления бота. Telegram у другого сотрудника — `409 telegram_taken`. 
  ///
  /// Parameters:
  ///
  /// * [TelegramWidgetLoginRequest] telegramWidgetLoginRequest (required):
  Future<Me?> linkTelegram(TelegramWidgetLoginRequest telegramWidgetLoginRequest, { Future<void>? abortTrigger, }) async {
    final response = await linkTelegramWithHttpInfo(telegramWidgetLoginRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }

  /// Отвязать Telegram
  ///
  /// Можно, только если у аккаунта есть почта и пароль, иначе `409 last_login_method`. Уведомления бота перестают приходить.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> unlinkTelegramWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/telegram';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Отвязать Telegram
  ///
  /// Можно, только если у аккаунта есть почта и пароль, иначе `409 last_login_method`. Уведомления бота перестают приходить.
  Future<Me?> unlinkTelegram({ Future<void>? abortTrigger, }) async {
    final response = await unlinkTelegramWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }

  /// Задать или сменить почту и пароль
  ///
  /// Пользователь, пришедший через Telegram, задаёт почту и пароль (`email` и `new_password` обязательны). У кого пароль уже есть, указывает `current_password`; можно сменить почту, пароль или оба. Неверный текущий пароль — `422` с полем `current_password`. Почта у другого сотрудника — `409 email_taken`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CredentialsUpdate] credentialsUpdate (required):
  Future<Response> updateMyCredentialsWithHttpInfo(CredentialsUpdate credentialsUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/me/credentials';

    // ignore: prefer_final_locals
    Object? postBody = credentialsUpdate;

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

  /// Задать или сменить почту и пароль
  ///
  /// Пользователь, пришедший через Telegram, задаёт почту и пароль (`email` и `new_password` обязательны). У кого пароль уже есть, указывает `current_password`; можно сменить почту, пароль или оба. Неверный текущий пароль — `422` с полем `current_password`. Почта у другого сотрудника — `409 email_taken`. 
  ///
  /// Parameters:
  ///
  /// * [CredentialsUpdate] credentialsUpdate (required):
  Future<Me?> updateMyCredentials(CredentialsUpdate credentialsUpdate, { Future<void>? abortTrigger, }) async {
    final response = await updateMyCredentialsWithHttpInfo(credentialsUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Me',) as Me;
    
    }
    return null;
  }
}
