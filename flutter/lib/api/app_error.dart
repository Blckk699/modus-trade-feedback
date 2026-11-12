import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' show ClientException;
import 'package:modus_api/api.dart';

/// Ошибка API в формате контракта: `{"error": {"code", "message", "details"}}`.
/// `message` показываем пользователю как есть, ветвимся только по `code`.
class AppError implements Exception {
  const AppError({required this.code, required this.message, this.status, this.fields = const {}, this.details = const {}});

  /// Код из `ErrorCode` контракта или `network`, если сервер недоступен.
  final String code;
  final String message;
  final int? status;

  /// Ошибки полей из `422 validation_error`: `details.fields[{field, message}]`, ключ без `body.`.
  final Map<String, String> fields;

  /// `details` ошибки как есть: например, `reason` у отклонённой заявки, `retry_after_seconds` у блокировки.
  final Map<String, dynamic> details;

  static const network = 'network';

  static const networkError = AppError(
    code: network,
    message: 'Нет связи с сервером. Проверьте интернет и адрес сервера.',
  );

  bool get isUnauthorized => status == 401;

  factory AppError.from(Object error) {
    if (error is AppError) return error;
    if (error is ClientException || error is SocketException || error is TimeoutException) {
      return networkError;
    }
    if (error is ApiException) {
      if (error.innerException != null) return networkError;
      final parsed = _parseBody(error.message);
      if (parsed != null) {
        return AppError(code: parsed.$1, message: parsed.$2, status: error.code, fields: parsed.$3, details: parsed.$4);
      }
      return AppError(
        code: 'internal_error',
        message: 'Сервер ответил ошибкой ${error.code}. Попробуйте ещё раз.',
        status: error.code,
      );
    }
    return const AppError(
      code: 'internal_error',
      message: 'Что-то пошло не так. Попробуйте ещё раз.',
    );
  }

  static (String, String, Map<String, String>, Map<String, dynamic>)? _parseBody(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      final error = json is Map ? json['error'] : null;
      if (error is Map && error['code'] is String && error['message'] is String) {
        final fields = <String, String>{};
        final details = error['details'];
        final list = details is Map ? details['fields'] : null;
        if (list is List) {
          for (final f in list) {
            if (f is Map && f['field'] is String && f['message'] is String) {
              fields[(f['field'] as String).replaceFirst(RegExp(r'^body\.'), '')] = f['message'] as String;
            }
          }
        }
        return (
          error['code'] as String,
          error['message'] as String,
          fields,
          details is Map ? details.cast<String, dynamic>() : const <String, dynamic>{},
        );
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  String toString() => 'AppError($code, $status): $message';
}
