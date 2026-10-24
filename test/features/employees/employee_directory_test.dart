import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
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
      accessRepo = MockAccessRepository(dataSource: dataSource, delay: Duration.zero);
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

    testWidgets('renders cards with matching button heights and primary edit button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accessController),
            ChangeNotifierProvider.value(value: branchController),
            ChangeNotifierProvider.value(value: membersController),
          ],
          child: const MaterialApp(
            home: EmployeeDirectoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no layout exceptions and cards are rendered
      expect(find.byType(EmployeeDirectoryScreen), findsOneWidget);
      expect(find.text('Employee Directory'), findsOneWidget);

      // Verify OutlinedButton and FilledButton exist
      final outlinedButtons = find.byType(OutlinedButton);
      final filledButtons = find.byType(FilledButton);
      expect(outlinedButtons, findsWidgets);
      expect(filledButtons, findsWidgets);

      // Compare the rendered height of the first OutlinedButton and FilledButton
      final outlinedSize = tester.getSize(outlinedButtons.first);
      final filledSize = tester.getSize(filledButtons.first);

      expect(
        filledSize.height,
        equals(outlinedSize.height),
        reason: 'FilledButton and OutlinedButton heights must match exactly',
      );

      // Verify FilledButton has primary background color and white icon
      final filledWidget = tester.widget<FilledButton>(filledButtons.first);
      final buttonStyle = filledWidget.style!;
      expect(buttonStyle.backgroundColor?.resolve({}), equals(AppColors.primary));
      expect(buttonStyle.foregroundColor?.resolve({}), equals(AppColors.onPrimary));
    });

    testWidgets('renders cleanly on smartphone (390x844) without overflow', (tester) async {
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
          child: const MaterialApp(
            home: EmployeeDirectoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Employee Directory'), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet (768x1024) without overflow', (tester) async {
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
          child: const MaterialApp(
            home: EmployeeDirectoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Employee Directory'), findsOneWidget);
    });
  });
}
