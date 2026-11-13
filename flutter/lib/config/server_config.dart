import 'dart:io' show Platform;

/// Адрес сервера API: хост без `/api/v1`, пути в контракте уже содержат префикс.
///
/// По умолчанию — мок-сервер на компьютере разработчика. Адрес можно задать при сборке
/// (`--dart-define=API_BASE_URL=https://…`); в приложении адрес не выбирается.
class ServerConfig {
  ServerConfig._();

  static const String buildUrl = String.fromEnvironment('API_BASE_URL');

  /// С эмулятора Android компьютер виден как 10.0.2.2, с симулятора iOS — как localhost.
  static String get mockUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:4010' : 'http://localhost:4010';

  static String get defaultUrl => buildUrl.isNotEmpty ? buildUrl : mockUrl;

  /// Приводит введённый адрес к виду `https://host[:port]` без завершающего слэша.
  /// Возвращает null, если адрес не похож на http(s).
  static String? normalize(String input) {
    var value = input.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.endsWith('/api/v1')) {
      value = value.substring(0, value.length - '/api/v1'.length);
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return null;
    }
    return value;
  }
}
