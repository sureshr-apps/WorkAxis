import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/routing/role_destinations.dart';
import 'package:workaxis/app/shell/adaptive_app_shell.dart';

void main() {
  const destinations = RoleDestinations.organizationAdmin;
  int indexOf(String route) => destinations.indexWhere((d) => d.route == route);

  test('exact routes select their own destination', () {
    expect(
      selectedDestinationIndex(destinations, AppRoutes.orgAdminEmployees),
      indexOf(AppRoutes.orgAdminEmployees),
    );
    expect(
      selectedDestinationIndex(destinations, AppRoutes.orgAdminWorkspace),
      indexOf(AppRoutes.orgAdminWorkspace),
    );
  });

  test('detail routes select their section, not Home', () {
    expect(
      selectedDestinationIndex(
        destinations,
        '${AppRoutes.orgAdminEmployees}/member-1/edit',
      ),
      indexOf(AppRoutes.orgAdminEmployees),
    );
    expect(
      selectedDestinationIndex(destinations, '${AppRoutes.orgAdminReturns}/r1'),
      indexOf(AppRoutes.orgAdminReturns),
    );
  });

  test('unknown routes fall back to the first destination', () {
    expect(selectedDestinationIndex(destinations, '/elsewhere'), 0);
  });
}
