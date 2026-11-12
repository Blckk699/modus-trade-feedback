import 'package:flutter_test/flutter_test.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/navigation/sections.dart';

import 'fixtures.dart';

Me me(Map<String, dynamic> json) => Me.fromJson(json)!;

// Те же случаи, что в web/src/app/navigation.test.ts, плюс профиль в конце.
void main() {
  test('сотрудник видит свои обращения, ленту и профиль', () {
    final user = me(meJson(permissions: plainEmployeePermissions));
    expect(sectionsFor(user), [Section.myAppeals, Section.feed, Section.profile]);
    expect(startSectionFor(user), Section.myAppeals);
  });

  test('сотрудник-ответственный видит обработку, но начинает со своих обращений', () {
    final user = me(meJson(assignedOpenCount: 2));
    expect(sectionsFor(user), [Section.myAppeals, Section.processing, Section.feed, Section.profile]);
    expect(startSectionFor(user), Section.myAppeals);
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

  test('администратор без can_process_appeals видит обработку (нераспределённые) и начинает с настроек', () {
    final user = me(meJson(id: 2, role: 'admin', permissions: adminPermissions));
    expect(user.permissions.canProcessAppeals, isFalse);
    expect(sectionsFor(user), containsAll([Section.processing, Section.settings]));
    expect(startSectionFor(user), Section.settings);
  });

  test('руководитель без сводки начинает с обработки', () {
    final user = me(meJson(id: 3, role: 'head', permissions: {
      ...plainEmployeePermissions,
      'can_view_department': true,
    }));
    expect(startSectionFor(user), Section.processing);
  });
}
