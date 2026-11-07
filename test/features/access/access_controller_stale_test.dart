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
}
