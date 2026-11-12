import 'package:flutter/material.dart';

/// Шапка нижнего листа: заголовок и «Закрыть». Лист на всю высоту с открытой клавиатурой
/// свайпом не закрыть — нужна явная кнопка.
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key, this.enabled = true});

  final String title;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        IconButton(
          key: const Key('sheet-close'),
          tooltip: 'Закрыть',
          onPressed: enabled ? () => Navigator.of(context).maybePop() : null,
          icon: const Icon(Icons.close_rounded),
        ),
      ]);
}
