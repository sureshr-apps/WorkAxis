import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/functions_error_mapper.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../helpers/session_fakes.dart';

/// Access repository whose resolution is refused with [error], as the server
/// refuses a member through the data callable.
class _RefusingAccessRepository extends FakeAccessRepository {
  _RefusingAccessRepository(this.error)
    : super((user) => UserAccessContext(user: user));

  final Object error;

  @override
  Future<UserAccessContext> resolveCurrentUserAccess(AppUser user) async =>
      throw error;
}

void main() {
  const organizationExpired =
      "Your organization's license has expired. Contact your administrator.";

  test('shows the server refusal message exactly as received', () async {
    final error = mapFunctionsError(
      FirebaseFunctionsException(
        code: 'permission-denied',
        message: organizationExpired,
      ),
      StackTrace.empty,
    );
    final controller = AccessController(
      accessRepository: _RefusingAccessRepository(error),
    );
    addTearDown(controller.dispose);

    final resolved = await controller.resolveAccess(
      testUser(UserRole.employee),
    );

    expect(resolved, isFalse);
    expect(controller.errorMessage, organizationExpired);
    expect(controller.accessContext, isNull);
  });
}
