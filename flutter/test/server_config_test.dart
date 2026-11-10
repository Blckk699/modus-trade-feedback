import 'package:flutter_test/flutter_test.dart';
import 'package:modus_feedback/config/server_config.dart';

void main() {
  test('адрес сервера нормализуется до хоста без /api/v1', () {
    expect(ServerConfig.normalize(' https://modus.example.kz/api/v1/ '), 'https://modus.example.kz');
    expect(ServerConfig.normalize('http://192.168.1.5:4010'), 'http://192.168.1.5:4010');
    expect(ServerConfig.normalize('modus.example.kz'), isNull);
    expect(ServerConfig.normalize('ftp://x'), isNull);
  });
}
