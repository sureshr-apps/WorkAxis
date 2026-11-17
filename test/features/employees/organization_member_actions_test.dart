import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_card.dart';

import '../../helpers/access_fixtures.dart';

OrganizationMember _employee({
  String id = 'm-1',
  AccountStatus status = AccountStatus.active,
}) => OrganizationMember(
  id: id,
  organizationId: acmeOrg.id,
  fullName: 'Casey Employee',
  username: 'casey.employee',
  email: '',
  role: UserRole.employee,
  branchIds: const ['br-01'],
  status: status,
);

Future<void> _pumpCard(
  WidgetTester tester,
  OrganizationMember member, {
  VoidCallback? onEdit,
  VoidCallback? onResetPassword,
  VoidCallback? onToggleStatus,
  VoidCallback? onDelete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OrganizationMemberCard(
            member: member,
            branchNames: const ['Downtown'],
            onOpen: () {},
            onEdit: onEdit,
            onResetPassword: onResetPassword,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'employee card offers Edit, Reset Password, Suspend and Delete like platform users',
    (tester) async {
      final calls = <String>[];
      await _pumpCard(
        tester,
        _employee(),
        onEdit: () => calls.add('edit'),
        onResetPassword: () => calls.add('reset'),
        onToggleStatus: () => calls.add('toggle'),
        onDelete: () => calls.add('delete'),
      );

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Suspend'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Reset Password'));
      await tester.tap(find.text('Suspend'));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(calls, ['reset', 'toggle', 'delete']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a suspended employee is offered Restore instead of Suspend', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _employee(status: AccountStatus.suspended),
      onToggleStatus: () {},
    );

    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
  });

  testWidgets('actions the caller may not perform are hidden', (tester) async {
    await _pumpCard(tester, _employee());

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Reset Password'), findsNothing);
    expect(find.text('Suspend'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Casey Employee'), findsOneWidget);
  });

  group('OrganizationMemberPolicy.assertCanDelete', () {
    test(
      'an organization admin may delete another member of the organization',
      () {
        expect(
          () => OrganizationMemberPolicy.assertCanDelete(
            access: orgAdminAccess(),
            existing: _employee(),
          ),
          returnsNormally,
        );
      },
    );

    test('nobody deletes their own account', () {
      final access = orgAdminAccess();
      expect(
        () => OrganizationMemberPolicy.assertCanDelete(
          access: access,
          existing: _employee(id: access.user.id),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
