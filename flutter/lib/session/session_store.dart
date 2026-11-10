import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Где приложение хранит адрес сервера и токен между запусками.
abstract class SessionStore {
  Future<String?> readServerUrl();
  Future<void> writeServerUrl(String url);
  Future<String?> readToken();
  Future<void> writeToken(String? token);
}

/// Токен — в Keychain / Keystore, адрес сервера — в обычных настройках.
class DeviceSessionStore implements SessionStore {
  static const _tokenKey = 'access_token';
  static const _serverKey = 'server_url';

  final _secure = const FlutterSecureStorage();

  @override
  Future<String?> readServerUrl() async =>
      (await SharedPreferences.getInstance()).getString(_serverKey);

  @override
  Future<void> writeServerUrl(String url) async =>
      (await SharedPreferences.getInstance()).setString(_serverKey, url);

  @override
  Future<String?> readToken() => _secure.read(key: _tokenKey);

  @override
  Future<void> writeToken(String? token) => token == null
      ? _secure.delete(key: _tokenKey)
      : _secure.write(key: _tokenKey, value: token);
}

/// Для тестов.
class MemorySessionStore implements SessionStore {
  MemorySessionStore({this.serverUrl, this.token});

  String? serverUrl;
  String? token;

  @override
  Future<String?> readServerUrl() async => serverUrl;
  @override
  Future<void> writeServerUrl(String url) async => serverUrl = url;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> writeToken(String? token) async => this.token = token;
}
