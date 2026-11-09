import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/features/attendance/presentation/screens/widgets/group_attendance_dialog.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:provider/provider.dart';

import '../helpers/test_backend.dart';

void main() {
  for (final username in ['orgadmin', 'employee']) {
    testWidgets(
      '$username completes its operational action with the real app wiring',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repos = buildTestBackend();
        addTearDown(mockAuthOf(repos).dispose);
        await tester.pumpWidget(WorkAxisApp(repositories: repos));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).at(0), username);
        await tester.enterText(find.byType(TextField).at(1), 'Password123!');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
        if (username == 'orgadmin') {
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .go(AppRoutes.orgAdminAttendance);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Group Check-In'));
          await tester.pumpAndSettle();
          expect(find.byType(GroupAttendanceDialog), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        } else {
          final context = tester.element(find.byType(Scaffold).first);
          final controller = context.read<EmployeeHomeController>();
          expect(controller.summary!.currentStatus, AttendanceStatus.checkedIn);
          await tester.ensureVisible(find.text('Check Out'));
          await tester.tap(find.text('Check Out'));
          await tester.pumpAndSettle();
          expect(
            controller.summary!.currentStatus,
            AttendanceStatus.checkedOut,
          );
          expect(find.text('Check Out'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
