import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../theme/modus_theme.dart';
import 'auth_forms.dart';
import 'register_screen.dart';
import 'server_settings_screen.dart';

enum _Method { email, code }

/// Вход: почта и пароль основным способом, код из бота — вторым; на моке и локально — ещё dev-вход.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _newPassword = TextEditingController();
  final _repeat = TextEditingController();
  final _code = TextEditingController();
  _Method _method = _Method.email;
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};
  LoginProblem? _problem;

  /// Вход с временным паролем: показываем шаг «Новый пароль».
  bool _needNewPassword = false;
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
    for (final c in [_email, _password, _newPassword, _repeat, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _codeComplete => RegExp(r'^\d{6}$').hasMatch(_code.text);

  void _clearErrors() => setState(() {
        _error = null;
        _fieldErrors = const {};
        _problem = null;
      });

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _problem = null;
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

  Future<void> _submitEmail() async {
    if (_busy) return;
    final errors = loginFormErrors(_email.text, _password.text);
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _problem = null;
      _fieldErrors = const {};
    });
    try {
      await SessionScope.read(context).loginWithEmail(_email.text, _password.text);
    } on AppError catch (e) {
      final p = loginProblem(e);
      if (mounted) {
        setState(() {
          if (p.kind == LoginProblemKind.newPassword) {
            _needNewPassword = true;
          } else {
            _problem = p;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitNewPassword() async {
    if (_busy) return;
    final errors = newPasswordErrors(_newPassword.text, _repeat.text, _password.text);
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      await SessionScope.read(context).loginWithEmail(_email.text, _password.text, newPassword: _newPassword.text);
    } on AppError catch (e) {
      final p = loginProblem(e);
      if (mounted) {
        setState(() => _error = p.kind == LoginProblemKind.other
            ? p.message
            : 'Временный пароль больше не действует. Вернитесь ко входу и попробуйте снова.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            const SizedBox(height: 28),
            if (_needNewPassword)
              ..._newPasswordStep(theme)
            else ...[
              SegmentedButton<_Method>(
                key: const Key('login-method'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Method.email, label: Text('Почта и пароль'), icon: Icon(Icons.mail_outline)),
                  ButtonSegment(value: _Method.code, label: Text('Код из Telegram'), icon: Icon(Icons.send_outlined)),
                ],
                selected: {_method},
                onSelectionChanged: _busy
                    ? null
                    : (v) {
                        _clearErrors();
                        setState(() => _method = v.first);
                      },
              ),
              const SizedBox(height: 20),
              if (_method == _Method.email) ..._emailForm(theme) else ..._codeForm(theme),
            ],
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

  List<Widget> _emailForm(ThemeData theme) => [
        if (_problem != null && _problem!.kind != LoginProblemKind.invalid) ...[
          ProblemNotice(problem: _problem!),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('login-email'),
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          autocorrect: false,
          decoration: InputDecoration(labelText: 'Рабочая почта', errorText: _fieldErrors['email']),
          onChanged: (_) => _clearErrors(),
        ),
        const SizedBox(height: 12),
        PasswordField(
          key: const Key('login-password'),
          controller: _password,
          label: 'Пароль',
          enabled: !_busy,
          autofillHints: const [AutofillHints.password],
          error: _fieldErrors['password'] ??
              (_problem?.kind == LoginProblemKind.invalid ? 'Неверная почта или пароль.' : null),
          onChanged: (_) => _clearErrors(),
          onSubmitted: (_) => _submitEmail(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('login-email-submit'),
          onPressed: _busy ? null : _submitEmail,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Войти'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('open-register'),
          onPressed: _busy
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
          child: const Text('Нет доступа? Зарегистрироваться'),
        ),
        Text(
          'Забыли пароль — его сбросит администратор.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ];

  List<Widget> _codeForm(ThemeData theme) => [
        const _Step(n: 1, text: 'Откройте бот компании в Telegram.'),
        const _Step(n: 2, text: 'Нажмите в меню бота «Код входа» или отправьте команду /code.'),
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
          decoration: InputDecoration(labelText: 'Код', hintText: '000000', errorText: _error, errorMaxLines: 3),
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
          'Войти кодом могут сотрудники, которых завёл администратор или чья заявка одобрена.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ];

  List<Widget> _newPasswordStep(ThemeData theme) => [
        Text('Новый пароль', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Вы вошли с временным паролем. Задайте свой для ${_email.text.trim()}.'),
        const SizedBox(height: 16),
        PasswordField(
          key: const Key('new-password'),
          controller: _newPassword,
          label: 'Новый пароль',
          hint: 'Не короче $minPassword символов.',
          enabled: !_busy,
          autofillHints: const [AutofillHints.newPassword],
          error: _fieldErrors['next'],
          onChanged: (_) => _clearErrors(),
        ),
        const SizedBox(height: 12),
        PasswordField(
          key: const Key('new-password-repeat'),
          controller: _repeat,
          label: 'Ещё раз',
          enabled: !_busy,
          autofillHints: const [AutofillHints.newPassword],
          error: _fieldErrors['repeat'],
          onChanged: (_) => _clearErrors(),
          onSubmitted: (_) => _submitNewPassword(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, key: const Key('new-password-error'), style: TextStyle(color: ModusColors.of(context).danger)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('new-password-submit'),
          onPressed: _busy ? null : _submitNewPassword,
          child: Text(_busy ? 'Сохраняем…' : 'Сохранить и войти'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _needNewPassword = false;
                    _newPassword.clear();
                    _repeat.clear();
                    _password.clear();
                    _error = null;
                  }),
          child: const Text('Вернуться ко входу'),
        ),
      ];
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
