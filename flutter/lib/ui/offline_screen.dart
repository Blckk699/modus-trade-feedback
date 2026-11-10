import 'package:flutter/material.dart';

import '../app.dart';

/// Сессия сохранена, но сервер не ответил при запуске.
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await SessionScope.read(context).refreshMe();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('Сервер недоступен', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  session.offlineError?.message ?? '',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(session.serverUrl, style: theme.textTheme.bodySmall),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _retry,
                  child: const Text('Повторить'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => SessionScope.read(context).logout(),
                  child: const Text('Выйти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
