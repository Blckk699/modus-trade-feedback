import 'package:flutter_test/flutter_test.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/navigation/sections.dart';

import 'fixtures.dart';

Me me(Map<String, dynamic> json) => Me.fromJson(json)!;

void main() {
  test('сотрудник видит свои обращения, ленту и профиль', () {
    final user = me(meJson(permissions: plainEmployeePermissions));
    expect(sectionsFor(user), [Section.myAppeals, Section.feed, Section.profile]);
    expect(startSectionFor(user), Section.myAppeals);
  });

  test('сотрудник-ответственный видит обработку и начинает с неё, если есть открытые', () {
    final user = me(meJson(assignedOpenCount: 2));
    expect(sectionsFor(user), [Section.myAppeals, Section.processing, Section.feed, Section.profile]);
    expect(startSectionFor(user), Section.processing);
    expect(startSectionFor(me(meJson())), Section.myAppeals);
  });

  test('собственник видит обработку, сводку и совещания и начинает со сводки', () {
    final user = me(meJson(id: 1, role: 'owner', permissions: ownerPermissions));
    expect(sectionsFor(user), [
      Section.myAppeals,
      Section.processing,
      Section.feed,
      Section.analytics,
      Section.meetings,
      Section.profile,
    ]);
    expect(startSectionFor(user), Section.analytics);
  });

  test('администратор видит настройки и начинает с них', () {
    final user = me(meJson(id: 2, role: 'admin', permissions: adminPermissions));
    expect(sectionsFor(user), contains(Section.settings));
    expect(startSectionFor(user), Section.settings);
  });

  test('стартовый раздел роли без права падает на первый доступный', () {
    final user = me(meJson(id: 3, role: 'head', permissions: plainEmployeePermissions));
    expect(startSectionFor(user), Section.myAppeals);
  });
}
