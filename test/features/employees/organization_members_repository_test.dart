import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

import '../../contracts/acme_scenario.dart';
import '../../contracts/organization_members_contract.dart';
import '../../helpers/fake_identity_server.dart';

void main() {
  runOrganizationMembersContract(
    'mock',
    () => MockOrganizationMembersRepository(
      accessDataSource: MockAccessDataSource(),
    ),
  );

  runOrganizationMembersContract('SQL Connect with fakes', () {
    final server = FakeIdentityServer(acmeMemberSeed());
    return SqlConnectOrganizationMembersRepository(
      dataSource: FakeMembersDataSource(server),
      accounts: AccountCallables(server),
    );
  });

  group('SqlConnectOrganizationMembersRepository specifics', () {
    late FakeIdentityServer server;
    late SqlConnectOrganizationMembersRepository repo;

    setUp(() {
      server = FakeIdentityServer(acmeMemberSeed());
      repo = SqlConnectOrganizationMembersRepository(
        dataSource: FakeMembersDataSource(server),
        accounts: AccountCallables(server),
      );
    });

    test('create goes through provisionUser with an idempotency key', () async {
      await repo.saveMember(
        access: orgAdminAccess(),
        member: memberDraft(email: 'new@example.com', phone: '+91 98765 43210'),
        initialPassword: 'Str0ng-Pass!',
      );
      final call = server.callsTo('provisionUser').single;
      expect(call.payload['requestId'], hasLength(36));
      expect(call.payload['role'], 'employee');
      expect(call.payload['organizationId'], 'org-acme');
      expect(call.payload['phone'], '+919876543210');
      expect(call.payload['branchIds'], ['br-02']);
    });

    test('a retried create reuses the same requestId', () async {
      server.failNextCallWith = const NetworkException();
      final draft = memberDraft(username: 'retry.me');
      await expectLater(
        repo.saveMember(
          access: orgAdminAccess(),
          member: draft,
          initialPassword: 'Str0ng-Pass!',
        ),
        throwsA(isA<NetworkException>()),
      );
      await repo.saveMember(
        access: orgAdminAccess(),
        member: draft,
        initialPassword: 'Str0ng-Pass!',
      );
      final ids = server
          .callsTo('provisionUser')
          .map((c) => c.payload['requestId'])
          .toSet();
      expect(ids, hasLength(1));
      expect(server.all.where((m) => m.username == 'retry.me'), hasLength(1));
    });

    test('update sends only the changed fields and never the role', () async {
      final existing = server.byId('user-emp-02')!;
      await repo.saveMember(
        access: orgAdminAccess(),
        member: existing.copyWith(fullName: 'Alexandra Chen'),
        initialPassword: '',
      );
      final payload = server.callsTo('updateUserAccount').single.payload;
      expect(payload['targetUid'], 'user-emp-02');
      expect(payload['fullName'], 'Alexandra Chen');
      expect(payload.containsKey('role'), isFalse);
      expect(payload.containsKey('branchIds'), isFalse);
      expect(payload.containsKey('email'), isFalse);
      expect(payload.containsKey('phone'), isFalse);
    });

    test('clearing the phone sends an explicit null', () async {
      final existing = server.byId('user-emp-02')!;
      await repo.saveMember(
        access: orgAdminAccess(),
        member: existing.copyWith(clearPhone: true),
        initialPassword: '',
      );
      final payload = server.callsTo('updateUserAccount').single.payload;
      expect(payload.containsKey('phone'), isTrue);
      expect(payload['phone'], isNull);
    });

    test('policy violations never reach the server', () async {
      await expectLater(
        repo.saveMember(
          access: orgAdminAccess(),
          member: memberDraft(role: UserRole.platformOwner),
          initialPassword: 'Str0ng-Pass!',
        ),
        throwsA(isA<AppException>()),
      );
      expect(server.calls, isEmpty);
    });

    test('synthetic login emails are never displayed', () async {
      final created = await repo.saveMember(
        access: orgAdminAccess(),
        member: memberDraft(username: 'quiet.user'),
        initialPassword: 'Str0ng-Pass!',
      );
      expect(created.email, isEmpty);
      final page = await repo.getMembersPage(access: orgAdminAccess());
      expect(page.items.every((m) => !m.email.endsWith('.invalid')), isTrue);
    });

    test('backend failures surface as typed errors without raw text', () async {
      final source = FakeMembersDataSource(server)
        ..failWith = StateError('host=10.0.0.5 password=hunter2');
      final failing = SqlConnectOrganizationMembersRepository(
        dataSource: source,
        accounts: AccountCallables(server),
      );
      await expectLater(
        failing.getMembersPage(access: orgAdminAccess()),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            isNot(contains('hunter2')),
          ),
        ),
      );
    });

    test('accounts without a sign-in identity cannot be changed', () async {
      final orphan = server.byId('user-emp-02')!;
      final repoWithOrphan = SqlConnectOrganizationMembersRepository(
        dataSource: _OrphanSource(server, 'user-emp-02'),
        accounts: AccountCallables(server),
      );
      await expectLater(
        repoWithOrphan.saveMember(
          access: orgAdminAccess(),
          member: orphan.copyWith(fullName: 'X Y'),
          initialPassword: '',
        ),
        throwsA(isA<AppException>()),
      );
      expect(server.calls, isEmpty);
    });
  });
}

/// Returns [orphanId] without an auth uid, like a seed row never provisioned.
class _OrphanSource extends FakeMembersDataSource {
  _OrphanSource(super.server, this.orphanId);

  final String orphanId;

  @override
  Future<OrganizationMember?> getById(String memberId) async {
    final m = await super.getById(memberId);
    if (m == null || memberId != orphanId) return m;
    return OrganizationMember(
      id: m.id,
      organizationId: m.organizationId,
      fullName: m.fullName,
      username: m.username,
      email: m.email,
      phone: m.phone,
      role: m.role,
      branchIds: m.branchIds,
      status: m.status,
    );
  }
}
