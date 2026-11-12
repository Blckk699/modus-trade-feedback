import 'package:flutter/foundation.dart';
import 'package:modus_api/api.dart';

import '../api/api_service.dart';
import '../api/app_error.dart';
import '../config/server_config.dart';
import 'session_store.dart';

enum SessionStatus {
  /// Читаем сохранённую сессию.
  loading,

  /// Нужно войти.
  signedOut,

  /// Сессия есть, но сервер недоступен — показываем повтор.
  offline,

  signedIn,
}

/// Сессия пользователя: вход по коду и dev-вход, восстановление при запуске, выход.
class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.store});

  final ApiService api;
  final SessionStore store;

  SessionStatus _status = SessionStatus.loading;
  SessionStatus get status => _status;

  Me? _me;

  /// Текущий пользователь; есть только в статусе [SessionStatus.signedIn].
  Me get me => _me!;

  Dictionaries? _dictionaries;

  /// Подписи статусов, ролей и типов. Может быть null, если сервер ещё не ответил.
  Dictionaries? get dictionaries => _dictionaries;

  AppError? _offlineError;
  AppError? get offlineError => _offlineError;

  String get serverUrl => api.baseUrl;

  /// Восстанавливает сессию при запуске приложения.
  Future<void> restore() async {
    api.baseUrl = await store.readServerUrl() ?? ServerConfig.defaultUrl;
    final token = await store.readToken();
    if (token == null || token.isEmpty) {
      _set(SessionStatus.signedOut);
      return;
    }
    // Токен выдан другим сервером (например, сборку переключили с мока на реальный адрес) —
    // он здесь не действует, входим заново. На iOS токен в Keychain переживает переустановку,
    // а настройки — нет: токен без записанного сервера тоже считаем чужим.
    final tokenServer = await store.readTokenServer();
    if (tokenServer != api.baseUrl) {
      await _clear();
      return;
    }
    api.token = token;
    await refreshMe();
  }

  /// Перечитывает `/me`. Истёкший токен — на экран входа, нет сети — экран повтора.
  Future<void> refreshMe() async {
    try {
      final me = await api.me.getMe();
      if (me == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      _me = me;
      _offlineError = null;
      await _loadDictionaries();
      _set(SessionStatus.signedIn);
    } catch (e) {
      final error = AppError.from(e);
      if (error.code == AppError.network || (error.status ?? 0) >= 500) {
        _offlineError = error;
        _set(SessionStatus.offline);
      } else {
        // 401 — токен истёк; 403 — пользователя отключили. В обоих случаях входим заново.
        await _clear();
      }
    }
  }

  /// Вход по одноразовому коду из бота. Бросает [AppError] с текстом для пользователя.
  Future<void> loginWithCode(String code) =>
      _login(() => api.auth.loginWithCode(CodeLoginRequest(code: code)));

  /// Вход по почте и паролю. С [newPassword] — вход с временным паролем и его заменой.
  /// Бросает [AppError]: `invalid_credentials`, `access_request_pending`, `password_change_required` и т. д.
  Future<void> loginWithEmail(String email, String password, {String? newPassword}) => _login(
        () => api.auth.loginByEmail(EmailLogin(email: email.trim(), password: password, newPassword: newPassword)),
      );

  /// Регистрация по почте. true — заявка на рассмотрении; false — вход по приглашению уже выполнен.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    int? departmentId,
    String? comment,
    String? inviteToken,
  }) async {
    final RegisterResult? result;
    try {
      result = await api.auth.registerByEmail(EmailRegister(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
        departmentId: departmentId,
        comment: comment == null || comment.trim().isEmpty ? null : comment.trim(),
        inviteToken: inviteToken,
      ));
    } catch (e) {
      throw AppError.from(e);
    }
    if (result == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
    final session = result.session;
    if (result.status == RegisterResultStatusEnum.registered && session != null) {
      await _login(() async => session);
      return false;
    }
    return true;
  }

  /// Подразделения для формы регистрации (публичный список).
  Future<List<DepartmentRef>> accessDepartments() async {
    try {
      return await api.access.listAccessDepartments() ?? const [];
    } catch (e) {
      throw AppError.from(e);
    }
  }

  /// Dev-вход под выбранным пользователем (только локально и на моке).
  Future<void> devLogin(int userId) =>
      _login(() => api.auth.devLogin(DevLoginRequest(userId: userId)));

  /// Пользователи для dev-входа или null, если dev-вход на сервере выключен.
  Future<List<UserBrief>?> devUsers() async {
    try {
      return await api.auth.listDevUsers() ?? const [];
    } catch (e) {
      final error = AppError.from(e);
      if (error.code == 'dev_login_disabled') return null;
      throw error;
    }
  }

  Future<void> logout() async {
    try {
      await api.auth.logout();
    } catch (_) {
      // Токен на сервере мог уже истечь — локальную сессию закрываем в любом случае.
    }
    await _clear();
  }

  /// Меняет адрес сервера. Сессия другого сервера не действует, поэтому выходим.
  Future<void> changeServer(String url) async {
    if (status == SessionStatus.signedIn) await logout();
    await store.writeServerUrl(url);
    api.baseUrl = url;
    _dictionaries = null;
    await _clear();
  }

  /// Подпись роли из справочника, например «Руководитель подразделения».
  String roleLabel(Role role) => _label(_dictionaries?.roles, role.toJson());

  String typeLabel(AppealType type) => _label(_dictionaries?.appealTypes, type.toJson());

  String priorityLabel(Priority priority) => _label(_dictionaries?.priorities, priority.toJson());

  String statusLabel(AppealStatus status) => statusCodeLabel(status.toJson());

  /// Подпись действия из справочника, например «Взять на рассмотрение».
  String actionLabel(AppealAction action) {
    for (final item in _dictionaries?.actions ?? const <DictionariesActionsInner>[]) {
      if (item.code == action.toJson()) return item.label;
    }
    return action.toJson();
  }

  /// Для истории событий: там статус приходит строкой.
  String statusCodeLabel(String code) {
    for (final item in _dictionaries?.statuses ?? const <DictionariesStatusesInner>[]) {
      if (item.code == code) return item.label;
    }
    return code;
  }

  /// Значение поля из истории: коды статуса, типа и приоритета — подписями из справочника.
  String historyCodeLabel(String? field, String code) => switch (field) {
        'status' => statusCodeLabel(code),
        'type' => _label(_dictionaries?.appealTypes, code),
        'priority' => _label(_dictionaries?.priorities, code),
        _ => code,
      };

  String _label(List<LabeledCode>? items, String code) {
    for (final item in items ?? const <LabeledCode>[]) {
      if (item.code == code) return item.label;
    }
    return code;
  }

  Future<void> _login(Future<Session?> Function() request) async {
    final Session? session;
    try {
      session = await request();
    } catch (e) {
      throw AppError.from(e);
    }
    if (session == null) {
      throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
    }
    api.token = session.accessToken;
    await store.writeToken(session.accessToken);
    await store.writeTokenServer(api.baseUrl);
    _me = session.user;
    _offlineError = null;
    await _loadDictionaries();
    _set(SessionStatus.signedIn);
  }

  Future<void> _loadDictionaries() async {
    if (_dictionaries != null) return;
    try {
      _dictionaries = await api.dictionaries.getDictionaries();
    } catch (_) {
      // Без подписей приложение работает: покажем коды. Перечитаем при следующем входе.
    }
  }

  Future<void> _clear() async {
    api.token = null;
    await store.writeToken(null);
    await store.writeTokenServer(null);
    _me = null;
    _set(SessionStatus.signedOut);
  }

  void _set(SessionStatus status) {
    _status = status;
    notifyListeners();
  }
}
