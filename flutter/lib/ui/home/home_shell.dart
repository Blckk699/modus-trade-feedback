import 'package:flutter/material.dart';

import '../../app.dart';
import '../../navigation/sections.dart';
import 'profile_screen.dart';
import 'section_screen.dart';

/// Главный экран: нижняя навигация по разделам роли. Больше пяти разделов —
/// первые четыре на панели, остальные в «Ещё».
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const maxBarItems = 5;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Section? _current;

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).me;
    final sections = sectionsFor(me);
    var current = _current ?? startSectionFor(me);
    if (!sections.contains(current)) current = startSectionFor(me);

    final overflow = sections.length > HomeShell.maxBarItems;
    final onBar = overflow ? sections.take(HomeShell.maxBarItems - 1).toList() : sections;
    final inMore = overflow ? sections.skip(HomeShell.maxBarItems - 1).toList() : <Section>[];
    final barIndex = onBar.contains(current) ? onBar.indexOf(current) : onBar.length;

    return Scaffold(
      body: _screenFor(current),
      bottomNavigationBar: NavigationBar(
        selectedIndex: barIndex,
        onDestinationSelected: (index) {
          if (index < onBar.length) {
            setState(() => _current = onBar[index]);
          } else {
            _openMore(inMore, current);
          }
        },
        destinations: [
          for (final s in onBar)
            NavigationDestination(
              key: Key('nav-${s.name}'),
              icon: Icon(s.icon),
              selectedIcon: Icon(s.selectedIcon),
              label: s.shortTitle,
            ),
          if (overflow)
            NavigationDestination(
              key: const Key('nav-more'),
              icon: const Icon(Icons.more_horiz),
              selectedIcon: Icon(inMore.contains(current) ? current.selectedIcon : Icons.more_horiz),
              label: inMore.contains(current) ? current.shortTitle : 'Ещё',
            ),
        ],
      ),
    );
  }

  Future<void> _openMore(List<Section> sections, Section current) async {
    final picked = await showModalBottomSheet<Section>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in sections)
              ListTile(
                key: Key('more-${s.name}'),
                leading: Icon(s == current ? s.selectedIcon : s.icon),
                title: Text(s.title),
                selected: s == current,
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _current = picked);
  }

  Widget _screenFor(Section section) => switch (section) {
        Section.profile => const ProfileScreen(),
        _ => SectionScreen(section: section),
      };
}
