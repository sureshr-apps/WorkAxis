import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_assignment_dialog.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fallback_maps.dart';

class _EmptyMembersRepository implements OrganizationMembersRepository {
  @override
  Future<PageResult<OrganizationMember>> getMembersPage({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
    AccountStatus? status,
    UserRole? role,
    int offset = 0,
    int limit = defaultPageSize,
  }) async => const PageResult.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('assignment form selects a destination from the map', (
    tester,
  ) async {
    final access = orgAdminAccess();
    final branchId = access.assignedBranches.first.id;
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        builder: fallbackMapsBuilder,
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showOffSiteWorkAssignmentDialog(
                context: context,
                access: access,
                activeBranchId: branchId,
                membersRepository: _EmptyMembersRepository(),
                onSubmit: (_) async {
                  submitted = true;
                  return true;
                },
                failureMessage: () => null,
              );
            });
            return const Scaffold();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select destination on map'), findsOneWidget);
    expect(find.text('Destination'), findsNothing);
    final chooseLocation = find.byKey(const Key('test_select_location_btn'));
    await tester.ensureVisible(chooseLocation);
    await tester.tap(chooseLocation);
    await tester.pumpAndSettle();

    expect(find.text('12.9716, 77.5946'), findsOneWidget);
    expect(submitted, isFalse);
  });
}
