import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/screens/employee_directory_screen.dart';

void main() {
  group('EmployeeDirectoryScreen Widget Tests', () {
    late MockAccessDataSource dataSource;
    late MockAccessRepository accessRepo;
    late MockOrganizationMembersRepository membersRepo;
    late AccessController accessController;
    late BranchContextController branchController;
    late OrganizationMembersController membersController;

    setUp(() async {
      dataSource = MockAccessDataSource();
      accessRepo = MockAccessRepository(
        dataSource: dataSource,
        delay: Duration.zero,
      );
      membersRepo = MockOrganizationMembersRepository(
        accessDataSource: dataSource,
      );

      const adminUser = AppUser(
        id: 'user-oa-01',
        name: 'Jordan Lee',
        username: 'jordan.lee',
        role: UserRole.orgAdmin,
        organizationId: 'org-acme',
      );

      accessController = AccessController(accessRepository: accessRepo);
      await accessController.resolveAccess(adminUser);

      branchController = BranchContextController();
      membersController = OrganizationMembersController(
        repository: membersRepo,
      );
    });

    tearDown(() {
      accessController.dispose();
      branchController.dispose();
      membersController.dispose();
    });

    testWidgets('renders member cards with view and edit actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: membersController),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Employee Directory'), findsOneWidget);
      expect(find.text('View details'), findsWidgets);
      // Organization Admin may manage every non-platform account.
      expect(find.text('Edit'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('seeds the search field from the controller query', (
      tester,
    ) async {
      final zeroDebounce = OrganizationMembersController(
        repository: membersRepo,
        searchDebounce: Duration.zero,
      );
      addTearDown(zeroDebounce.dispose);
      await zeroDebounce.setQuery(
        access: accessController.accessContext!,
        query: 'sarah',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: zeroDebounce),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, 'sarah');
    });
    testWidgets('renders cleanly on smartphone (390x844) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: membersController),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Employee Directory'), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768x1024) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: membersController),
          ],
          child: const MaterialApp(home: EmployeeDirectoryScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Employee Directory'), findsOneWidget);
    });
  });
}
