import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../theme/modus_theme.dart';
import 'auth_forms.dart';

/// Регистрация по почте: заявка на доступ, которую одобряет администратор или собственник.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _comment = TextEditingController();
  int? _department;
  Future<List<DepartmentRef>>? _departments;
  bool _busy = false;
  bool _sent = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _departments ??= SessionScope.read(context).accessDepartments();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clear() => setState(() {
        _error = null;
        _fieldErrors = const {};
      });

  Future<void> _submit() async {
    if (_busy) return;
    final errors = registerFormErrors(fullName: _name.text, email: _email.text, password: _password.text);
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = SessionScope.read(context);
    final navigator = Navigator.of(context);
    try {
      final pending = await session.register(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        departmentId: _department,
        comment: _comment.text,
      );
      if (!mounted) return;
      if (pending) {
        setState(() => _sent = true);
      } else {
        navigator.popUntil((r) => r.isFirst);
      }
    } on AppError catch (e) {
      if (mounted) {
        setState(() {
          _fieldErrors = e.fields;
          _error = e.code == 'email_taken' || e.fields.isEmpty ? e.message : null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: _sent ? _done(theme) : _form(theme),
        ),
      ),
    );
  }

  List<Widget> _done(ThemeData theme) {
    final c = ModusColors.of(context);
    return [
      Container(
        key: const Key('register-pending'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.warnBg, borderRadius: BorderRadius.circular(ModusRadius.lg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Заявка на рассмотрении',
              style: theme.textTheme.titleMedium?.copyWith(color: c.warn, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Администратор получил заявку. Войти по почте ${_email.text.trim()} и паролю получится после одобрения.',
            style: TextStyle(color: c.warn),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('register-back'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Ко входу'),
      ),
    ];
  }

  List<Widget> _form(ThemeData theme) => [
        Text(
          'Заявку рассмотрит администратор. После одобрения войдёте по почте и паролю.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('register-name'),
          controller: _name,
          enabled: !_busy,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: InputDecoration(labelText: 'Имя и фамилия', errorText: _fieldErrors['full_name']),
          onChanged: (_) => _clear(),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('register-email'),
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: 'Рабочая почта', errorText: _fieldErrors['email']),
          onChanged: (_) => _clear(),
        ),
        const SizedBox(height: 12),
        PasswordField(
          key: const Key('register-password'),
          controller: _password,
          label: 'Пароль',
          hint: 'Не короче $minPassword символов.',
          enabled: !_busy,
          autofillHints: const [AutofillHints.newPassword],
          error: _fieldErrors['password'],
          onChanged: (_) => _clear(),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<DepartmentRef>>(
          future: _departments,
          builder: (context, s) => DropdownButtonFormField<int?>(
            key: Key('register-department-${s.hasData}'),
            initialValue: s.hasData ? _department : null,
            decoration: InputDecoration(
              labelText: 'Подразделение',
              helperText: s.hasError ? 'Список не загрузился — укажите подразделение в комментарии.' : null,
              errorText: _fieldErrors['department_id'],
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Не знаю')),
              for (final d in s.data ?? const <DepartmentRef>[])
                DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
            ],
            onChanged: _busy ? null : (v) => setState(() => _department = v),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('register-comment'),
          controller: _comment,
          enabled: !_busy,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Комментарий',
            hintText: 'Должность, кто может подтвердить',
            errorText: _fieldErrors['comment'],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, key: const Key('register-error'), style: TextStyle(color: ModusColors.of(context).danger)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('register-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Отправляем…' : 'Отправить заявку'),
        ),
      ];
}
