import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../app.dart';
import '../../appeals/labels.dart';
import '../../format.dart';
import '../../theme/modus_theme.dart';

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.background, required this.foreground, this.dot = false, this.icon});

  final String text;
  final Color background;
  final Color foreground;
  final bool dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(ModusRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: foreground, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.5, color: foreground),
          ),
        ]),
      );
}

/// Цвета типа — как `.type-icon--*` и `.badge--type-*` в вебе.
(Color, Color) typeColors(BuildContext context, AppealType type) {
  final c = ModusColors.of(context);
  return switch (type) {
    AppealType.problem => (c.warnBg, c.warn),
    AppealType.suggestion => (c.status('in_progress').bg, c.status('in_progress').fg),
    _ => (c.successBg, c.success),
  };
}

IconData typeIcon(AppealType type) => switch (type) {
      AppealType.problem => Icons.error_outline_rounded,
      AppealType.suggestion => Icons.lightbulb_outline_rounded,
      _ => Icons.favorite_border_rounded,
    };

/// Значок типа в круге — в строках списков.
class TypeIcon extends StatelessWidget {
  const TypeIcon(this.type, {super.key, this.size = 38});

  final AppealType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = typeColors(context, type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(typeIcon(type), size: size * 0.5, color: fg),
    );
  }
}

/// Тип обращения чипом рядом со статусом (#192).
class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key});

  final AppealType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = typeColors(context, type);
    return KeyedSubtree(
      key: const Key('type-chip'),
      child: _Pill(text: SessionScope.of(context).typeLabel(type), background: bg, foreground: fg, icon: typeIcon(type)),
    );
  }
}

/// Статус с подписью из справочника.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final AppealStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = ModusColors.of(context).status(status.toJson());
    return _Pill(text: SessionScope.of(context).statusLabel(status), background: colors.bg, foreground: colors.fg, dot: true);
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
