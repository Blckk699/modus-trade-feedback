//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class BotApi {
  BotApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Подтвердить доставку
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  ///
  /// * [AckNotificationRequest] ackNotificationRequest:
  Future<Response> ackNotificationWithHttpInfo(int notificationId, { AckNotificationRequest? ackNotificationRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bot/notifications/{notification_id}/ack'
      .replaceAll('{notification_id}', notificationId.toString());

    // ignore: prefer_final_locals
    Object? postBody = ackNotificationRequest;

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

  /// Подтвердить доставку
  ///
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  ///
  /// * [AckNotificationRequest] ackNotificationRequest:
  Future<void> ackNotification(int notificationId, { AckNotificationRequest? ackNotificationRequest, Future<void>? abortTrigger, }) async {
    final response = await ackNotificationWithHttpInfo(notificationId, ackNotificationRequest: ackNotificationRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Сообщить о неудачной доставке
  ///
  /// Уведомление вернётся в `pending` позже с нарастающей паузой. Пользователь заблокировал бота — `permanent=true`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  ///
  /// * [FailNotificationRequest] failNotificationRequest:
  Future<Response> failNotificationWithHttpInfo(int notificationId, { FailNotificationRequest? failNotificationRequest, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bot/notifications/{notification_id}/fail'
      .replaceAll('{notification_id}', notificationId.toString());

    // ignore: prefer_final_locals
    Object? postBody = failNotificationRequest;

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

  /// Сообщить о неудачной доставке
  ///
  /// Уведомление вернётся в `pending` позже с нарастающей паузой. Пользователь заблокировал бота — `permanent=true`.
  ///
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  ///
  /// * [FailNotificationRequest] failNotificationRequest:
  Future<void> failNotification(int notificationId, { FailNotificationRequest? failNotificationRequest, Future<void>? abortTrigger, }) async {
    final response = await failNotificationWithHttpInfo(notificationId, failNotificationRequest: failNotificationRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
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

  /// Неотправленные уведомления для доставки в Telegram
  ///
  /// Бот опрашивает раз в несколько секунд. Возвращаются уведомления без подтверждённой доставки, у которых наступило время следующей попытки. Подтверждённое (`ack`) больше не возвращается. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] limit:
  Future<Response> listPendingNotificationsWithHttpInfo({ int? limit, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/bot/notifications/pending';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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

  /// Неотправленные уведомления для доставки в Telegram
  ///
  /// Бот опрашивает раз в несколько секунд. Возвращаются уведомления без подтверждённой доставки, у которых наступило время следующей попытки. Подтверждённое (`ack`) больше не возвращается. 
  ///
  /// Parameters:
  ///
  /// * [int] limit:
  Future<List<BotNotification>?> listPendingNotifications({ int? limit, Future<void>? abortTrigger, }) async {
    final response = await listPendingNotificationsWithHttpInfo(limit: limit, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<BotNotification>') as List)
        .cast<BotNotification>()
        .toList(growable: false);

    }
    return null;
  }
}
