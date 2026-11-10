import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../app.dart';
import '../../appeals/labels.dart';
import '../../format.dart';

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.background, required this.foreground});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
      );
}

/// Статус с подписью из справочника.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final AppealStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      AppealStatus.implemented => (scheme.primaryContainer, scheme.onPrimaryContainer),
      AppealStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer),
      AppealStatus.awaitingInfo => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      AppealStatus.closed => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return _Pill(text: SessionScope.of(context).statusLabel(status), background: bg, foreground: fg);
  }
}

/// Срок первого ответа: состояние считает бэкенд (`due_state`), клиент только показывает.
class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.state, required this.dueAt});

  final DueState state;
  final DateTime? dueAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (state) {
      DueState.overdue => (scheme.errorContainer, scheme.onErrorContainer),
      DueState.dueSoon => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    final showDate = dueAt != null && (state == DueState.onTime || state == DueState.dueSoon || state == DueState.overdue);
    final text = showDate ? '${dueStateLabel(state)} · до ${formatDateTime(dueAt!)}' : dueStateLabel(state);
    return _Pill(text: text, background: bg, foreground: fg);
  }
}
