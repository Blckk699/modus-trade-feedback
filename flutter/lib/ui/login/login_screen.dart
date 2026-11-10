import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import 'server_settings_screen.dart';

/// Вход по одноразовому коду из бота; на моке и локально — ещё dev-вход.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  late Future<List<UserBrief>?> _devUsers;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    // Перезапрашиваем список dev-входа при смене сервера.
    if (_loadedFor != session.serverUrl) {
      _loadedFor = session.serverUrl;
      _devUsers = session.devUsers();
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _codeComplete => RegExp(r'^\d{6}$').hasMatch(_code.text);

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AppError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submitCode() {
    if (!_codeComplete || _busy) return;
    _run(() => SessionScope.read(context).loginWithCode(_code.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text('Модус Трейд', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Обращения и предложения сотрудников',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Text('Вход по коду из бота', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            const _Step(n: 1, text: 'Откройте бот компании в Telegram.'),
            const _Step(n: 2, text: 'Нажмите в меню бота «Код входа».'),
            const _Step(n: 3, text: 'Введите шесть цифр из сообщения. Код действует несколько минут и подходит один раз.'),
            const SizedBox(height: 16),
            TextField(
              key: const Key('login-code'),
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Код',
                hintText: '000000',
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 3,
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submitCode(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('login-submit'),
              onPressed: _codeComplete && !_busy ? _submitCode : null,
              child: _busy
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Войти'),
            ),
            const SizedBox(height: 8),
            Text(
              'Войти могут только сотрудники, которых завёл администратор.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            FutureBuilder<List<UserBrief>?>(
              future: _devUsers,
              builder: (context, snapshot) {
                final users = snapshot.data;
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return _Hint(
                    text: error is AppError ? error.message : 'Сервер не ответил.',
                    icon: Icons.cloud_off,
                  );
                }
                if (users == null || users.isEmpty) return const SizedBox.shrink();
                return _DevLogin(
                  users: users,
                  enabled: !_busy,
                  onPick: (user) => _run(() => SessionScope.read(context).devLogin(user.id)),
                );
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns_outlined),
              title: const Text('Сервер'),
              subtitle: Text(session.serverUrl),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen()),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text('$n', style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: theme.colorScheme.error))),
        ],
      ),
    );
  }
}

/// Показывается, только если сервер отдаёт `GET /auth/dev/users` (на демо-сервере выключен).
class _DevLogin extends StatelessWidget {
  const _DevLogin({required this.users, required this.enabled, required this.onPick});

  final List<UserBrief> users;
  final bool enabled;
  final ValueChanged<UserBrief> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = SessionScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Card.outlined(
        child: ExpansionTile(
          key: const Key('dev-login'),
          shape: const Border(),
          leading: const Icon(Icons.developer_mode),
          title: const Text('Dev-вход'),
          subtitle: const Text('Только для разработки: войти под выбранным пользователем'),
          children: [
            for (final user in users)
              ListTile(
                key: Key('dev-user-${user.id}'),
                enabled: enabled,
                title: Text(user.fullName),
                subtitle: Text([
                  session.roleLabel(user.role),
                  if (user.department != null) user.department!.name,
                ].join(' · ')),
                trailing: Icon(Icons.login, color: theme.colorScheme.primary),
                onTap: () => onPick(user),
              ),
          ],
        ),
      ),
    );
  }
}
