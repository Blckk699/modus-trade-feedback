import 'package:http/http.dart' as http;
import 'package:modus_api/api.dart';

/// Точка доступа к сгенерированному клиенту API (`packages/modus_api`).
///
/// Хранит адрес сервера и токен сессии; экраны берут нужный `*Api` отсюда.
class ApiService {
  ApiService({required String baseUrl, this.httpClient}) {
    _client = _buildClient(baseUrl);
  }

  /// Подменяется в тестах.
  final http.Client? httpClient;
  final HttpBearerAuth _auth = HttpBearerAuth();
  late ApiClient _client;

  String get baseUrl => _client.basePath;

  set baseUrl(String value) {
    if (value != _client.basePath) _client = _buildClient(value);
  }

  set token(String? value) {
    // Пустая строка — заголовок Authorization не отправляется.
    _auth.accessToken = value ?? '';
  }

  ApiClient _buildClient(String baseUrl) {
    final client = ApiClient(basePath: baseUrl, authentication: _auth);
    if (httpClient != null) client.client = httpClient!;
    return client;
  }

  AuthApi get auth => AuthApi(_client);
  MeApi get me => MeApi(_client);
  DictionariesApi get dictionaries => DictionariesApi(_client);
  AppealsApi get appeals => AppealsApi(_client);
  AppealActionsApi get appealActions => AppealActionsApi(_client);
  MessagesApi get messages => MessagesApi(_client);
  AttachmentsApi get attachments => AttachmentsApi(_client);
  DuplicatesApi get duplicates => DuplicatesApi(_client);
  BitrixApi get bitrix => BitrixApi(_client);
  DiscussionsApi get discussions => DiscussionsApi(_client);
  FeedApi get feed => FeedApi(_client);
  MeetingsApi get meetings => MeetingsApi(_client);
  AnalyticsApi get analytics => AnalyticsApi(_client);
  NotificationsApi get notifications => NotificationsApi(_client);
  AdminApi get admin => AdminApi(_client);
}
