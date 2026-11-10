import 'package:flutter/material.dart';

import 'api/api_service.dart';
import 'app.dart';
import 'config/server_config.dart';
import 'session/session_controller.dart';
import 'session/session_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionController(
    api: ApiService(baseUrl: ServerConfig.defaultUrl),
    store: DeviceSessionStore(),
  )..restore();
  runApp(ModusApp(session: session));
}
