import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leave_policy/data/mock_leave_policy_repository.dart';
import 'package:workaxis/features/leave_policy/presentation/controllers/leave_policy_controller.dart';
import 'package:workaxis/features/leave_policy/presentation/widgets/leave_policy_section.dart';
import 'package:workaxis/features/leave_policy/presentation/widgets/leave_type_editor_dialog.dart';

const _orgAdmin = AppUser(
  id: 'user-oa-01',
  name: 'Jordan Lee',
  username: 'jordan.lee',
  role: UserRole.orgAdmin,
  organizationId: 'org-acme',
);

const _branchManager = AppUser(
  id: 'user-bm-01',
  name: 'Marcus Chen',
  username: 'marcus.chen',
  role: UserRole.branchManager,
  organizationId: 'org-acme',
);

void main() {
  late AccessController accessController;
  late LeavePolicyController leavePolicyController;

  setUp(() {
    accessController = AccessController(
      accessRepository: MockAccessRepository(
        dataSource: MockAccessDataSource(),
        delay: Duration.zero,
      ),
    );
    leavePolicyController = LeavePolicyController(
      repository: MockLeavePolicyRepository(delay: Duration.zero),
    );
  });

  tearDown(() {
    accessController.dispose();
    leavePolicyController.dispose();
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    AppUser user = _orgAdmin,
    double width = 1200,
    double height = 1400,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await accessController.resolveAccess(user);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(
            value: accessController,
          ),
          ChangeNotifierProvider<LeavePolicyController>.value(
            value: leavePolicyController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: LeavePolicySection(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder switchTitled(String title) => find.byWidgetPredicate(
    (widget) =>
        widget is SwitchListTile && (widget.title as Text?)?.data == title,
  );

  testWidgets('lists leave types with their allowance', (tester) async {
    await pumpSection(tester);

    expect(find.text('Leave Policy'), findsOneWidget);
    expect(find.text('Annual leave'), findsOneWidget);
    expect(find.text('12 days / year · Carries forward'), findsOneWidget);
    expect(find.text('6 days / year'), findsOneWidget);
    expect(find.text('2 days / year'), findsOneWidget);
    expect(find.text('No allowance · always unpaid'), findsOneWidget);
    expect(find.byTooltip('Remove Sick leave'), findsOneWidget);
    expect(find.byTooltip('Remove Unpaid leave'), findsNothing);
    expect(find.byTooltip('Edit Unpaid leave'), findsOneWidget);
    expect(switchTitled('Accrue leave monthly'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a paid type saves its new allowance', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.byTooltip('Edit Sick leave'));
    await tester.pumpAndSettle();

    expect(find.text('Edit leave type'), findsOneWidget);
    expect(find.byKey(LeaveTypeEditorDialog.daysFieldKey), findsOneWidget);
    expect(find.byKey(LeaveTypeEditorDialog.carryForwardKey), findsOneWidget);
    expect(
      find.text(
        'A new allowance applies from the next month. Earlier months and past payroll are not affected.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(LeaveTypeEditorDialog.daysFieldKey),
        matching: find.byType(EditableText),
      ),
      '7.5',
    );
    await tester.tap(find.byKey(LeaveTypeEditorDialog.carryForwardKey));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit leave type'), findsNothing);
    expect(find.text('7.5 days / year · Carries forward'), findsOneWidget);
  });

  testWidgets('a duplicate name keeps the editor open with the message', (
    tester,
  ) async {
    await pumpSection(tester);

    await tester.tap(find.text('Add leave type'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(LeaveTypeEditorDialog.nameFieldKey),
        matching: find.byType(EditableText),
      ),
      'annual leave',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(LeaveTypeEditorDialog.daysFieldKey),
        matching: find.byType(EditableText),
      ),
      '3',
    );
    await tester.tap(find.text('Create leave type'));
    await tester.pumpAndSettle();

    expect(find.text(MockLeavePolicyRepository.nameInUse), findsOneWidget);
    expect(find.byType(LeaveTypeEditorDialog), findsOneWidget);
  });

  testWidgets('the unpaid type edits its name only', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.byTooltip('Edit Unpaid leave'));
    await tester.pumpAndSettle();

    expect(find.byKey(LeaveTypeEditorDialog.nameFieldKey), findsOneWidget);
    expect(find.byKey(LeaveTypeEditorDialog.daysFieldKey), findsNothing);
    expect(find.byKey(LeaveTypeEditorDialog.carryForwardKey), findsNothing);
    expect(
      find.textContaining('Unpaid leave has no allowance'),
      findsOneWidget,
    );
  });

  testWidgets('removing a type asks for confirmation', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.byTooltip('Remove Personal leave'));
    await tester.pumpAndSettle();
    expect(find.text('Remove leave type?'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Personal leave'), findsNothing);
    expect(find.text('Annual leave'), findsOneWidget);
  });

  testWidgets('turning on monthly accrual saves it', (tester) async {
    await pumpSection(tester);

    await tester.tap(switchTitled('Accrue leave monthly'));
    await tester.pumpAndSettle();

    expect(leavePolicyController.policy!.monthlyAccrual, isTrue);
    expect(
      tester.widget<SwitchListTile>(switchTitled('Accrue leave monthly')).value,
      isTrue,
    );
  });

  testWidgets('fits a phone width', (tester) async {
    await pumpSection(tester, width: 360, height: 1600);

    expect(find.text('Add leave type'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Edit Annual leave'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('is hidden from other roles', (tester) async {
    await pumpSection(tester, user: _branchManager);

    expect(find.text('Leave Policy'), findsNothing);
    expect(leavePolicyController.status, LeavePolicyLoadStatus.initial);
  });
}
