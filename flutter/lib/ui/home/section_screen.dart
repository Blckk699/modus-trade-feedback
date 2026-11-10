import 'package:flutter/material.dart';

import '../../navigation/sections.dart';

/// Каркас раздела. Содержимое разделов добавляют следующие тикеты:
/// F-02 «Мои обращения», F-03 «Обработка», F-05 «Лента», F-06 «Сводка»,
/// F-07 «Совещания», F-08 «Настройки».
class SectionScreen extends StatelessWidget {
  const SectionScreen({super.key, required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: Center(
        child: Icon(section.icon, size: 64, color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}
