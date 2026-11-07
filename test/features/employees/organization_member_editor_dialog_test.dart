import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_card.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart';

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

  setUp(() async {
    final controller = await resolvedAccessController(
      UserRole.branchManager,
      'user-bm-single-01',
    );
    managerAccess = controller.accessContext!;
    controller.dispose();
  });

  Future<List<OrganizationMember>> pumpEditor(
    WidgetTester tester, {
    required Future<OrganizationMember?> Function(OrganizationMember) onSave,
    String? Function()? saveError,
    OrganizationMember member = _member,
  }) async {
    final saved = <OrganizationMember>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationMemberEditorDialog(
            access: managerAccess,
            activeBranchId: 'branch-a',
            isSaving: false,
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
    expect(find.byType(OrganizationMemberEditorDialog), findsOneWidget);
  });

  testWidgets('rejects a malformed email without saving', (tester) async {
    final saved = await pumpEditor(tester, onSave: (draft) async => draft);

    await tester.enterText(find.byType(TextField).at(2), 'not-an-email');
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(saved, isEmpty);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
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
            onView: () {},
            onEdit: null,
          ),
        ),
      ),
    );

    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
  });
}
