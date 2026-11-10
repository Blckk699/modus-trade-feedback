import 'package:flutter/material.dart';

import '../../app.dart';
import '../../config/server_config.dart';

/// Выбор сервера: мок на компьютере разработчика, адрес из сборки или свой.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

enum _Choice { mock, build, custom }

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late _Choice _choice;
  late final TextEditingController _custom;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = SessionScope.read(context).serverUrl;
    _choice = current == ServerConfig.mockUrl
        ? _Choice.mock
        : (ServerConfig.buildUrl.isNotEmpty && current == ServerConfig.buildUrl)
            ? _Choice.build
            : _Choice.custom;
    _custom = TextEditingController(text: _choice == _Choice.custom ? current : 'https://');
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? url = switch (_choice) {
      _Choice.mock => ServerConfig.mockUrl,
      _Choice.build => ServerConfig.buildUrl,
      _Choice.custom => ServerConfig.normalize(_custom.text),
    };
    if (url == null) {
      setState(() => _error = 'Адрес должен начинаться с http:// или https://');
      return;
    }
    final session = SessionScope.read(context);
    final navigator = Navigator.of(context);
    if (url != session.serverUrl) await session.changeServer(url);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сервер')),
      body: SafeArea(
        child: RadioGroup<_Choice>(
          groupValue: _choice,
          onChanged: (value) => setState(() {
            _choice = value!;
            _error = null;
          }),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              RadioListTile<_Choice>(
                value: _Choice.mock,
                title: const Text('Мок-сервер'),
                subtitle: Text('${ServerConfig.mockUrl} · примеры из контракта, без сохранения'),
              ),
              if (ServerConfig.buildUrl.isNotEmpty)
                RadioListTile<_Choice>(
                  value: _Choice.build,
                  title: const Text('Сервер из сборки'),
                  subtitle: const Text(ServerConfig.buildUrl),
                ),
              const RadioListTile<_Choice>(
                value: _Choice.custom,
                title: Text('Другой адрес'),
              ),
              if (_choice == _Choice.custom)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 24, 8),
                  child: TextField(
                    controller: _custom,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'https://example.kz',
                      helperText: 'Хост без /api/v1',
                      errorText: _error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(onPressed: _save, child: const Text('Сохранить')),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('При смене сервера текущая сессия закрывается.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
