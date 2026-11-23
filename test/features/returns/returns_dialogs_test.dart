import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
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
import 'package:workaxis/features/returns/presentation/screens/return_details_route.dart';
import 'package:workaxis/features/returns/presentation/screens/return_details_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/returns_operations_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/submit_return_route.dart';
import 'package:workaxis/features/returns/presentation/screens/submit_return_screen.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_card_item.dart';

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
  Future<List<ReturnItem>> submitReturnBatch({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnBatchInput input,
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

/// The returns routes for one list, as the app nests them: the list, then the
/// record page and the details page under it.
GoRouter _returnsRouter({
  required String listRoute,
  required String listLabel,
  required Widget list,
}) {
  return GoRouter(
    initialLocation: listRoute,
    routes: [
      GoRoute(
        path: listRoute,
        builder: (context, state) => list,
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) =>
                SubmitReturnRoute(listRoute: listRoute, listLabel: listLabel),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => ReturnDetailsRoute(
              returnId: state.pathParameters['id'] ?? '',
              listRoute: listRoute,
              listLabel: listLabel,
            ),
          ),
        ],
      ),
    ],
  );
}

GoRouter _employeeRouter() => _returnsRouter(
  listRoute: AppRoutes.employeeReturns,
  listLabel: 'My Returns',
  list: const EmployeeReturnsScreen(),
);

GoRouter _orgRouter() => _returnsRouter(
  listRoute: AppRoutes.orgAdminReturns,
  listLabel: 'Organization Returns',
  list: const ReturnsOperationsScreen(),
);

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
    required GoRouter router,
    String? userId,
    double width = 1200,
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    addTearDown(router.dispose);
    await accessController.resolveAccess(
      AppUser(
        id:
            userId ??
            (role == UserRole.employee ? 'user-emp-01' : 'user-oa-01'),
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
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Taps the breadcrumb back link of the page currently shown.
  Future<void> tapBreadcrumb(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(PageBreadcrumb),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls to the card of the first pending return and opens it.
  Future<void> openPendingReturn(WidgetTester tester) async {
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
  }

  testWidgets('search field is seeded from the controller query', (
    tester,
  ) async {
    returnsController.setSearchQuery('apples');
    await pump(
      tester,
      role: UserRole.employee,
      router: _employeeRouter(),
      width: 390,
      height: 844,
    );

    expect(find.text('apples'), findsOneWidget);
  });

  testWidgets(
    'submit opens the record page and the breadcrumb returns to the list',
    (tester) async {
      await pump(tester, role: UserRole.employee, router: _employeeRouter());

      await tester.tap(find.text('Submit Return'));
      await tester.pumpAndSettle();
      expect(find.byType(SubmitReturnScreen), findsOneWidget);

      await tapBreadcrumb(tester);

      expect(find.byType(SubmitReturnScreen), findsNothing);
      expect(find.byType(EmployeeReturnsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'a multi-branch manager files returns only for the active branch',
    (tester) async {
      final router = _returnsRouter(
        listRoute: AppRoutes.branchManagerReturns,
        listLabel: 'Branch Returns',
        list: const SizedBox.shrink(),
      );
      await pump(
        tester,
        role: UserRole.branchManager,
        userId: 'user-bm-multi-01',
        router: router,
      );
      final access = accessController.accessContext!;
      expect(access.hasMultipleAssignedBranches, isTrue);
      // The manager picks their second branch on the branch selection screen.
      final active = access.activeAssignedBranches.last.id;
      expect(
        branchController.selectBranch(access.activeAssignedBranches.last),
        isTrue,
      );
      router.go('${AppRoutes.branchManagerReturns}/add');
      await tester.pumpAndSettle();

      final screen = tester.widget<SubmitReturnScreen>(
        find.byType(SubmitReturnScreen),
      );
      expect(screen.availableBranches.map((b) => b.id), [active]);
    },
  );

  testWidgets('failed submit keeps the record page open and shows the error', (
    tester,
  ) async {
    await pump(tester, role: UserRole.employee, router: _employeeRouter());

    await tester.tap(find.text('Submit Return'));
    await tester.pumpAndSettle();
    expect(find.byType(SubmitReturnScreen), findsOneWidget);
    expect(find.textContaining('OCR'), findsNothing);
    expect(find.textContaining('bill_scan'), findsNothing);

    final fields = find.descendant(
      of: find.byType(SubmitReturnScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Fuji Apples');
    await tester.enterText(fields.at(2), 'INV-1');
    final submitBtn = find.descendant(
      of: find.byType(SubmitReturnScreen),
      matching: find.text('Submit Return'),
    );
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.byType(SubmitReturnScreen), findsOneWidget);
    expect(find.byType(ErrorBanner), findsOneWidget);
  });

  testWidgets(
    'a return opens its details page and the breadcrumb returns to the list',
    (tester) async {
      await pump(
        tester,
        role: UserRole.orgAdmin,
        router: _orgRouter(),
        width: 390,
        height: 844,
      );

      await openPendingReturn(tester);
      expect(find.byType(ReturnDetailsScreen), findsOneWidget);
      expect(find.text('Organization Returns'), findsWidgets);

      await tapBreadcrumb(tester);

      expect(find.byType(ReturnDetailsScreen), findsNothing);
      expect(find.byType(ReturnsOperationsScreen), findsOneWidget);
    },
  );

  testWidgets('failed review keeps the details page open and shows the error', (
    tester,
  ) async {
    await pump(
      tester,
      role: UserRole.orgAdmin,
      router: _orgRouter(),
      width: 390,
      height: 844,
    );

    await openPendingReturn(tester);
    expect(find.byType(ReturnDetailsScreen), findsOneWidget);
    expect(find.textContaining('OCR'), findsNothing);
    expect(find.textContaining('1.2 MB'), findsNothing);

    await tester.ensureVisible(find.text('Approve Return'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve Return'));
    await tester.pumpAndSettle();

    expect(find.byType(ReturnDetailsScreen), findsOneWidget);
    expect(find.byType(ErrorBanner), findsOneWidget);
  });

  testWidgets(
    'an approved return closes the details page, refreshes the list and confirms',
    (tester) async {
      returnsController.dispose();
      returnsController = ReturnsController(
        repository: MockReturnsRepository(now: fixedNow, delay: Duration.zero),
      );
      await pump(
        tester,
        role: UserRole.orgAdmin,
        router: _orgRouter(),
        width: 390,
        height: 844,
      );
      final pending = returnsController.items.firstWhere(
        (i) => i.status == ReturnStatus.pending,
      );

      await openPendingReturn(tester);
      await tester.ensureVisible(find.text('Approve Return'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve Return'));
      await tester.pumpAndSettle();

      expect(find.byType(ReturnDetailsScreen), findsNothing);
      expect(find.byType(ReturnsOperationsScreen), findsOneWidget);
      expect(
        find.text('Return request #${pending.id} approved.'),
        findsOneWidget,
      );
      expect(
        returnsController.items.firstWhere((i) => i.id == pending.id).status,
        ReturnStatus.approved,
      );
    },
  );

  for (final size in const [Size(390, 844), Size(768, 1024), Size(1280, 800)]) {
    testWidgets('employee returns render without overflow at ${size.width}', (
      tester,
    ) async {
      await pump(
        tester,
        role: UserRole.employee,
        router: _employeeRouter(),
        width: size.width,
        height: size.height,
      );
      expect(find.text('My Returns'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
