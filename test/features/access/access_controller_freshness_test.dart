import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../helpers/session_fakes.dart';

void main() {
  late int resolveCalls;
  late DateTime clock;
  late AccessController controller;

  setUp(() async {
    resolveCalls = 0;
    clock = DateTime.utc(2026, 11, 15, 9);
    controller = AccessController(
      accessRepository: FakeAccessRepository((user) {
        resolveCalls++;
        return UserAccessContext(user: user, organization: testOrganization);
      }),
      now: () => clock,
    );
    await controller.resolveAccess(testUser(UserRole.employee, id: 'user-a'));
    resolveCalls = 0;
  });

  tearDown(() => controller.dispose());

  test('a non-forced refresh inside the window skips the round trip', () async {
    clock = clock.add(const Duration(seconds: 59));

    expect(await controller.refreshAccess(force: false), isFalse);
    expect(resolveCalls, 0);
    expect(controller.accessContext, isNotNull);
  });

  test('a forced refresh always reaches the repository', () async {
    expect(await controller.refreshAccess(), isTrue);
    expect(await controller.refreshAccess(force: true), isTrue);
    expect(resolveCalls, 2);
  });

  test('a non-forced refresh after the window re-resolves', () async {
    clock = clock.add(AccessController.freshnessWindow);

    expect(await controller.refreshAccess(force: false), isTrue);
    expect(resolveCalls, 1);
  });

  test('a refresh restarts the window', () async {
    clock = clock.add(const Duration(seconds: 90));
    await controller.refreshAccess(force: false);
    resolveCalls = 0;

    clock = clock.add(const Duration(seconds: 30));
    expect(await controller.refreshAccess(force: false), isFalse);
    expect(resolveCalls, 0);
  });
}
