import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../theme/modus_theme.dart';
import 'badges.dart';

/// Список строк в одной карточке, как `.card.list-card` + `.rows` в вебе: разделители между строками.
class RowsCard extends StatelessWidget {
  const RowsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebLook.cardRadius)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: ModusColors.of(context).palette.border),
          children[i],
        ],
      ]),
    );
  }
}

/// Строка обращения как `.row` в вебе: значок типа в круге, суть, мета-строка, справа бейджи.
class WebRow extends StatelessWidget {
  const WebRow({
    super.key,
    required this.type,
    required this.title,
    required this.meta,
    required this.onTap,
    this.unread = false,
    this.unreadKey,
    this.badges = const [],
    this.overdue = false,
    this.plain = false,
  });

  final AppealType type;
  final String title;
  final String meta;
  final VoidCallback onTap;
  final bool unread;
  final Key? unreadKey;
  final List<Widget> badges;
  final bool overdue;

  /// Строка внутри карточки (`.rows` в вебе): без своих боковых отступов.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: overdue ? c.dangerBg.withValues(alpha: 0.35) : null,
        padding: plain ? const EdgeInsets.symmetric(vertical: 14) : const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TypeIcon(type),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (unread)
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 6),
                    child: Container(
                      key: unreadKey,
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(height: 1.4),
                  ),
                ),
              ]),
              const SizedBox(height: 2),
              Text(meta, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: badges),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
