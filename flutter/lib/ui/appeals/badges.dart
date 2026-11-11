import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../app.dart';
import '../../appeals/labels.dart';
import '../../format.dart';
import '../../theme/modus_theme.dart';

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.background, required this.foreground});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(ModusRadius.pill)),
        child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
      );
}

/// Статус с подписью из справочника.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final AppealStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = ModusColors.of(context).status(status.toJson());
    return _Pill(text: SessionScope.of(context).statusLabel(status), background: colors.bg, foreground: colors.fg);
  }
}

/// Срок первого ответа: состояние считает бэкенд (`due_state`), клиент только показывает.
class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.state, required this.dueAt});

  final DueState state;
  final DateTime? dueAt;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final (bg, fg) = switch (state) {
      DueState.overdue => (c.dangerBg, c.danger),
      DueState.dueSoon => (c.warnBg, c.warn),
      _ => (c.surface2, c.muted),
    };
    final showDate = dueAt != null && (state == DueState.onTime || state == DueState.dueSoon || state == DueState.overdue);
    final text = showDate ? '${dueStateLabel(state)} · до ${formatDateTime(dueAt!)}' : dueStateLabel(state);
    return _Pill(text: text, background: bg, foreground: fg);
  }
}
