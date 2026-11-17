import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_card.dart';
import 'package:workaxis/features/employees/presentation/screens/organization_member_editor_screen.dart';

import '../../helpers/access_controller_fixture.dart';

const _member = OrganizationMember(
  id: 'm-1',
  organizationId: 'org-acme',
  fullName: 'Casey Employee',
  username: 'casey.employee',
  email: '',
  role: UserRole.employee,
  branchIds: ['branch-a', 'branch-b'],
  status: AccountStatus.active,
);

void main() {
  late UserAccessContext managerAccess;
  late UserAccessContext adminAccess;

  setUp(() async {
    final controller = await resolvedAccessController(
      UserRole.branchManager,
      'user-bm-single-01',
    );
    managerAccess = controller.accessContext!;
    controller.dispose();

    final aController = await resolvedAccessController(
      UserRole.orgAdmin,
      'user-oa-01',
    );
    adminAccess = aController.accessContext!;
    aController.dispose();
  });

  Future<List<OrganizationMember>> pumpEditor(
    WidgetTester tester, {
    required Future<OrganizationMember?> Function(OrganizationMember) onSave,
    String? Function()? saveError,
    OrganizationMember? member = _member,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final saved = <OrganizationMember>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationMemberEditorScreen(
            access: managerAccess,
            activeBranchId: 'branch-a',
            isSaving: false,
            onClose: () {},
            onSaved: () {},
            backLabel: 'Employee Directory',
            member: member,
            saveErrorMessage: saveError,
            onSave: (draft, password) {
              saved.add(draft);
              return onSave(draft);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return saved;
  }

  testWidgets('editing preserves role and other branch assignments', (
    tester,
  ) async {
    final saved = await pumpEditor(tester, onSave: (draft) async => draft);

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single.role, UserRole.employee);
    expect(saved.single.branchIds, ['branch-a', 'branch-b']);
    expect(saved.single.email, isEmpty, reason: 'email is optional');
  });

  testWidgets('shows the controller failure and keeps the dialog open', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      onSave: (_) async => null,
      saveError: () => 'You can only manage employees in your active branch.',
    );

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('You can only manage employees in your active branch.'),
      findsOneWidget,
    );
    expect(find.byType(OrganizationMemberEditorScreen), findsOneWidget);
  });

  testWidgets('rejects a malformed email without saving', (tester) async {
    final saved = await pumpEditor(tester, onSave: (draft) async => draft);

    await tester.enterText(
      find.widgetWithText(AppTextField, 'Email address (optional)'),
      'not-an-email',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isEmpty);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('submits configured daily work hours and shift window on save', (
    tester,
  ) async {
    final saved = await pumpEditor(tester, onSave: (draft) async => draft);

    // Tap preset '6 hrs'
    await tester.tap(find.text('6 hrs'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single.dailyWorkHours, 6.0);
    expect(saved.single.shiftHours, '09:00 AM - 03:00 PM');
  });

  testWidgets('submits rich employee profile fields on save', (tester) async {
    final saved = await pumpEditor(tester, onSave: (draft) async => draft);

    await tester.enterText(
      find.widgetWithText(AppTextField, 'Designation'),
      'Senior Fruit Associate',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Monthly Salary'),
      '32000',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Aadhaar Number'),
      '123456789012',
    );

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single.designation, 'Senior Fruit Associate');
    expect(saved.single.salary, 32000.0);
    expect(saved.single.aadhaarNumber, '123456789012');
    // No ID is fabricated client-side; the stored one (none here) is kept.
    expect(saved.single.employeeCode, isNull);
  });

  testWidgets('new employee ID is optional and starts blank with no default', (
    tester,
  ) async {
    await pumpEditor(tester, onSave: (draft) async => draft, member: null);

    expect(find.text('Leave blank to auto-assign'), findsOneWidget);
    expect(find.text('EMP-10001'), findsNothing);
    final field = tester.widget<AppTextField>(
      find.widgetWithText(AppTextField, 'Employee ID'),
    );
    expect(field.controller!.text, isEmpty);
    expect(field.enabled, isTrue);
  });

  testWidgets('editing shows the stored employee ID read-only and keeps it', (
    tester,
  ) async {
    final saved = await pumpEditor(
      tester,
      onSave: (draft) async => draft,
      member: _member.copyWith(employeeCode: 'EMP-10042'),
    );

    expect(find.text('Leave blank to auto-assign'), findsNothing);
    final field = tester.widget<AppTextField>(
      find.widgetWithText(AppTextField, 'Employee ID'),
    );
    expect(field.controller!.text, 'EMP-10042');
    expect(field.enabled, isFalse);

    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(saved.single.employeeCode, 'EMP-10042');
  });

  testWidgets('member card hides Edit when the caller cannot manage it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationMemberCard(
            member: _member,
            branchNames: const ['Downtown'],
            onOpen: () {},
            onEdit: null,
          ),
        ),
      ),
    );

    expect(find.text('Branches: Downtown'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets(
    'member card shows Edit when allowed and opens the account on tap',
    (tester) async {
      var opened = 0;
      var edited = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrganizationMemberCard(
              member: _member,
              branchNames: const ['Downtown'],
              onOpen: () => opened++,
              onEdit: () => edited++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit'));
      expect(edited, 1);
      await tester.tap(find.text(_member.fullName));
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('branch manager role field is disabled and locked to Employee', (
    tester,
  ) async {
    await pumpEditor(tester, onSave: (draft) async => draft, member: null);

    expect(find.text('Role'), findsOneWidget);
    expect(
      find.text('Branch managers can only add employees.'),
      findsOneWidget,
    );
    expect(find.text('Employee'), findsWidgets);

    // Verify the dropdown is disabled (tapping does not open menu)
    await tester.tap(find.text('Employee').first);
    await tester.pumpAndSettle();
    expect(find.text('Organization Admin'), findsNothing);
    expect(find.text('Branch Manager'), findsNothing);
  });

  testWidgets(
    'org admin can select Org Admin, Branch Manager, or Employee but not Platform Admin',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrganizationMemberEditorScreen(
              access: adminAccess,
              activeBranchId: null,
              isSaving: false,
              onClose: () {},
              onSaved: () {},
              backLabel: 'Employee Directory',
              member: null,
              onSave: (draft, password) async => draft,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows Employee role
      expect(
        find.widgetWithText(DropdownButtonFormField<UserRole>, 'Employee'),
        findsOneWidget,
      );

      // Open the Role dropdown
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<UserRole>, 'Employee'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organization Admin'), findsWidgets);
      expect(find.text('Branch Manager'), findsWidgets);
      expect(find.text('Employee'), findsWidgets);
      expect(find.text('Platform Administrator'), findsNothing);
      expect(find.text('Platform Owner'), findsNothing);

      // Select Organization Admin
      await tester.tap(find.text('Organization Admin').last);
      await tester.pumpAndSettle();

      // Check that organization-wide message is displayed and branch checkboxes are hidden
      expect(
        find.text(
          'Organization Administrators have organization-wide access across all branches.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
    },
  );

  testWidgets(
    'creating employee shows mandatory asterisks for aadhaar, photo, designation, salary',
    (tester) async {
      await pumpEditor(tester, onSave: (draft) async => draft, member: null);

      expect(find.text('Aadhaar Number *'), findsOneWidget);
      expect(find.text('Aadhaar Card Document Photo *'), findsOneWidget);
      expect(find.text('Designation *'), findsOneWidget);
      expect(find.text('Monthly Salary *'), findsOneWidget);
      // Mobile number and profile photo are optional, so carry no marker.
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Mobile Number *'), findsNothing);
    },
  );

  testWidgets(
    'creating employee enforces mandatory aadhaar, photo, designation, salary',
    (tester) async {
      final saved = await pumpEditor(
        tester,
        onSave: (draft) async => draft,
        member: null,
      );

      // Fill name, username, phone, password
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Full Name *'),
        'Jane Employee',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Sign-in Username *'),
        'jane.employee',
      );
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Mobile Number'),
        '+91 98765 43210',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AppPasswordField),
          matching: find.byType(TextField),
        ),
        'Password123!',
      );

      // 1. Try to save without Aadhaar
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter the 12-digit Aadhaar number.'), findsOneWidget);
      expect(saved, isEmpty);

      // 2. Try to save with invalid Aadhaar
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Aadhaar Number *'),
        '12345',
      );
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(
        find.text('Aadhaar number must be exactly 12 digits.'),
        findsOneWidget,
      );
      expect(saved, isEmpty);

      // 3. Enter valid Aadhaar, try to save without photo
      await tester.enterText(
        find.widgetWithText(AppTextField, 'Aadhaar Number *'),
        '1234 5678 9012',
      );
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(
        find.text('Attach the Aadhaar card document photo.'),
        findsOneWidget,
      );
      expect(saved, isEmpty);
    },
  );
}
