import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';

import '../../helpers/session_fakes.dart';

class _RecordingMembersRepository implements OrganizationMembersRepository {
  final List<String?> queries = [];

  @override
  Future<PageResult<OrganizationMember>> getMembersPage({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
    AccountStatus? status,
    UserRole? role,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    queries.add(query);
    return const PageResult.empty();
  }

  @override
  Future<OrganizationMember> setMemberStatus({
    required UserAccessContext access,
    required OrganizationMember member,
    required AccountStatus status,
    String? activeBranchId,
  }) => throw UnimplementedError();

  @override
  Future<void> resetMemberPassword({
    required UserAccessContext access,
    required OrganizationMember member,
    required String newPassword,
    String? activeBranchId,
  }) => throw UnimplementedError();

  @override
  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async => null;

  @override
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) => throw UnimplementedError();
}

void main() {
  final access = UserAccessContext(user: testUser(UserRole.orgAdmin));

  testWidgets('typing is debounced into a single backend search', (
    tester,
  ) async {
    final repository = _RecordingMembersRepository();
    final controller = OrganizationMembersController(repository: repository);
    addTearDown(controller.dispose);

    for (final text in ['a', 'al', 'ali', 'alic', 'alice']) {
      unawaited(controller.setQuery(access: access, query: text));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repository.queries, isEmpty);
    expect(controller.query, 'alice');
    expect(controller.searchQuery, 'alice');

    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.queries, ['alice']);
  });

  testWidgets('reset cancels a pending search and clears the query', (
    tester,
  ) async {
    final repository = _RecordingMembersRepository();
    final controller = OrganizationMembersController(repository: repository);
    addTearDown(controller.dispose);

    unawaited(controller.setQuery(access: access, query: 'bob'));
    controller.reset();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.queries, isEmpty);
    expect(controller.query, isEmpty);
  });

  test('a zero debounce loads immediately', () async {
    final repository = _RecordingMembersRepository();
    final controller = OrganizationMembersController(
      repository: repository,
      searchDebounce: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.setQuery(access: access, query: 'x');

    expect(repository.queries, ['x']);
  });
}
