//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DiscussionsApi {
  DiscussionsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Зафиксировать итог обсуждения
  ///
  /// Руководитель подразделения обращения или собственник. Итог записывается в обсуждение и в историю обращения.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [CloseDiscussionRequest] closeDiscussionRequest (required):
  Future<Response> closeDiscussionWithHttpInfo(int discussionId, CloseDiscussionRequest closeDiscussionRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions/{discussion_id}/close'
      .replaceAll('{discussion_id}', discussionId.toString());

    // ignore: prefer_final_locals
    Object? postBody = closeDiscussionRequest;

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

  /// Зафиксировать итог обсуждения
  ///
  /// Руководитель подразделения обращения или собственник. Итог записывается в обсуждение и в историю обращения.
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [CloseDiscussionRequest] closeDiscussionRequest (required):
  Future<Discussion?> closeDiscussion(int discussionId, CloseDiscussionRequest closeDiscussionRequest, { Future<void>? abortTrigger, }) async {
    final response = await closeDiscussionWithHttpInfo(discussionId, closeDiscussionRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Discussion',) as Discussion;
    
    }
    return null;
  }

  /// Обсуждение
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  Future<Response> getDiscussionWithHttpInfo(int discussionId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions/{discussion_id}'
      .replaceAll('{discussion_id}', discussionId.toString());

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

  /// Обсуждение
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  Future<Discussion?> getDiscussion(int discussionId, { Future<void>? abortTrigger, }) async {
    final response = await getDiscussionWithHttpInfo(discussionId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Discussion',) as Discussion;
    
    }
    return null;
  }

  /// Публичные комментарии
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  Future<Response> listDiscussionCommentsWithHttpInfo(int discussionId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions/{discussion_id}/comments'
      .replaceAll('{discussion_id}', discussionId.toString());

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

  /// Публичные комментарии
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  Future<List<DiscussionComment>?> listDiscussionComments(int discussionId, { Future<void>? abortTrigger, }) async {
    final response = await listDiscussionCommentsWithHttpInfo(discussionId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<DiscussionComment>') as List)
        .cast<DiscussionComment>()
        .toList(growable: false);

    }
    return null;
  }

  /// Лента обсуждений
  ///
  /// Видна всем пользователям. Приватная переписка обращения сюда не попадает.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DiscussionStatus] status:
  ///
  /// * [int] page:
  ///
  /// * [int] pageSize:
  Future<Response> listDiscussionsWithHttpInfo({ DiscussionStatus? status, int? page, int? pageSize, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (pageSize != null) {
      queryParams.addAll(_queryParams('', 'page_size', pageSize));
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

  /// Лента обсуждений
  ///
  /// Видна всем пользователям. Приватная переписка обращения сюда не попадает.
  ///
  /// Parameters:
  ///
  /// * [DiscussionStatus] status:
  ///
  /// * [int] page:
  ///
  /// * [int] pageSize:
  Future<DiscussionPage?> listDiscussions({ DiscussionStatus? status, int? page, int? pageSize, Future<void>? abortTrigger, }) async {
    final response = await listDiscussionsWithHttpInfo(status: status, page: page, pageSize: pageSize, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DiscussionPage',) as DiscussionPage;
    
    }
    return null;
  }

  /// Оставить комментарий
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [PostMessageRequest] postMessageRequest (required):
  Future<Response> postDiscussionCommentWithHttpInfo(int discussionId, PostMessageRequest postMessageRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions/{discussion_id}/comments'
      .replaceAll('{discussion_id}', discussionId.toString());

    // ignore: prefer_final_locals
    Object? postBody = postMessageRequest;

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

  /// Оставить комментарий
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [PostMessageRequest] postMessageRequest (required):
  Future<DiscussionComment?> postDiscussionComment(int discussionId, PostMessageRequest postMessageRequest, { Future<void>? abortTrigger, }) async {
    final response = await postDiscussionCommentWithHttpInfo(discussionId, postMessageRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DiscussionComment',) as DiscussionComment;
    
    }
    return null;
  }

  /// Вынести обращение на общее обсуждение
  ///
  /// Ответственный, руководитель, собственник. Одно обсуждение на обращение (повторно — `409 conflict`). Автору уходит запрос на показ имени; до ответа `author_name_consent=pending` и в ленте стоит только подразделение. Администратору и сотруднику — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [DiscussionCreate] discussionCreate (required):
  Future<Response> publishDiscussionWithHttpInfo(int appealId, DiscussionCreate discussionCreate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/discussion'
      .replaceAll('{appeal_id}', appealId.toString());

    // ignore: prefer_final_locals
    Object? postBody = discussionCreate;

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

  /// Вынести обращение на общее обсуждение
  ///
  /// Ответственный, руководитель, собственник. Одно обсуждение на обращение (повторно — `409 conflict`). Автору уходит запрос на показ имени; до ответа `author_name_consent=pending` и в ленте стоит только подразделение. Администратору и сотруднику — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [DiscussionCreate] discussionCreate (required):
  Future<Discussion?> publishDiscussion(int appealId, DiscussionCreate discussionCreate, { Future<void>? abortTrigger, }) async {
    final response = await publishDiscussionWithHttpInfo(appealId, discussionCreate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Discussion',) as Discussion;
    
    }
    return null;
  }

  /// Автор решает, показывать ли своё имя
  ///
  /// Только автор обращения. Бот вызывает от имени автора по кнопкам «Показать имя» / «Скрыть».
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [SetNameConsentRequest] setNameConsentRequest (required):
  Future<Response> setNameConsentWithHttpInfo(int discussionId, SetNameConsentRequest setNameConsentRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions/{discussion_id}/name-consent'
      .replaceAll('{discussion_id}', discussionId.toString());

    // ignore: prefer_final_locals
    Object? postBody = setNameConsentRequest;

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

  /// Автор решает, показывать ли своё имя
  ///
  /// Только автор обращения. Бот вызывает от имени автора по кнопкам «Показать имя» / «Скрыть».
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [SetNameConsentRequest] setNameConsentRequest (required):
  Future<Discussion?> setNameConsent(int discussionId, SetNameConsentRequest setNameConsentRequest, { Future<void>? abortTrigger, }) async {
    final response = await setNameConsentWithHttpInfo(discussionId, setNameConsentRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Discussion',) as Discussion;
    
    }
    return null;
  }

  /// Отозвать голос
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  Future<Response> unvoteWithHttpInfo(int discussionId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions/{discussion_id}/vote'
      .replaceAll('{discussion_id}', discussionId.toString());

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

  /// Отозвать голос
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  Future<Discussion?> unvote(int discussionId, { Future<void>? abortTrigger, }) async {
    final response = await unvoteWithHttpInfo(discussionId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Discussion',) as Discussion;
    
    }
    return null;
  }

  /// Проголосовать или изменить голос
  ///
  /// Один голос на пользователя, менять можно до срока. После срока или закрытия — `409 voting_closed`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [VoteRequest] voteRequest (required):
  Future<Response> voteWithHttpInfo(int discussionId, VoteRequest voteRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/discussions/{discussion_id}/vote'
      .replaceAll('{discussion_id}', discussionId.toString());

    // ignore: prefer_final_locals
    Object? postBody = voteRequest;

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

  /// Проголосовать или изменить голос
  ///
  /// Один голос на пользователя, менять можно до срока. После срока или закрытия — `409 voting_closed`.
  ///
  /// Parameters:
  ///
  /// * [int] discussionId (required):
  ///
  /// * [VoteRequest] voteRequest (required):
  Future<Discussion?> vote(int discussionId, VoteRequest voteRequest, { Future<void>? abortTrigger, }) async {
    final response = await voteWithHttpInfo(discussionId, voteRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Discussion',) as Discussion;
    
    }
    return null;
  }
}
