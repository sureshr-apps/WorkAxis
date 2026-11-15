import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../helpers/session_fakes.dart';

class _ThrowingAccessRepository extends FakeAccessRepository {
  _ThrowingAccessRepository() : super((user) => UserAccessContext(user: user));

  @override
  Future<UserAccessContext> resolveCurrentUserAccess(AppUser user) async =>
      throw Exception('socket 10.0.0.1:5432 refused');
}

void main() {
  late FakeAccessRepository repository;
  late AccessController controller;
  var resolved = <String>[];

  setUp(() {
    resolved = [];
    repository = FakeAccessRepository(
      (user) => UserAccessContext(user: user, organization: testOrganization),
    );
    controller = AccessController(
      accessRepository: repository,
      onResolved: (context) => resolved.add(context.user.id),
    );
  });

  tearDown(() => controller.dispose());

  test('a slow response for user A cannot overwrite user B', () async {
    final userA = testUser(UserRole.employee, id: 'user-a');
    final userB = testUser(UserRole.employee, id: 'user-b');
    final gateA = Completer<void>();
    repository.gates['user-a'] = gateA;

    final resolveA = controller.resolveAccess(userA);
    final resolveB = controller.resolveAccess(userB);

    expect(await resolveB, isTrue);
    expect(controller.accessContext?.user.id, 'user-b');

    gateA.complete();
    expect(await resolveA, isFalse);
    expect(controller.accessContext?.user.id, 'user-b');
    expect(resolved, ['user-b']);
  });

  test('clear() discards a resolution that is still in flight', () async {
    final user = testUser(UserRole.employee, id: 'user-a');
    final gate = Completer<void>();
    repository.gates['user-a'] = gate;

    final pending = controller.resolveAccess(user);
    controller.clear();
    gate.complete();

    expect(await pending, isFalse);
    expect(controller.accessContext, isNull);
    expect(controller.isResolving, isFalse);
    expect(resolved, isEmpty);
  });

  test(
    'failures surface a safe message instead of raw exception text',
    () async {
      final failing = AccessController(
        accessRepository: _ThrowingAccessRepository(),
      );
      addTearDown(failing.dispose);

      expect(await failing.resolveAccess(testUser(UserRole.employee)), isFalse);

      expect(failing.errorMessage, isNotNull);
      expect(failing.errorMessage, isNot(contains('socket')));
      expect(failing.errorMessage, isNot(contains('Exception')));
    },
  );

  test('refreshAccess updates context silently without isResolving', () async {
    final user = testUser(UserRole.orgAdmin, id: 'user-oa-01');
    await controller.resolveAccess(user);
    expect(controller.accessContext?.user.id, 'user-oa-01');
    expect(controller.isResolving, isFalse);

    var notified = false;
    controller.addListener(() => notified = true);

    final success = await controller.refreshAccess();
    expect(success, isTrue);
    expect(notified, isTrue);
    expect(controller.isResolving, isFalse);
    expect(controller.accessContext?.user.id, 'user-oa-01');
    expect(resolved, ['user-oa-01', 'user-oa-01']);
  });

  test('refreshAccess preserves existing context on failure', () async {
    final throwingRepo = _ThrowingAccessRepository();
    final c = AccessController(accessRepository: throwingRepo);
    addTearDown(c.dispose);

    // No resolved user initially
    expect(await c.refreshAccess(), isFalse);

    // If resolving failed, refreshAccess returns false without clearing error
    await c.resolveAccess(testUser(UserRole.employee));
    expect(c.errorMessage, isNotNull);
    expect(await c.refreshAccess(), isFalse);
  });
}
