import 'package:flutter_test/flutter_test.dart';
import 'package:modus_api/api.dart';
import 'package:modus_feedback/navigation/sections.dart';

import 'fixtures.dart';

Me me(Map<String, dynamic> json) => Me.fromJson(json)!;

// Те же случаи, что в web/src/app/navigation.test.ts: «Сегодня» у всех и стартовый, профиль в конце.
void main() {
  test('сотрудник: Сегодня, свои обращения, лента и профиль', () {
    final user = me(meJson(permissions: plainEmployeePermissions));
    expect(sectionsFor(user), [Section.home, Section.myAppeals, Section.feed, Section.profile]);
    expect(startSectionFor(user), Section.home);
  });

  test('сотрудник-ответственный видит входящие', () {
    final user = me(meJson());
    expect(sectionsFor(user), [Section.home, Section.myAppeals, Section.processing, Section.feed, Section.profile]);
    expect(startSectionFor(user), Section.home);
  });

  test('собственник видит входящие, сводку, совещания и настройки доступа', () {
    final user = me(meJson(id: 1, role: 'owner', permissions: ownerPermissions));
    expect(sectionsFor(user), [
      Section.home,
      Section.myAppeals,
      Section.processing,
      Section.feed,
      Section.analytics,
      Section.meetings,
      Section.settings,
      Section.profile,
    ]);
    expect(startSectionFor(user), Section.home);
  });

  test('администратор без can_process_appeals видит входящие (нераспределённые) и настройки', () {
    final user = me(meJson(id: 2, role: 'admin', permissions: adminPermissions));
    expect(user.permissions.canProcessAppeals, isFalse);
    expect(sectionsFor(user), containsAll([Section.processing, Section.settings]));
    expect(startSectionFor(user), Section.home);
  });

  test('руководитель без сводки видит входящие', () {
    final user = me(meJson(id: 3, role: 'head', permissions: {
      ...plainEmployeePermissions,
      'can_view_department': true,
    }));
    expect(sectionsFor(user), contains(Section.processing));
    expect(startSectionFor(user), Section.home);
  });
}
