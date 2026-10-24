import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/profile/presentation/screens/employee_profile_screen.dart';

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late MockAuthenticationRepository authRepository;
  late AccessController accessController;
  late BranchContextController branchContextController;
  late AuthController authController;

  setUp(() {
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    authRepository = MockAuthenticationRepository(delay: Duration.zero);
    accessController = AccessController(accessRepository: accessRepository);
    branchContextController = BranchContextController();
    authController = AuthController(authRepository: authRepository);
  });

  tearDown(() {
    accessController.dispose();
    branchContextController.dispose();
    authController.dispose();
  });

  Future<void> pumpEmployeeProfileScreen(
    WidgetTester tester, {
    double width = 1200,
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await accessController.resolveAccess(
      const AppUser(
        id: 'user-emp-01',
        name: 'Sarah Connor',
        username: 'sarah.connor',
        role: UserRole.employee,
        organizationId: 'org-acme',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(value: accessController),
          ChangeNotifierProvider<BranchContextController>.value(
            value: branchContextController,
          ),
          ChangeNotifierProvider<AuthController>.value(value: authController),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EmployeeProfileScreen(),
        ),
      ),
    );

    await tester.pump();
  }

  group('Employee Profile Screen Tests', () {
    testWidgets('renders all profile sections on desktop', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 1200);

      expect(find.text('My Profile & Credentials'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('Assigned Work Schedule & Geofence'), findsOneWidget);
      expect(find.text('Employee Information'), findsOneWidget);
      expect(find.text('Security & Password'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on smartphone (390x844) with zero overflow', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 390, height: 844);

      expect(find.text('My Profile & Credentials'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024) with zero overflow', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 768, height: 1024);

      expect(find.text('My Profile & Credentials'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty password fields trigger validation error', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 1200);

      final updateButton = find.text('Update Password');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pump();

      expect(find.text('Please fill out all password fields.'), findsOneWidget);
    });

    testWidgets('mismatching passwords trigger validation error', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 1200);

      final currentField = find.byType(TextField).at(0);
      final newField = find.byType(TextField).at(1);
      final confirmField = find.byType(TextField).at(2);
      final updateButton = find.text('Update Password');

      await tester.ensureVisible(currentField);
      await tester.enterText(currentField, 'Password123!');
      await tester.enterText(newField, 'NewSecret123!');
      await tester.enterText(confirmField, 'DifferentSecret123!');

      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pump();

      expect(find.text('New passwords do not match.'), findsOneWidget);
    });

    testWidgets('short password (<8 chars) triggers validation error', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 1200);

      final currentField = find.byType(TextField).at(0);
      final newField = find.byType(TextField).at(1);
      final confirmField = find.byType(TextField).at(2);
      final updateButton = find.text('Update Password');

      await tester.ensureVisible(currentField);
      await tester.enterText(currentField, 'Password123!');
      await tester.enterText(newField, 'Short1');
      await tester.enterText(confirmField, 'Short1');

      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pump();

      expect(find.text('New password must be at least 8 characters long.'), findsOneWidget);
    });

    testWidgets('valid password update displays success snackbar', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 1200);

      final currentField = find.byType(TextField).at(0);
      final newField = find.byType(TextField).at(1);
      final confirmField = find.byType(TextField).at(2);
      final updateButton = find.text('Update Password');

      await tester.ensureVisible(currentField);
      await tester.enterText(currentField, 'Password123!');
      await tester.enterText(newField, 'FreshNewSecret123!');
      await tester.enterText(confirmField, 'FreshNewSecret123!');

      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Your password has been changed successfully.'), findsOneWidget);
    });

    testWidgets('tapping Sign Out opens confirmation modal', (tester) async {
      await pumpEmployeeProfileScreen(tester, width: 1200);

      final signOutButton = find.text('Sign Out');
      await tester.tap(signOutButton);
      await tester.pump();

      expect(find.text('Are you sure you want to end your current session?'), findsOneWidget);
    });
  });
}
