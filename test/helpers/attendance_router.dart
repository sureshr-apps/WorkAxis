import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/features/attendance/presentation/screens/attendance_details_route.dart';
import 'package:workaxis/features/attendance/presentation/screens/attendance_operations_screen.dart';
import 'package:workaxis/features/attendance/presentation/screens/group_attendance_route.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Attendance routes for [role], registered with the real route loaders the
/// app uses: the list, the group check-in page and the details page.
GoRouter buildAttendanceRouter(UserRole role) {
  final isEmployee = role == UserRole.employee;
  final isManager = role == UserRole.branchManager;

  final listRoute = isEmployee
      ? AppRoutes.employeeAttendance
      : isManager
      ? AppRoutes.branchManagerAttendance
      : AppRoutes.orgAdminAttendance;
  final listLabel = isEmployee
      ? 'My Attendance'
      : isManager
      ? 'Branch Attendance'
      : 'Organization Attendance';
  final groupPath = isManager
      ? AppRoutes.branchManagerAttendanceGroupPath
      : AppRoutes.orgAdminAttendanceGroupPath;
  final detailsPath = isEmployee
      ? AppRoutes.employeeAttendanceDetailsPath(':id')
      : isManager
      ? AppRoutes.branchManagerAttendanceDetailsPath(':id')
      : AppRoutes.orgAdminAttendanceDetailsPath(':id');

  return GoRouter(
    initialLocation: listRoute,
    routes: [
      GoRoute(
        path: listRoute,
        builder: (context, state) => const AttendanceOperationsScreen(),
      ),
      // Declared before the details route so "group" is not read as an id.
      GoRoute(
        path: groupPath,
        builder: (context, state) =>
            GroupAttendanceRoute(listRoute: listRoute, listLabel: listLabel),
      ),
      GoRoute(
        path: detailsPath,
        builder: (context, state) => AttendanceDetailsRoute(
          entryId: state.pathParameters['id']!,
          listRoute: listRoute,
          listLabel: listLabel,
        ),
      ),
    ],
  );
}
