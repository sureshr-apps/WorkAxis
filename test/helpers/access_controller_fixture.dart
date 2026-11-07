import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// An [AccessController] already resolved for the mock user [id] of [role]
/// (ids match `MockAccessDataSource`: `user-oa-01`, `user-bm-multi-01`,
/// `user-bm-single-01`, `user-emp-01`). Zero latency, hermetic.
Future<AccessController> resolvedAccessController(
  UserRole role,
  String id, {
  String name = 'Fixture User',
}) async {
  final controller = AccessController(
    accessRepository: MockAccessRepository(delay: Duration.zero),
  );
  await controller.resolveAccess(
    AppUser(
      id: id,
      name: name,
      username: id,
      role: role,
      organizationId: 'org-acme',
    ),
  );
  return controller;
}
