//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AttachmentsApi {
  AttachmentsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Скачать файл
  ///
  /// Отдаётся только тем, кто видит обращение (участнику склеенного повтора — нет).
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] attachmentId (required):
  Future<Response> downloadAttachmentWithHttpInfo(int attachmentId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/attachments/{attachment_id}'
      .replaceAll('{attachment_id}', attachmentId.toString());

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

  /// Скачать файл
  ///
  /// Отдаётся только тем, кто видит обращение (участнику склеенного повтора — нет).
  ///
  /// Parameters:
  ///
  /// * [int] attachmentId (required):
  Future<MultipartFile?> downloadAttachment(int attachmentId, { Future<void>? abortTrigger, }) async {
    final response = await downloadAttachmentWithHttpInfo(attachmentId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MultipartFile',) as MultipartFile;
    
    }
    return null;
  }

  /// Вложения обращения
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<Response> listAttachmentsWithHttpInfo(int appealId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/attachments'
      .replaceAll('{appeal_id}', appealId.toString());

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

  /// Вложения обращения
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<List<Attachment>?> listAttachments(int appealId, { Future<void>? abortTrigger, }) async {
    final response = await listAttachmentsWithHttpInfo(appealId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Attachment>') as List)
        .cast<Attachment>()
        .toList(growable: false);

    }
    return null;
  }

  /// Приложить файл
  ///
  /// Автор, ответственный, руководитель подразделения обращения и собственник, пока обращение не завершено. Не больше 20 МБ на файл.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [MultipartFile] file (required):
  Future<Response> uploadAttachmentWithHttpInfo(int appealId, MultipartFile file, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/attachments'
      .replaceAll('{appeal_id}', appealId.toString());

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

  /// Приложить файл
  ///
  /// Автор, ответственный, руководитель подразделения обращения и собственник, пока обращение не завершено. Не больше 20 МБ на файл.
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  ///
  /// * [MultipartFile] file (required):
  Future<Attachment?> uploadAttachment(int appealId, MultipartFile file, { Future<void>? abortTrigger, }) async {
    final response = await uploadAttachmentWithHttpInfo(appealId, file, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Attachment',) as Attachment;
    
    }
    return null;
  }
}
