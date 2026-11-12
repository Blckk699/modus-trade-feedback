import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/app_error.dart';
import '../../theme/modus_theme.dart';

/// Пароль — от 8 символов (SPEC, «Пароль»).
const minPassword = 8;

/// Блокировка после пяти неудачных попыток подряд.
const lockMinutes = 5;

enum LoginProblemKind { invalid, pending, rejected, disabled, locked, newPassword, other }

/// Что случилось при входе по почте — в терминах экрана (как `loginProblem` в вебе).
class LoginProblem {
  const LoginProblem(this.kind, {this.message = '', this.reason, this.retryAfterSec});

  final LoginProblemKind kind;
  final String message;
  final String? reason;
  final int? retryAfterSec;
}

LoginProblem loginProblem(AppError e) {
  switch (e.code) {
    case 'invalid_credentials':
      return const LoginProblem(LoginProblemKind.invalid);
    case 'access_request_pending':
      return const LoginProblem(LoginProblemKind.pending);
    case 'access_request_rejected':
      final reason = e.details['reason'];
      return LoginProblem(
        LoginProblemKind.rejected,
        reason: reason is String && reason.trim().isNotEmpty ? reason.trim() : null,
      );
    case 'user_disabled':
      return const LoginProblem(LoginProblemKind.disabled);
    case 'password_change_required':
      return const LoginProblem(LoginProblemKind.newPassword);
    case 'too_many_requests':
      final sec = num.tryParse('${e.details['retry_after_seconds']}');
      return LoginProblem(LoginProblemKind.locked, retryAfterSec: sec != null && sec > 0 ? sec.ceil() : null);
    default:
      // Старый сервер не знает вход по почте и отвечает на незнакомый маршрут 404/405.
      final notDeployed = e.status == 404 || e.status == 405;
      return LoginProblem(
        LoginProblemKind.other,
        message: notDeployed
            ? 'Вход по почте на этом сервере ещё не включён. Войдите кодом из Telegram или попробуйте позже.'
            : e.message,
      );
  }
}

/// «через 4 мин 12 с», «через 40 с»; без точного времени — «через 5 минут».
String lockWait(int? retryAfterSec) {
  if (retryAfterSec == null) return 'через $lockMinutes минут';
  final min = retryAfterSec ~/ 60;
  final sec = retryAfterSec % 60;
  if (min == 0) return 'через $sec с';
  return sec == 0 ? 'через $min мин' : 'через $min мин $sec с';
}

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? emailError(String email) {
  final v = email.trim();
  if (v.isEmpty) return 'Укажите рабочую почту.';
  return _emailRe.hasMatch(v) ? null : 'Проверьте адрес: в нём должны быть @ и домен.';
}

String? passwordError(String password) {
  if (password.isEmpty) return 'Придумайте пароль.';
  return password.length < minPassword ? 'Пароль короче $minPassword символов.' : null;
}

Map<String, String> loginFormErrors(String email, String password) => {
      'email': ?emailError(email),
      if (password.isEmpty) 'password': 'Введите пароль.',
    };

Map<String, String> newPasswordErrors(String next, String repeat, String temporary) => {
      if (passwordError(next) case final e?)
        'next': e
      else if (next == temporary)
        'next': 'Новый пароль должен отличаться от временного.',
      if (repeat != next) 'repeat': 'Пароли не совпадают.',
    };

Map<String, String> registerFormErrors({required String fullName, required String email, required String password}) => {
      if (fullName.trim().isEmpty) 'full_name': 'Укажите имя и фамилию.',
      'email': ?emailError(email),
      'password': ?passwordError(password),
    };

/// Поле пароля с кнопкой «показать».
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.error,
    this.enabled = true,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? error;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: !_visible,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: widget.autofillHints,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.hint,
          errorText: widget.error,
          suffixIcon: IconButton(
            tooltip: _visible ? 'Скрыть пароль' : 'Показать пароль',
            icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      );
}

/// Отказы входа, которые не лечатся правкой полей: что происходит и что делать.
class ProblemNotice extends StatelessWidget {
  const ProblemNotice({super.key, required this.problem});

  final LoginProblem problem;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final (title, text, warn) = switch (problem.kind) {
      LoginProblemKind.pending => (
          'Заявка на рассмотрении',
          'Войти получится после одобрения. Администратор уже получил заявку.',
          true,
        ),
      LoginProblemKind.rejected => (
          'Заявка отклонена',
          problem.reason != null ? 'Причина: ${problem.reason}' : 'Причину можно узнать у администратора.',
          false,
        ),
      LoginProblemKind.disabled => ('Доступ отключён', 'Обратитесь к администратору.', false),
      LoginProblemKind.locked => ('Слишком много попыток', '', true),
      _ => (null, problem.message, false),
    };
    return Container(
      key: Key('login-problem-${problem.kind.name}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? c.warnBg : c.dangerBg,
        borderRadius: BorderRadius.circular(ModusRadius.md),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: warn ? c.warn : c.danger),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (problem.kind == LoginProblemKind.locked)
            _LockCountdown(seconds: problem.retryAfterSec)
          else if (text.isNotEmpty)
            Text(text),
        ]),
      ),
    );
  }
}

/// Блокировка после пяти неудач: отсчитываем оставшееся время.
class _LockCountdown extends StatefulWidget {
  const _LockCountdown({required this.seconds});

  final int? seconds;

  @override
  State<_LockCountdown> createState() => _LockCountdownState();
}

class _LockCountdownState extends State<_LockCountdown> {
  Timer? _timer;
  int? _left;

  @override
  void initState() {
    super.initState();
    _left = widget.seconds;
    if (_left != null) {
      final until = DateTime.now().add(Duration(seconds: _left!));
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        final left = until.difference(DateTime.now()).inSeconds;
        setState(() => _left = left < 0 ? 0 : left);
        if (left <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        _left == 0
            ? 'Можно пробовать снова. Если пароль не вспомнился, его сбросит администратор.'
            : 'Вход по этой почте откроется ${lockWait(_left)}. Если пароль не вспомнился, его сбросит администратор.',
      );
}
