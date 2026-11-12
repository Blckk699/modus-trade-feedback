//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiClient {
  ApiClient({this.basePath = 'http://localhost:4010', this.authentication,});

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType, {
    Future<void>? abortTrigger,
  }) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty ? '?${urlEncodedQueryParams.join('&')}' : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (
        body is MultipartFile && (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data'))
      ) {
        final request = AbortableStreamedRequest(method, uri, abortTrigger: abortTrigger);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
          request.sink.add,
          onDone: request.sink.close,
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error, StackTrace trace) => request.sink.close(),
          cancelOnError: true,
        );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = AbortableMultipartRequest(method, uri, abortTrigger: abortTrigger);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
        ? formParams
        : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      final request = AbortableRequest(method, uri, abortTrigger: abortTrigger);
      if (nullableHeaderParams != null) {
        request.headers.addAll(nullableHeaderParams);
      }
      if (msgBody is String && msgBody.isNotEmpty) {
        request.body = msgBody;
      } else if (msgBody is List<int> && msgBody.isNotEmpty) {
        request.bodyBytes = msgBody;
      } else if (msgBody is Map<String, String>) {
        request.bodyFields = msgBody;
      }
      final response = await _client.send(request);
      return Response.fromStream(response);
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }
  }

  Future<dynamic> deserializeAsync(String value, String targetType, {bool growable = false,}) async =>
    // ignore: deprecated_member_use_from_same_package
    deserialize(value, targetType, growable: growable);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(String value, String targetType, {bool growable = false,}) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType = targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
      ? value
      : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(dynamic value, String targetType, {bool growable = false,}) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'AcceptFeedbackRequest':
          return AcceptFeedbackRequest.fromJson(value);
        case 'AccessRequest':
          return AccessRequest.fromJson(value);
        case 'AccessRequestApprove':
          return AccessRequestApprove.fromJson(value);
        case 'AccessRequestPage':
          return AccessRequestPage.fromJson(value);
        case 'AccessRequestReject':
          return AccessRequestReject.fromJson(value);
        case 'AccessRequestStatus':
          return AccessRequestStatusTypeTransformer().decode(value);
        case 'AccessRequestSubmit':
          return AccessRequestSubmit.fromJson(value);
        case 'AccessStatus':
          return AccessStatus.fromJson(value);
        case 'AckNotificationRequest':
          return AckNotificationRequest.fromJson(value);
        case 'AdminUpdateSettingsRequest':
          return AdminUpdateSettingsRequest.fromJson(value);
        case 'AnalyticsSummary':
          return AnalyticsSummary.fromJson(value);
        case 'Appeal':
          return Appeal.fromJson(value);
        case 'AppealAction':
          return AppealActionTypeTransformer().decode(value);
        case 'AppealCreate':
          return AppealCreate.fromJson(value);
        case 'AppealDraft':
          return AppealDraft.fromJson(value);
        case 'AppealListItem':
          return AppealListItem.fromJson(value);
        case 'AppealPage':
          return AppealPage.fromJson(value);
        case 'AppealRef':
          return AppealRef.fromJson(value);
        case 'AppealScope':
          return AppealScopeTypeTransformer().decode(value);
        case 'AppealSource':
          return AppealSourceTypeTransformer().decode(value);
        case 'AppealStatus':
          return AppealStatusTypeTransformer().decode(value);
        case 'AppealType':
          return AppealTypeTypeTransformer().decode(value);
        case 'AssignableRole':
          return AssignableRoleTypeTransformer().decode(value);
        case 'AssigneeLoad':
          return AssigneeLoad.fromJson(value);
        case 'Attachment':
          return Attachment.fromJson(value);
        case 'AuthMethods':
          return AuthMethods.fromJson(value);
        case 'BitrixTask':
          return BitrixTask.fromJson(value);
        case 'BotNotification':
          return BotNotification.fromJson(value);
        case 'BotNotificationAllOfRecipient':
          return BotNotificationAllOfRecipient.fromJson(value);
        case 'Category':
          return Category.fromJson(value);
        case 'CategoryRef':
          return CategoryRef.fromJson(value);
        case 'CategoryUpdate':
          return CategoryUpdate.fromJson(value);
        case 'CategoryWrite':
          return CategoryWrite.fromJson(value);
        case 'CloseDiscussionRequest':
          return CloseDiscussionRequest.fromJson(value);
        case 'ClosedReason':
          return ClosedReasonTypeTransformer().decode(value);
        case 'CodeLoginRequest':
          return CodeLoginRequest.fromJson(value);
        case 'CountByCategory':
          return CountByCategory.fromJson(value);
        case 'CountByStatus':
          return CountByStatus.fromJson(value);
        case 'CountByType':
          return CountByType.fromJson(value);
        case 'CredentialsUpdate':
          return CredentialsUpdate.fromJson(value);
        case 'DeadlineRule':
          return DeadlineRule.fromJson(value);
        case 'Department':
          return Department.fromJson(value);
        case 'DepartmentRef':
          return DepartmentRef.fromJson(value);
        case 'DepartmentUpdate':
          return DepartmentUpdate.fromJson(value);
        case 'DepartmentWrite':
          return DepartmentWrite.fromJson(value);
        case 'DevLoginRequest':
          return DevLoginRequest.fromJson(value);
        case 'Dictionaries':
          return Dictionaries.fromJson(value);
        case 'DictionariesActionsInner':
          return DictionariesActionsInner.fromJson(value);
        case 'DictionariesStatusesInner':
          return DictionariesStatusesInner.fromJson(value);
        case 'Digest':
          return Digest.fromJson(value);
        case 'Discussion':
          return Discussion.fromJson(value);
        case 'DiscussionAppeal':
          return DiscussionAppeal.fromJson(value);
        case 'DiscussionComment':
          return DiscussionComment.fromJson(value);
        case 'DiscussionCreate':
          return DiscussionCreate.fromJson(value);
        case 'DiscussionPage':
          return DiscussionPage.fromJson(value);
        case 'DiscussionRef':
          return DiscussionRef.fromJson(value);
        case 'DiscussionStatus':
          return DiscussionStatusTypeTransformer().decode(value);
        case 'DueFilter':
          return DueFilterTypeTransformer().decode(value);
        case 'DueState':
          return DueStateTypeTransformer().decode(value);
        case 'DuplicateSuggestion':
          return DuplicateSuggestion.fromJson(value);
        case 'EmailLogin':
          return EmailLogin.fromJson(value);
        case 'EmailRegister':
          return EmailRegister.fromJson(value);
        case 'Error':
          return Error.fromJson(value);
        case 'ErrorCode':
          return ErrorCodeTypeTransformer().decode(value);
        case 'ErrorError':
          return ErrorError.fromJson(value);
        case 'ExchangeBitrixLoginRequest':
          return ExchangeBitrixLoginRequest.fromJson(value);
        case 'FailNotificationRequest':
          return FailNotificationRequest.fromJson(value);
        case 'FeedItem':
          return FeedItem.fromJson(value);
        case 'FeedPage':
          return FeedPage.fromJson(value);
        case 'GetHealth200Response':
          return GetHealth200Response.fromJson(value);
        case 'HistoryEvent':
          return HistoryEvent.fromJson(value);
        case 'ImplementAppealRequest':
          return ImplementAppealRequest.fromJson(value);
        case 'Invite':
          return Invite.fromJson(value);
        case 'InviteAccept':
          return InviteAccept.fromJson(value);
        case 'InviteAccepted':
          return InviteAccepted.fromJson(value);
        case 'InviteCreate':
          return InviteCreate.fromJson(value);
        case 'InviteCreated':
          return InviteCreated.fromJson(value);
        case 'InvitePreview':
          return InvitePreview.fromJson(value);
        case 'InviteState':
          return InviteStateTypeTransformer().decode(value);
        case 'LabeledCode':
          return LabeledCode.fromJson(value);
        case 'LoginCode':
          return LoginCode.fromJson(value);
        case 'MarkReadRequest':
          return MarkReadRequest.fromJson(value);
        case 'Me':
          return Me.fromJson(value);
        case 'Meeting':
          return Meeting.fromJson(value);
        case 'MeetingBrief':
          return MeetingBrief.fromJson(value);
        case 'MeetingDraft':
          return MeetingDraft.fromJson(value);
        case 'MeetingDraftStatus':
          return MeetingDraftStatusTypeTransformer().decode(value);
        case 'MeetingDraftUpdate':
          return MeetingDraftUpdate.fromJson(value);
        case 'MeetingStatus':
          return MeetingStatusTypeTransformer().decode(value);
        case 'MergeAppealRequest':
          return MergeAppealRequest.fromJson(value);
        case 'Message':
          return Message.fromJson(value);
        case 'MiniAppLoginRequest':
          return MiniAppLoginRequest.fromJson(value);
        case 'NameConsent':
          return NameConsentTypeTransformer().decode(value);
        case 'Notification':
          return Notification.fromJson(value);
        case 'NotificationButton':
          return NotificationButton.fromJson(value);
        case 'NotificationButtonType':
          return NotificationButtonTypeTypeTransformer().decode(value);
        case 'NotificationKind':
          return NotificationKindTypeTransformer().decode(value);
        case 'NotificationPage':
          return NotificationPage.fromJson(value);
        case 'Permissions':
          return Permissions.fromJson(value);
        case 'PostMessageRequest':
          return PostMessageRequest.fromJson(value);
        case 'Priority':
          return PriorityTypeTransformer().decode(value);
        case 'ReassignAppealRequest':
          return ReassignAppealRequest.fromJson(value);
        case 'RegisterResult':
          return RegisterResult.fromJson(value);
        case 'RejectAppealRequest':
          return RejectAppealRequest.fromJson(value);
        case 'RepeatedTopic':
          return RepeatedTopic.fromJson(value);
        case 'RequestInfoRequest':
          return RequestInfoRequest.fromJson(value);
        case 'Role':
          return RoleTypeTransformer().decode(value);
        case 'Session':
          return Session.fromJson(value);
        case 'SessionToken':
          return SessionToken.fromJson(value);
        case 'SetNameConsentRequest':
          return SetNameConsentRequest.fromJson(value);
        case 'StartWorkRequest':
          return StartWorkRequest.fromJson(value);
        case 'StuckAppeal':
          return StuckAppeal.fromJson(value);
        case 'SwitchAccountRequest':
          return SwitchAccountRequest.fromJson(value);
        case 'SystemSettings':
          return SystemSettings.fromJson(value);
        case 'TakeAppealRequest':
          return TakeAppealRequest.fromJson(value);
        case 'TelegramIdentity':
          return TelegramIdentity.fromJson(value);
        case 'TelegramWidgetLoginRequest':
          return TelegramWidgetLoginRequest.fromJson(value);
        case 'TemporaryPassword':
          return TemporaryPassword.fromJson(value);
        case 'TextDraftRequest':
          return TextDraftRequest.fromJson(value);
        case 'UnreadCount':
          return UnreadCount.fromJson(value);
        case 'User':
          return User.fromJson(value);
        case 'UserBrief':
          return UserBrief.fromJson(value);
        case 'UserCreate':
          return UserCreate.fromJson(value);
        case 'UserUpdate':
          return UserUpdate.fromJson(value);
        case 'ViewerRelation':
          return ViewerRelationTypeTransformer().decode(value);
        case 'VoteRequest':
          return VoteRequest.fromJson(value);
        case 'VoteValue':
          return VoteValueTypeTransformer().decode(value);
        default:
          dynamic match;
          if (value is List && (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toList(growable: growable);
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toSet();
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,)),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(HttpStatus.internalServerError, 'Exception during deserialization.', error, trace,);
    }
    throw ApiException(HttpStatus.internalServerError, 'Could not find a suitable class for deserialization',);
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : ApiClient.fromJson(
        json.decode(message.json),
        targetType,
        growable: message.growable,
      );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async => value == null ? '' : json.encode(value);
