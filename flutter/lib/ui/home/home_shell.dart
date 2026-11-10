import 'package:flutter/material.dart';

import '../../app.dart';
import '../../navigation/sections.dart';
import '../appeals/my_appeals_screen.dart';
import '../analytics/digest_screen.dart';
import '../appeals/queue_screen.dart';
import '../discussions/feed_screen.dart';
import 'profile_screen.dart';
import 'section_screen.dart';
import 'unread_scope.dart';

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
    // Счётчик непрочитанного — на первом разделе панели (у сотрудника это «Мои обращения»).
    final unread = UnreadScope.of(context).count;
    final badgeOn = onBar.first;

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
              icon: _withUnread(Icon(s.icon), s == badgeOn ? unread : 0),
              selectedIcon: _withUnread(Icon(s.selectedIcon), s == badgeOn ? unread : 0),
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

  static Widget _withUnread(Widget icon, int count) => count <= 0
      ? icon
      : Badge(
          key: const Key('unread-badge'),
          label: Text(count > 99 ? '99+' : '$count'),
          child: icon,
        );

  Widget _screenFor(Section section) => switch (section) {
        Section.myAppeals => const MyAppealsScreen(),
        Section.processing => const QueueScreen(),
        Section.feed => const FeedScreen(),
        Section.analytics => const DigestScreen(),
        Section.profile => const ProfileScreen(),
        _ => SectionScreen(section: section),
      };
}
