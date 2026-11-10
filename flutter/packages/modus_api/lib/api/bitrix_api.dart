//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class BitrixApi {
  BitrixApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Создать задачу в Битрикс24
  ///
  /// Ответственный, руководитель, собственник. Повторный вызов не создаёт вторую задачу и возвращает существующую с кодом 200. При ошибке портала — `502 bitrix_unavailable`, обращение не меняется. Администратору и сотруднику — `403`. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<Response> createBitrixTaskWithHttpInfo(int appealId, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/appeals/{appeal_id}/bitrix-task'
      .replaceAll('{appeal_id}', appealId.toString());

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

  /// Создать задачу в Битрикс24
  ///
  /// Ответственный, руководитель, собственник. Повторный вызов не создаёт вторую задачу и возвращает существующую с кодом 200. При ошибке портала — `502 bitrix_unavailable`, обращение не меняется. Администратору и сотруднику — `403`. 
  ///
  /// Parameters:
  ///
  /// * [int] appealId (required):
  Future<BitrixTask?> createBitrixTask(int appealId, { Future<void>? abortTrigger, }) async {
    final response = await createBitrixTaskWithHttpInfo(appealId, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'BitrixTask',) as BitrixTask;
    
    }
    return null;
  }
}
