//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DraftsApi {
  DraftsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Черновик обращения из текста или пересланного сообщения
  ///
  /// Claude предлагает тип, категорию из справочника, приоритет, краткую суть и предлагаемое решение. Черновик ничего не создаёт и не хранится: автор правит поля и отправляет `POST /appeals` с `source=bot`. Если AI-сервис недоступен — `503 ai_unavailable`, форма продолжает работать. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TextDraftRequest] textDraftRequest (required):
  Future<Response> draftFromTextWithHttpInfo(TextDraftRequest textDraftRequest, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/drafts/text';

    // ignore: prefer_final_locals
    Object? postBody = textDraftRequest;

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

  /// Черновик обращения из текста или пересланного сообщения
  ///
  /// Claude предлагает тип, категорию из справочника, приоритет, краткую суть и предлагаемое решение. Черновик ничего не создаёт и не хранится: автор правит поля и отправляет `POST /appeals` с `source=bot`. Если AI-сервис недоступен — `503 ai_unavailable`, форма продолжает работать. 
  ///
  /// Parameters:
  ///
  /// * [TextDraftRequest] textDraftRequest (required):
  Future<AppealDraft?> draftFromText(TextDraftRequest textDraftRequest, { Future<void>? abortTrigger, }) async {
    final response = await draftFromTextWithHttpInfo(textDraftRequest, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AppealDraft',) as AppealDraft;
    
    }
    return null;
  }

  /// Черновик обращения из голосового сообщения
  ///
  /// ElevenLabs Scribe расшифровывает аудио, затем Claude делает черновик. Расшифровка возвращается в `transcript` и в `text` черновика. Пустое аудио — `422 audio_empty`, длиннее 5 минут — `422 audio_too_long`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   ogg/opus из Telegram, mp3, m4a, wav
  ///
  /// * [int] durationSeconds:
  ///   Длительность в секундах, если клиент её знает (Telegram `voice.duration`); больше 300 — `422 audio_too_long`
  Future<Response> draftFromVoiceWithHttpInfo(MultipartFile file, { int? durationSeconds, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/drafts/voice';

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
    if (durationSeconds != null) {
      hasFields = true;
      mp.fields[r'duration_seconds'] = parameterToString(durationSeconds);
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

  /// Черновик обращения из голосового сообщения
  ///
  /// ElevenLabs Scribe расшифровывает аудио, затем Claude делает черновик. Расшифровка возвращается в `transcript` и в `text` черновика. Пустое аудио — `422 audio_empty`, длиннее 5 минут — `422 audio_too_long`. 
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   ogg/opus из Telegram, mp3, m4a, wav
  ///
  /// * [int] durationSeconds:
  ///   Длительность в секундах, если клиент её знает (Telegram `voice.duration`); больше 300 — `422 audio_too_long`
  Future<AppealDraft?> draftFromVoice(MultipartFile file, { int? durationSeconds, Future<void>? abortTrigger, }) async {
    final response = await draftFromVoiceWithHttpInfo(file, durationSeconds: durationSeconds, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AppealDraft',) as AppealDraft;
    
    }
    return null;
  }
}
