import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/branches/presentation/screens/branch_management_screen.dart';

void main() {
  group('BranchManagementScreen Responsive Tests', () {
    late MockAccessDataSource dataSource;
    late MockAccessRepository accessRepo;
    late MockBranchManagementRepository branchRepo;
    late AccessController accessController;
    late BranchManagementController branchController;

    setUp(() async {
      dataSource = MockAccessDataSource();
      accessRepo = MockAccessRepository(dataSource: dataSource, delay: Duration.zero);
      branchRepo = MockBranchManagementRepository(accessDataSource: dataSource);

      const adminUser = AppUser(
        id: 'user-oa-01',
        name: 'Jordan Lee',
        username: 'jordan.lee',
        role: UserRole.orgAdmin,
        organizationId: 'org-acme',
      );

      accessController = AccessController(accessRepository: accessRepo);
      await accessController.resolveAccess(adminUser);

      branchController = BranchManagementController(repository: branchRepo);
    });

    tearDown(() {
      accessController.dispose();
      branchController.dispose();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: accessController),
          ChangeNotifierProvider.value(value: branchController),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BranchManagementScreen(),
        ),
      );
    }

    testWidgets('renders cleanly on smartphone (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Branch Management'), findsOneWidget);
      expect(find.text('Downtown Flagship'), findsOneWidget);

      final statusChips = tester.widgetList<StatusChip>(find.byType(StatusChip));
      expect(statusChips, isNotEmpty);
      for (final chip in statusChips) {
        expect(chip.width, 96);
      }
    });

    testWidgets('renders cleanly on tablet (768x1024) without overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Branch Management'), findsOneWidget);
      expect(find.text('Downtown Flagship'), findsOneWidget);
    });

    testWidgets('renders cleanly on desktop (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Branch Management'), findsOneWidget);
      expect(find.text('Downtown Flagship'), findsOneWidget);
    });
  });
}
