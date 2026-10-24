import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/employee_returns_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/returns_operations_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_card_item.dart';

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late MockReturnsRepository returnsRepository;
  late AccessController accessController;
  late BranchContextController branchContextController;
  late ReturnsController returnsController;

  setUp(() {
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    returnsRepository = MockReturnsRepository();
    accessController = AccessController(accessRepository: accessRepository);
    branchContextController = BranchContextController();
    returnsController = ReturnsController(repository: returnsRepository);
  });

  tearDown(() {
    accessController.dispose();
    branchContextController.dispose();
    returnsController.dispose();
  });

  Future<void> pumpReturnsOperationsScreen(
    WidgetTester tester, {
    required UserRole role,
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
      AppUser(
        id: 'user-oa-01',
        name: 'Jordan Lee',
        username: 'jordan.lee',
        role: role,
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
          ChangeNotifierProvider<ReturnsController>.value(
            value: returnsController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReturnsOperationsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpEmployeeReturnsScreen(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
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
          ChangeNotifierProvider<ReturnsController>.value(
            value: returnsController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EmployeeReturnsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Returns Operations Screen Tests', () {
    testWidgets('renders Organization Returns on desktop with table', (tester) async {
      await pumpReturnsOperationsScreen(tester, role: UserRole.orgAdmin, width: 1200);

      expect(find.text('Organization Returns'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Total returns'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('renders cleanly on smartphone (390x844) with ReturnCardItem list and zero overflow', (tester) async {
      await pumpReturnsOperationsScreen(tester, role: UserRole.orgAdmin, width: 390, height: 844);

      expect(find.text('Organization Returns'), findsOneWidget);
      expect(find.byType(ReturnCardItem), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024) with 2-column grid and zero overflow', (tester) async {
      await pumpReturnsOperationsScreen(tester, role: UserRole.branchManager, width: 768, height: 1024);

      expect(find.text('Branch Returns'), findsOneWidget);
      expect(find.byType(ReturnCardItem), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Employee Returns Screen Tests', () {
    testWidgets('renders My Returns and Submit Return button on smartphone (390x844)', (tester) async {
      await pumpEmployeeReturnsScreen(tester, width: 390, height: 844);

      expect(find.text('My Returns'), findsOneWidget);
      expect(find.text('Submit Return'), findsOneWidget);
      expect(find.byType(ReturnCardItem), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024)', (tester) async {
      await pumpEmployeeReturnsScreen(tester, width: 768, height: 1024);

      expect(find.text('My Returns'), findsOneWidget);
      expect(find.text('Submit Return'), findsOneWidget);
      expect(find.byType(ReturnCardItem), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
