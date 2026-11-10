//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MeetingsApi {
  MeetingsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Подтвердить черновик — создать обращение
  ///
  /// Обращение создаётся с `source=meeting` и идёт по обычной маршрутизации. Автор — `author_id` черновика, если указан, иначе загрузивший. Тело необязательно: можно сразу передать последние правки. Только загрузивший, остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  ///
  /// * [int] draftId (required):
  ///
  /// * [MeetingDraftUpdate] meetingDraftUpdate:
  Future<Response> confirmMeetingDraftWithHttpInfo(int meetingId, int draftId, { MeetingDraftUpdate? meetingDraftUpdate, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/meetings/{meeting_id}/drafts/{draft_id}/confirm'
      .replaceAll('{meeting_id}', meetingId.toString())
      .replaceAll('{draft_id}', draftId.toString());

    // ignore: prefer_final_locals
    Object? postBody = meetingDraftUpdate;

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

  /// Подтвердить черновик — создать обращение
  ///
  /// Обращение создаётся с `source=meeting` и идёт по обычной маршрутизации. Автор — `author_id` черновика, если указан, иначе загрузивший. Тело необязательно: можно сразу передать последние правки. Только загрузивший, остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  ///
  /// * [int] draftId (required):
  ///
  /// * [MeetingDraftUpdate] meetingDraftUpdate:
  Future<Appeal?> confirmMeetingDraft(int meetingId, int draftId, { MeetingDraftUpdate? meetingDraftUpdate, Future<void>? abortTrigger, }) async {
    final response = await confirmMeetingDraftWithHttpInfo(meetingId, draftId, meetingDraftUpdate: meetingDraftUpdate, abortTrigger: abortTrigger,);
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

  /// Отбросить черновик
  ///
  /// Только загрузивший, остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  ///
  /// * [int] draftId (required):
  Future<Response> discardMeetingDraftWithHttpInfo(int meetingId, int draftId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/meetings/{meeting_id}/drafts/{draft_id}/discard'
      .replaceAll('{meeting_id}', meetingId.toString())
      .replaceAll('{draft_id}', draftId.toString());

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

  /// Отбросить черновик
  ///
  /// Только загрузивший, остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  ///
  /// * [int] draftId (required):
  Future<MeetingDraft?> discardMeetingDraft(int meetingId, int draftId, { Future<void>? abortTrigger, }) async {
    final response = await discardMeetingDraftWithHttpInfo(meetingId, draftId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MeetingDraft',) as MeetingDraft;
    
    }
    return null;
  }

  /// Совещание: состояние, расшифровка, черновики
  ///
  /// Только загрузивший (руководитель или собственник), остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  Future<Response> getMeetingWithHttpInfo(int meetingId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/meetings/{meeting_id}'
      .replaceAll('{meeting_id}', meetingId.toString());

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

  /// Совещание: состояние, расшифровка, черновики
  ///
  /// Только загрузивший (руководитель или собственник), остальным — `403`.
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  Future<Meeting?> getMeeting(int meetingId, { Future<void>? abortTrigger, }) async {
    final response = await getMeetingWithHttpInfo(meetingId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Meeting',) as Meeting;
    
    }
    return null;
  }

  /// Совещания, загруженные пользователем
  ///
  /// Руководитель и собственник видят загруженные ими записи. Остальным — `403`.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listMeetingsWithHttpInfo({ Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/meetings';

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

  /// Совещания, загруженные пользователем
  ///
  /// Руководитель и собственник видят загруженные ими записи. Остальным — `403`.
  Future<List<MeetingBrief>?> listMeetings({ Future<void>? abortTrigger, }) async {
    final response = await listMeetingsWithHttpInfo(abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<MeetingBrief>') as List)
        .cast<MeetingBrief>()
        .toList(growable: false);

    }
    return null;
  }

  /// Поправить черновик
  ///
  /// Только загрузивший и только черновик в статусе `pending`. Остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  ///
  /// * [int] draftId (required):
  ///
  /// * [MeetingDraftUpdate] meetingDraftUpdate (required):
  Future<Response> updateMeetingDraftWithHttpInfo(int meetingId, int draftId, MeetingDraftUpdate meetingDraftUpdate, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/meetings/{meeting_id}/drafts/{draft_id}'
      .replaceAll('{meeting_id}', meetingId.toString())
      .replaceAll('{draft_id}', draftId.toString());

    // ignore: prefer_final_locals
    Object? postBody = meetingDraftUpdate;

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

  /// Поправить черновик
  ///
  /// Только загрузивший и только черновик в статусе `pending`. Остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] meetingId (required):
  ///
  /// * [int] draftId (required):
  ///
  /// * [MeetingDraftUpdate] meetingDraftUpdate (required):
  Future<MeetingDraft?> updateMeetingDraft(int meetingId, int draftId, MeetingDraftUpdate meetingDraftUpdate, { Future<void>? abortTrigger, }) async {
    final response = await updateMeetingDraftWithHttpInfo(meetingId, draftId, meetingDraftUpdate, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MeetingDraft',) as MeetingDraft;
    
    }
    return null;
  }

  /// Загрузить аудиозапись совещания
  ///
  /// Обработка идёт в фоне: ответ сразу со `status=processing`. Клиент опрашивает `GET /meetings/{id}` раз в несколько секунд, пока статус не станет `ready` или `failed`. До 200 МБ. Только руководитель и собственник, остальным — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   mp3, m4a, wav, ogg, webm
  ///
  /// * [String] title:
  Future<Response> uploadMeetingWithHttpInfo(MultipartFile file, { String? title, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/meetings';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (file != null) {
      hasFields = true;
      mp.fields[r'file'] = file.field;
      mp.files.add(file);
    }
    if (title != null) {
      hasFields = true;
      mp.fields[r'title'] = parameterToString(title);
    }
    if (hasFields) {
      postBody = mp;
    }

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

  /// Загрузить аудиозапись совещания
  ///
  /// Обработка идёт в фоне: ответ сразу со `status=processing`. Клиент опрашивает `GET /meetings/{id}` раз в несколько секунд, пока статус не станет `ready` или `failed`. До 200 МБ. Только руководитель и собственник, остальным — `403`. 
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   mp3, m4a, wav, ogg, webm
  ///
  /// * [String] title:
  Future<Meeting?> uploadMeeting(MultipartFile file, { String? title, Future<void>? abortTrigger, }) async {
    final response = await uploadMeetingWithHttpInfo(file, title: title, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Meeting',) as Meeting;
    
    }
    return null;
  }
}
