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
import 'package:workaxis/features/reports/data/mock_reports_repository.dart';
import 'package:workaxis/features/reports/presentation/controllers/reports_controller.dart';
import 'package:workaxis/features/reports/presentation/screens/operational_reports_screen.dart';

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late MockReportsRepository reportsRepository;
  late AccessController accessController;
  late BranchContextController branchContextController;
  late ReportsController reportsController;

  setUp(() {
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    reportsRepository = MockReportsRepository(delay: Duration.zero);
    accessController = AccessController(accessRepository: accessRepository);
    branchContextController = BranchContextController();
    reportsController = ReportsController(repository: reportsRepository);
  });

  tearDown(() {
    accessController.dispose();
    branchContextController.dispose();
    reportsController.dispose();
  });

  Future<void> pumpOperationalReportsScreen(
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

    final user = role == UserRole.branchManager
        ? const AppUser(
            id: 'user-bm-01',
            name: 'Marcus Vance',
            username: 'marcus.vance',
            role: UserRole.branchManager,
            organizationId: 'org-acme',
          )
        : const AppUser(
            id: 'user-oa-01',
            name: 'Jordan Lee',
            username: 'jordan.lee',
            role: UserRole.orgAdmin,
            organizationId: 'org-acme',
          );

    await accessController.resolveAccess(user);
    final access = accessController.accessContext;
    if (access != null) {
      branchContextController.initFromAccessContext(access);
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(value: accessController),
          ChangeNotifierProvider<BranchContextController>.value(
            value: branchContextController,
          ),
          ChangeNotifierProvider<ReportsController>.value(
            value: reportsController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OperationalReportsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Operational Reports Screen Widget Tests', () {
    testWidgets('renders Operational Reports on desktop for Org Admin', (tester) async {
      await pumpOperationalReportsScreen(tester, role: UserRole.orgAdmin, width: 1200);

      expect(find.text('Operational Reports'), findsOneWidget);
      expect(find.text('Attendance rate'), findsOneWidget);
      expect(find.text('On-time arrival'), findsOneWidget);
      expect(find.text('Total hours logged'), findsOneWidget);
      expect(find.text('Exceptions flagged'), findsOneWidget);
      expect(find.text('Daily Attendance Compliance'), findsOneWidget);
      expect(find.text('Branch Workforce Compliance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on smartphone (390x844) for Branch Manager with zero overflow', (tester) async {
      await pumpOperationalReportsScreen(
        tester,
        role: UserRole.branchManager,
        width: 390,
        height: 844,
      );

      expect(find.text('Branch Operational Reports'), findsOneWidget);
      expect(find.text('Export Report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024) with zero overflow', (tester) async {
      await pumpOperationalReportsScreen(
        tester,
        role: UserRole.branchManager,
        width: 768,
        height: 1024,
      );

      expect(find.text('Branch Operational Reports'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching period chips triggers report reload', (tester) async {
      await pumpOperationalReportsScreen(tester, role: UserRole.orgAdmin, width: 1200);

      final thisMonthChip = find.text('This Month');
      expect(thisMonthChip, findsOneWidget);

      await tester.tap(thisMonthChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(reportsController.selectedPeriod, equals('This Month'));
    });

    testWidgets('tapping Export Report triggers confirmation snackbar', (tester) async {
      await pumpOperationalReportsScreen(tester, role: UserRole.orgAdmin, width: 1200);

      final exportButton = find.text('Export Report');
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pump();

      expect(find.text('Operational report export generated (PDF & CSV).'), findsOneWidget);
    });
  });
}
