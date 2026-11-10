import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'api/api_service.dart';
import 'app.dart';
import 'config/server_config.dart';
import 'session/session_controller.dart';
import 'session/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final session = SessionController(
    api: ApiService(baseUrl: ServerConfig.defaultUrl),
    store: DeviceSessionStore(),
  )..restore();
  runApp(ModusApp(session: session));
}
