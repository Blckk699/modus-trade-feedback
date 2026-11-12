import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app.dart';
import '../../navigation/sections.dart';
import '../appeals/my_appeals_screen.dart';
import '../analytics/digest_screen.dart';
import '../appeals/queue_screen.dart';
import '../discussions/feed_screen.dart';
import '../meetings/meetings_screen.dart';
import '../settings/settings_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';
import 'unread_scope.dart';
import '../web/web_ui.dart';

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
    // Счётчик непрочитанного — на «Мои обращения» (если раздела нет — на первом пункте панели).
    final unread = UnreadScope.of(context).count;
    final badgeOn = onBar.contains(Section.myAppeals) ? Section.myAppeals : onBar.first;

    return Scaffold(
      // Содержимое уходит под полупрозрачную панель, как `.tabbar` в вебе (backdrop-filter: blur).
      extendBody: true,
      body: _screenFor(current),
      bottomNavigationBar: WebTabBar(
        items: [
          for (final s in onBar)
            WebTab(
              key: Key('nav-${s.name}'),
              icon: s.icon,
              label: s.shortTitle,
              badge: s == badgeOn ? unread : 0,
              active: s == current,
              onTap: () => setState(() => _current = s),
            ),
          if (overflow)
            WebTab(
              key: const Key('nav-more'),
              icon: inMore.contains(current) ? current.icon : LucideIcons.ellipsis,
              label: inMore.contains(current) ? current.shortTitle : 'Ещё',
              active: inMore.contains(current),
              onTap: () => _openMore(inMore, current),
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
        Section.home => TodayScreen(onOpenSection: (s) => setState(() => _current = s)),
        Section.myAppeals => const MyAppealsScreen(),
        Section.processing => const QueueScreen(),
        Section.feed => const FeedScreen(),
        Section.analytics => const DigestScreen(),
        Section.meetings => const MeetingsScreen(),
        Section.settings => const SettingsScreen(),
        Section.profile => const ProfileScreen(),
      };
}
