import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:modus_api/api.dart';

import '../api/api_service.dart';

/// Счётчик непрочитанного, как в вебе: `GET /notifications/unread-count` раз в 30 секунд
/// и при возврате в приложение; при открытии карточки — `POST /notifications/read` по обращению.
class UnreadController extends ChangeNotifier with WidgetsBindingObserver {
  UnreadController(this.api, {this.interval = const Duration(seconds: 30)});

  final ApiService api;
  final Duration interval;

  int _count = 0;
  int get count => _count;

  Timer? _timer;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    try {
      final result = await api.notifications.getUnreadCount();
      if (result != null) _set(result.count);
    } catch (_) {
      // Счётчик не критичен: оставляем прежнее значение.
    }
  }

  Future<void> markAppealRead(int appealId) async {
    try {
      final result = await api.notifications.markNotificationsRead(_AppealRead(appealId));
      if (result != null) _set(result.count);
    } catch (_) {}
  }

  void _set(int value) {
    if (value == _count) return;
    _count = value;
    notifyListeners();
  }
}

/// Сгенерированный `MarkReadRequest.toJson` отправляет все поля (`"all": null, "ids": []`),
/// а контракт ждёт одно из трёх. Шлём только `appeal_id`.
class _AppealRead extends MarkReadRequest {
  _AppealRead(int appealId) : super(appealId: appealId);

  @override
  Map<String, dynamic> toJson() => {'appeal_id': appealId};
}
