import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' show ClientException;
import 'package:modus_api/api.dart';

/// Ошибка API в формате контракта: `{"error": {"code", "message", "details"}}`.
/// `message` показываем пользователю как есть, ветвимся только по `code`.
class AppError implements Exception {
  const AppError({required this.code, required this.message, this.status});

  /// Код из `ErrorCode` контракта или `network`, если сервер недоступен.
  final String code;
  final String message;
  final int? status;

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
        return AppError(code: parsed.$1, message: parsed.$2, status: error.code);
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

  static (String, String)? _parseBody(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final json = jsonDecode(body);
      final error = json is Map ? json['error'] : null;
      if (error is Map && error['code'] is String && error['message'] is String) {
        return (error['code'] as String, error['message'] as String);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  String toString() => 'AppError($code, $status): $message';
}
