import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/assets/data/mock_assets_repository.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/presentation/widgets/asset_editor_dialog.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

import '../../helpers/access_fixtures.dart';

// Seed data: user-emp-04 (Daniel Kim) is suspended in br-04 and holds the
// returned asset-005.
const _suspendedId = 'user-emp-04';

void main() {
  group('assigning assets to inactive members', () {
    late MockAssetsRepository repository;

    setUp(() {
      repository = MockAssetsRepository(
        members: MockOrganizationMembersRepository(),
      );
    });

    Future<EmployeeAsset> heldBySuspended() async {
      final page = await repository.getAssetsPage(
        access: orgAdminAccess(),
        queue: AssetQueue.organization,
        limit: 100,
      );
      return page.items.singleWhere((a) => a.employeeId == _suspendedId);
    }

    test('a new asset cannot be handed to a suspended member', () async {
      final template = await heldBySuspended();
      final draft = EmployeeAsset(
        id: '',
        organizationId: template.organizationId,
        branchId: template.branchId,
        branchName: template.branchName,
        employeeId: _suspendedId,
        employeeName: template.employeeName,
        name: 'Tablet',
        category: 'Device',
        assetTag: 'WA-NEW-1',
        status: AssetStatus.assigned,
        acknowledgementRequired: false,
        acknowledgementStatus: AssetAcknowledgementStatus.notRequired,
      );
      await expectLater(
        repository.saveAsset(access: orgAdminAccess(), asset: draft),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'a returned asset cannot be re-issued to a suspended member',
      () async {
        final returned = await heldBySuspended();
        expect(returned.status, AssetStatus.returned);
        await expectLater(
          repository.saveAsset(
            access: orgAdminAccess(),
            asset: returned.copyWith(status: AssetStatus.assigned),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('a suspended member\'s asset can still be edited', () async {
      final returned = await heldBySuspended();
      final saved = await repository.saveAsset(
        access: orgAdminAccess(),
        asset: returned,
      );
      expect(saved.employeeId, _suspendedId);
    });
  });

  group('AssetEditorDialog assignee choices', () {
    OrganizationMember member(String id, String name, AccountStatus status) =>
        OrganizationMember(
          id: id,
          authUid: id,
          organizationId: 'org-acme',
          fullName: name,
          username: id,
          email: '$id@example.com',
          role: UserRole.employee,
          branchIds: const ['br-01'],
          status: status,
        );

    final active = member('m-active', 'Active Ann', AccountStatus.active);
    final suspended = member(
      'm-susp',
      'Suspended Sam',
      AccountStatus.suspended,
    );

    Future<void> pumpDialog(WidgetTester tester, {EmployeeAsset? asset}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AssetEditorDialog(
              organizationId: 'org-acme',
              branches: [acmeBranch('br-01')],
              employees: [active, suspended],
              asset: asset,
              fixedBranchId: 'br-01',
              onSave: (_) async => true,
              actionErrorMessage: () => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Opens the assignee menu and returns the names it offers.
    Future<List<String>> choices(WidgetTester tester) async {
      final field = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();
      final menu = find.byType(DropdownMenuItem<String>);
      return [
        for (final name in ['Active Ann', 'Suspended Sam'])
          if (find
              .descendant(of: menu, matching: find.text(name))
              .evaluate()
              .isNotEmpty)
            name,
      ];
    }

    testWidgets('a new asset lists only active members', (tester) async {
      await pumpDialog(tester);
      expect(await choices(tester), ['Active Ann']);
    });

    testWidgets('editing keeps a suspended holder selected', (tester) async {
      await pumpDialog(
        tester,
        asset: EmployeeAsset(
          id: 'asset-9',
          organizationId: 'org-acme',
          branchId: 'br-01',
          branchName: 'Downtown Flagship',
          employeeId: suspended.id,
          employeeName: suspended.fullName,
          name: 'Work phone',
          category: 'Device',
          assetTag: 'WA-009',
          status: AssetStatus.assigned,
          acknowledgementRequired: false,
          acknowledgementStatus: AssetAcknowledgementStatus.notRequired,
        ),
      );
      expect(await choices(tester), ['Active Ann', 'Suspended Sam']);
    });
  });
}
