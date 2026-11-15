import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/screens/organization_member_editor_screen.dart';

import '../../helpers/access_controller_fixture.dart';

const _member = OrganizationMember(
  id: 'm-1',
  organizationId: 'org-acme',
  fullName: 'Casey Employee',
  username: 'casey.employee',
  email: '',
  role: UserRole.employee,
  branchIds: ['branch-a'],
  status: AccountStatus.active,
);

void main() {
  late UserAccessContext managerAccess;

  setUp(() async {
    final controller = await resolvedAccessController(
      UserRole.branchManager,
      'user-bm-single-01',
    );
    managerAccess = controller.accessContext!;
    controller.dispose();
  });

  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// Pumps the editor as its routed page. The returned counts record how many
  /// times the page reported a save ('saved') or a close request ('closed').
  Future<Map<String, int>> openEditor(
    WidgetTester tester, {
    required Future<OrganizationMember?> Function(OrganizationMember) onSave,
    OrganizationMember? member,
  }) async {
    final outcome = {'saved': 0, 'closed': 0};
    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationMemberEditorScreen(
          access: managerAccess,
          activeBranchId: 'branch-a',
          isSaving: false,
          member: member,
          onSave: (draft, password) => onSave(draft),
          onClose: () {
            outcome['closed'] = outcome['closed']! + 1;
          },
          onSaved: () {
            outcome['saved'] = outcome['saved']! + 1;
          },
          backLabel: 'Employee Directory',
        ),
      ),
    );
    await tester.pumpAndSettle();
    return outcome;
  }

  Finder fieldWithError(String label, String error) => find.descendant(
    of: find.widgetWithText(AppTextField, label),
    matching: find.text(error),
  );

  Future<void> fillIdentity(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Full Name *'),
      'Jane Employee',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Sign-in Username *'),
      'jane.employee',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(AppPasswordField),
        matching: find.byType(TextField),
      ),
      'Password123!',
    );
  }

  testWidgets('field errors appear inline under their own fields, no banner', (
    tester,
  ) async {
    setViewport(tester, const Size(1200, 2400));
    await openEditor(tester, onSave: (d) async => d);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      fieldWithError('Full Name *', 'Enter the full name.'),
      findsOneWidget,
    );
    expect(
      fieldWithError('Aadhaar Number *', 'Enter the 12-digit Aadhaar number.'),
      findsOneWidget,
    );
    expect(
      fieldWithError('Designation *', 'Enter the employee designation.'),
      findsOneWidget,
    );
    expect(
      fieldWithError('Monthly Salary *', 'Enter the monthly salary.'),
      findsOneWidget,
    );
    expect(
      find.text('Attach the Aadhaar card document photo.'),
      findsOneWidget,
    );
    expect(find.byType(ErrorBanner), findsNothing);
  });

  testWidgets('typed data survives a failed validation', (tester) async {
    setViewport(tester, const Size(1200, 2400));
    await openEditor(tester, onSave: (d) async => d);
    await fillIdentity(tester);
    await tester.enterText(
      find.widgetWithText(AppTextField, 'Aadhaar Number *'),
      '12345',
    );

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      fieldWithError(
        'Aadhaar Number *',
        'Aadhaar number must be exactly 12 digits.',
      ),
      findsOneWidget,
    );
    final name = tester.widget<AppTextField>(
      find.widgetWithText(AppTextField, 'Full Name *'),
    );
    expect(name.controller!.text, 'Jane Employee');
  });

  testWidgets('the first invalid field is scrolled into view', (tester) async {
    setViewport(tester, const Size(1200, 700));
    await openEditor(tester, onSave: (d) async => d);
    await fillIdentity(tester);

    final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
    final aadhaar = find.widgetWithText(AppTextField, 'Aadhaar Number *');
    expect(
      tester.getRect(aadhaar).top,
      greaterThan(viewport.bottom),
      reason: 'precondition: the Aadhaar field starts below the fold',
    );

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final shown = tester.getRect(aadhaar);
    // The field is on screen: focusing it may leave its top just past the edge.
    expect(shown.bottom, greaterThan(viewport.top));
    expect(shown.top, lessThan(viewport.bottom - 40));
  });

  testWidgets('shows only server failures in the banner', (tester) async {
    setViewport(tester, const Size(1200, 2400));
    await openEditor(tester, member: _member, onSave: (_) async => null);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('The account could not be saved. Try again.'),
      findsOneWidget,
    );
    expect(find.byType(OrganizationMemberEditorScreen), findsOneWidget);
  });

  testWidgets('cannot be left while saving, reports the save once', (
    tester,
  ) async {
    setViewport(tester, const Size(1200, 2400));
    final saving = Completer<OrganizationMember?>();
    final outcome = await openEditor(
      tester,
      member: _member,
      onSave: (_) => saving.future,
    );

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    // Primary shows progress and Cancel is disabled.
    final primary = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Save changes'),
    );
    expect(primary.isLoading, isTrue);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Cancel'))
          .onPressed,
      isNull,
    );

    // System back is ignored while the save is in flight.
    await tester.binding.handlePopRoute();
    // The spinner never settles, so advance time explicitly.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OrganizationMemberEditorScreen), findsOneWidget);
    expect(outcome['saved'], 0);

    saving.complete(_member);
    await tester.pumpAndSettle();

    expect(outcome['saved'], 1);
    expect(outcome['closed'], 0);
  });

  testWidgets('stays open with data intact when the save fails', (
    tester,
  ) async {
    setViewport(tester, const Size(1200, 2400));
    final saving = Completer<OrganizationMember?>();
    await openEditor(tester, member: _member, onSave: (_) => saving.future);

    await tester.enterText(
      find.widgetWithText(AppTextField, 'Full Name *'),
      'Changed Name',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    saving.complete(null);
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationMemberEditorScreen), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Cancel'))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<AppTextField>(
            find.widgetWithText(AppTextField, 'Full Name *'),
          )
          .controller!
          .text,
      'Changed Name',
    );
  });
}
