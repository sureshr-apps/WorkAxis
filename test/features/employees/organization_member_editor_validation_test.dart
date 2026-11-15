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
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart';

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

  /// Opens the editor through `showDialog`, as the directory screen does.
  Future<Future<bool?>> openEditor(
    WidgetTester tester, {
    required Future<OrganizationMember?> Function(OrganizationMember) onSave,
    OrganizationMember? member,
  }) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );
    final result = showDialog<bool>(
      context: hostContext,
      barrierDismissible: false,
      builder: (_) => OrganizationMemberEditorDialog(
        access: managerAccess,
        activeBranchId: 'branch-a',
        isSaving: false,
        member: member,
        onSave: (draft, password) => onSave(draft),
      ),
    );
    await tester.pumpAndSettle();
    return result;
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

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final shown = tester.getRect(aadhaar);
    // The field starts inside the visible area (its error line may touch the edge).
    expect(shown.top, greaterThanOrEqualTo(viewport.top));
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
    expect(find.byType(OrganizationMemberEditorDialog), findsOneWidget);
  });

  testWidgets('cannot be dismissed while saving, closes once after success', (
    tester,
  ) async {
    setViewport(tester, const Size(1200, 2400));
    final saving = Completer<OrganizationMember?>();
    final result = await openEditor(
      tester,
      member: _member,
      onSave: (_) => saving.future,
    );
    bool? closedWith;
    var closes = 0;
    unawaited(
      result.then((v) {
        closedWith = v;
        closes++;
      }),
    );

    await tester.tap(find.text('Save changes'));
    await tester.pump();

    // Primary shows progress and both buttons are disabled.
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
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
          .onPressed,
      isNull,
    );

    // System back and a tap on the barrier are both ignored.
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tapAt(const Offset(2, 2));
    // The spinner never settles, so advance time explicitly.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OrganizationMemberEditorDialog), findsOneWidget);
    expect(closes, 0);

    saving.complete(_member);
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationMemberEditorDialog), findsNothing);
    expect(closedWith, isTrue);
    expect(closes, 1);
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

    expect(find.byType(OrganizationMemberEditorDialog), findsOneWidget);
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
