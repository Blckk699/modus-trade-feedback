import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modus_api/api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../theme/modus_theme.dart';
import '../web/web_ui.dart';
import 'auth_forms.dart';
import 'register_screen.dart';

/// Бот компании: заявка на доступ и коды входа. Задаётся при сборке: --dart-define=BOT_USERNAME=...
const botUsername = String.fromEnvironment('BOT_USERNAME', defaultValue: 'modus_fb_bot');

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
    // Раскладка экрана входа веба на телефоне (.auth, max-width 760): поля 8, плитка бренда,
    // под ней карточка с отступами 22 / 8 и промежутком 16 между блоками.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
          children: [
            BrandTile(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                  child: const BrandLogo(ink: Color(0xFF082742), surface: Colors.white),
                ),
                const SizedBox(height: 22),
                // max-width 14em и text-wrap: balance — три ровные строки, как в вебе.
                const Text(
                  'Скажите, что мешает\nработать. Ответ\nпридёт в срок.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    height: 1.08,
                    letterSpacing: -1,
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 22, 8, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(a),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_needNewPassword ? 'new' : _method.name),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _gap16(_needNewPassword
                      ? _newPasswordStep(theme)
                      : _method == _Method.email
                          ? _emailForm(theme)
                          : _codeForm(theme)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FutureBuilder<List<UserBrief>?>(
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
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _gap16(List<Widget> items) => [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(height: 16), items[i]],
      ];

  Widget _title(String title, String? lead) {
    final c = ModusColors.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, height: 1.1, letterSpacing: -1.2, color: c.heading)),
      if (lead != null) ...[
        const SizedBox(height: 16),
        Text(lead, style: TextStyle(color: c.muted, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
      ],
    ]);
  }

  Widget _muted(String text, {double size = 13.5}) =>
      Text(text, style: TextStyle(color: ModusColors.of(context).muted, fontSize: size, height: 1.45));

  /// «Ещё нет доступа? Зарегистрироваться» — `.auth__switch`.
  Widget _registerLink() {
    final c = ModusColors.of(context);
    return GestureDetector(
      key: const Key('open-register'),
      onTap: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: 'Ещё нет доступа? ', style: TextStyle(color: c.muted)),
        TextSpan(text: 'Зарегистрироваться', style: TextStyle(color: c.palette.link, fontWeight: FontWeight.w600)),
      ]), style: const TextStyle(fontSize: 14, height: 1.5)),
    );
  }

  List<Widget> _emailForm(ThemeData theme) => [
        _title('Вход', 'Обращения и предложения сотрудников Модус Трейд.'),
        if (_problem != null && _problem!.kind != LoginProblemKind.invalid) ProblemNotice(problem: _problem!),
        WebInput(
          key: const Key('login-email'),
          label: 'Рабочая почта',
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          autocorrect: false,
          error: _fieldErrors['email'],
          onChanged: (_) => _clearErrors(),
        ),
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
        WebButton(
          key: const Key('login-email-submit'),
          label: _busy ? 'Входим…' : 'Войти',
          busy: _busy,
          onPressed: _submitEmail,
        ),
        _muted('Забыли пароль? Его сбросит администратор.'),
        const OrDivider(),
        WebButton(
          key: const Key('login-code-mode'),
          kind: WebButtonKind.soft,
          icon: const Icon(LucideIcons.send),
          label: 'Войти кодом из Telegram',
          onPressed: _busy
              ? null
              : () {
                  _clearErrors();
                  setState(() => _method = _Method.code);
                },
        ),
        _registerLink(),
      ];

  List<Widget> _codeForm(ThemeData theme) => [
        _title('Код из Telegram', 'Откройте бот компании, нажмите «Код входа» или отправьте /code и введите шесть цифр. Код действует несколько минут.'),
        WebInput(
          key: const Key('login-code'),
          label: 'Код',
          controller: _code,
          enabled: !_busy,
          hint: '000000',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          style: TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w600, color: ModusColors.of(context).heading),
          error: _error,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _submitCode(),
        ),
        WebButton(
          key: const Key('login-submit'),
          label: 'Войти',
          busy: _busy,
          onPressed: _codeComplete ? _submitCode : null,
        ),
        WebButton(
          key: const Key('open-bot'),
          kind: WebButtonKind.soft,
          icon: const Icon(LucideIcons.send),
          label: 'Открыть бот',
          onPressed: () => launchUrl(Uri.parse('https://t.me/$botUsername'), mode: LaunchMode.externalApplication),
        ),
        _muted('Войти кодом могут сотрудники, которых завёл администратор или чья заявка одобрена. Нет доступа? Подайте заявку в боте.'),
        Center(
          child: TextButton.icon(
            key: const Key('login-email-mode'),
            onPressed: _busy ? null : () => setState(() => _method = _Method.email),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Войти по почте'),
          ),
        ),
      ];

  List<Widget> _newPasswordStep(ThemeData theme) => [
        _title('Новый пароль', 'Вы вошли с временным паролем. Задайте свой для ${_email.text.trim()}.'),
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
        if (_error != null)
          Text(_error!, key: const Key('new-password-error'), style: TextStyle(color: ModusColors.of(context).danger)),
        WebButton(
          key: const Key('new-password-submit'),
          label: _busy ? 'Сохраняем…' : 'Сохранить и войти',
          busy: _busy,
          onPressed: _submitNewPassword,
        ),
        Center(
          child: TextButton(
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
        ),
      ];
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
