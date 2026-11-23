import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/routing/role_destinations.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Detail and edit routes inherit their area's guard. These pin that down so
/// a switch to exact matching cannot silently open nested routes.
void main() {
  String? guard(UserRole role, String location) =>
      redirectForRoleRoute(role: role, matchedLocation: location);

  test('platform administrators cannot open nested platform user routes', () {
    for (final location in [
      '${AppRoutes.platformUsers}/x/edit',
      '${AppRoutes.platformUsers}/x/reset-password',
    ]) {
      expect(
        guard(UserRole.platformAdmin, location),
        isNotNull,
        reason: location,
      );
      expect(guard(UserRole.platformOwner, location), isNull, reason: location);
    }
  });

  test('each customer area rejects other roles on nested routes', () {
    final cases = <String, UserRole>{
      '${AppRoutes.orgAdminEmployees}/x/edit': UserRole.orgAdmin,
      '${AppRoutes.orgAdminBranches}/x': UserRole.orgAdmin,
      '${AppRoutes.branchManagerReturns}/x/edit': UserRole.branchManager,
      '${AppRoutes.employeeReturns}/x/edit': UserRole.employee,
    };
    for (final MapEntry(key: location, value: owner) in cases.entries) {
      for (final role in UserRole.values) {
        final redirect = guard(role, location);
        if (role == owner) {
          expect(redirect, isNull, reason: '$role on $location');
        } else {
          expect(redirect, isNotNull, reason: '$role on $location');
          expect(redirect, defaultRouteForRole(role));
        }
      }
    }
  });
}
