import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/employee_returns_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/returns_operations_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_card_item.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_details_dialog.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/submit_return_dialog.dart';

import '../../helpers/fixed_clock.dart';

/// Reads succeed; every write fails, to exercise inline error surfacing.
class _WriteFailingReturnsRepository extends MockReturnsRepository {
  _WriteFailingReturnsRepository() : super(now: fixedNow, delay: Duration.zero);

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) => Future.error(StateError('backend down'));

  @override
  Future<ReturnItem> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) => Future.error(StateError('backend down'));
}

void main() {
  late AccessController accessController;
  late BranchContextController branchController;
  late ReturnsController returnsController;

  setUp(() {
    accessController = AccessController(
      accessRepository: MockAccessRepository(
        dataSource: MockAccessDataSource(),
        delay: Duration.zero,
      ),
    );
    branchController = BranchContextController();
    returnsController = ReturnsController(
      repository: _WriteFailingReturnsRepository(),
    );
  });

  tearDown(() {
    accessController.dispose();
    branchController.dispose();
    returnsController.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    required UserRole role,
    required Widget home,
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
        id: role == UserRole.employee ? 'user-emp-01' : 'user-oa-01',
        name: 'Test User',
        username: 'test.user',
        role: role,
        organizationId: 'org-acme',
      ),
    );
    final access = accessController.accessContext;
    if (access != null) branchController.initFromAccessContext(access);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(
            value: accessController,
          ),
          ChangeNotifierProvider<BranchContextController>.value(
            value: branchController,
          ),
          ChangeNotifierProvider<ReturnsController>.value(
            value: returnsController,
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: home),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('search field is seeded from the controller query', (
    tester,
  ) async {
    returnsController.setSearchQuery('apples');
    await pump(
      tester,
      role: UserRole.employee,
      home: const EmployeeReturnsScreen(),
      width: 390,
      height: 844,
    );

    expect(find.text('apples'), findsOneWidget);
  });

  testWidgets('failed submit keeps the dialog open and shows the error', (
    tester,
  ) async {
    await pump(
      tester,
      role: UserRole.employee,
      home: const EmployeeReturnsScreen(),
    );

    await tester.tap(find.text('Submit Return'));
    await tester.pumpAndSettle();
    expect(find.byType(SubmitReturnDialog), findsOneWidget);
    expect(find.textContaining('OCR'), findsNothing);
    expect(find.textContaining('bill_scan'), findsNothing);

    final fields = find.descendant(
      of: find.byType(SubmitReturnDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Fuji Apples');
    await tester.enterText(fields.at(2), 'INV-1');
    await tester.tap(
      find.descendant(
        of: find.byType(SubmitReturnDialog),
        matching: find.text('Submit Return'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SubmitReturnDialog), findsOneWidget);
    expect(find.byType(ErrorBanner), findsOneWidget);
  });

  testWidgets('failed review keeps the dialog open and shows the error', (
    tester,
  ) async {
    await pump(
      tester,
      role: UserRole.orgAdmin,
      home: const ReturnsOperationsScreen(),
      width: 390,
      height: 844,
    );

    final pending = returnsController.items.firstWhere(
      (i) => i.status == ReturnStatus.pending,
    );
    final card = find.byWidgetPredicate(
      (w) => w is ReturnCardItem && w.item.id == pending.id,
    );
    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(ReturnDetailsDialog), findsOneWidget);
    expect(find.textContaining('OCR'), findsNothing);
    expect(find.textContaining('1.2 MB'), findsNothing);

    await tester.ensureVisible(find.text('Approve Return'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve Return'));
    await tester.pumpAndSettle();

    expect(find.byType(ReturnDetailsDialog), findsOneWidget);
    expect(find.byType(ErrorBanner), findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(768, 1024), Size(1280, 800)]) {
    testWidgets('employee returns render without overflow at ${size.width}', (
      tester,
    ) async {
      await pump(
        tester,
        role: UserRole.employee,
        home: const EmployeeReturnsScreen(),
        width: size.width,
        height: size.height,
      );
      expect(find.text('My Returns'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
